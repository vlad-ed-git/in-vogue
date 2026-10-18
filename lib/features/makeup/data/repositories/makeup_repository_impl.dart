import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
import 'package:in_vogue/features/makeup/data/data_sources/look_picture_local_data_source.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_asset_data_source.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_remote_data_source.dart';
import 'package:in_vogue/features/makeup/data/models/face_colours_model.dart';
import 'package:in_vogue/features/makeup/data/models/makeup_look_model.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:path/path.dart' as p;

/// The bundled recipes, read once and kept in memory; the looks and face
/// colours on the account, with a copy of each look on the phone.
///
/// A face photo's colours are kept under its fingerprint, and a look under
/// its face photo's fingerprint and outfit, so they always belong to that
/// very photo. A look on the phone opens without the account.
class MakeupRepositoryImpl implements MakeupRepository {
  MakeupRepositoryImpl({
    required MakeupAssetDataSource assetDataSource,
    required MakeupRemoteDataSource remoteDataSource,
    required LookPictureLocalDataSource pictureDataSource,
    required this._fingerprints,
    required LogMessages logMessages,
  }) : _asset = assetDataSource,
       _remote = remoteDataSource,
       _pictures = pictureDataSource,
       _logger = logMessages;

  final MakeupAssetDataSource _asset;
  final MakeupRemoteDataSource _remote;
  final LookPictureLocalDataSource _pictures;
  final PhotoFingerprints _fingerprints;
  final LogMessages _logger;

  /// How long a call to the account may take before it counts as offline.
  static const timeLimit = Duration(seconds: 30);

  /// How long moving a look's pictures to or from the account may take.
  static const picturesTimeLimit = Duration(minutes: 2);

  Future<Map<String, MakeupRecipe>>? _recipes;

  Future<Map<String, MakeupRecipe>> _load() async {
    final loading = _recipes ??= _asset.recipes();
    try {
      return await loading;
    } on FormatException {
      // Read again next time.
      _recipes = null;
      rethrow;
    }
  }

  @override
  Future<Either<Failure, MakeupRecipe?>> recipe(String key) =>
      _guard('recipe', () async => (await _load())[key]);

  @override
  Future<Either<Failure, FaceColours?>> faceColours(
    String accountId,
    String facePhoto,
  ) => _guard('faceColours', () async {
    final json = await _remote.colours(
      accountId,
      await _fingerprints.of(facePhoto),
    );
    return json == null ? null : FaceColoursModel.fromJson(json);
  });

  @override
  Future<Either<Failure, Unit>> saveFaceColours(
    String accountId,
    String facePhoto,
    FaceColours colours,
  ) => _guard('saveFaceColours', () async {
    await _remote.saveColours(
      accountId,
      await _fingerprints.of(facePhoto),
      FaceColoursModel.toJson(colours),
    );
    return unit;
  });

  @override
  Future<Either<Failure, String?>> keptPicture(
    String accountId, {
    required String facePhoto,
    required String outfitSignature,
    required String fileName,
  }) => _guard(
    'keptPicture',
    () async => _pictures.kept(
      accountId,
      await _lookOf(facePhoto, outfitSignature),
      fileName,
    ),
  );

  @override
  Future<Either<Failure, String>> keepPicture(
    String accountId, {
    required String facePhoto,
    required String outfitSignature,
    required String name,
    required List<int> picture,
  }) => _guard(
    'keepPicture',
    () async => _pictures.keep(
      accountId,
      await _lookOf(facePhoto, outfitSignature),
      '$name.${MakeupLookModel.extensionOf(picture)}',
      picture,
    ),
  );

  @override
  Future<Either<Failure, Unit>> record(
    String accountId,
    MakeupLook look, {
    required String facePhoto,
  }) => _guard('record', limit: picturesTimeLimit, () async {
    final face = await _fingerprints.of(facePhoto);
    final id = MakeupLookModel.idOf(face, look.outfitSignature);
    for (final picture in [
      look.before,
      for (final step in look.steps) step.picture!,
    ]) {
      final name = p.basename(picture);
      await _remote.upload(
        MakeupLookModel.storagePath(accountId, id, name),
        await File(picture).readAsBytes(),
        contentType: MakeupLookModel.contentType(name),
      );
    }
    final record = {...MakeupLookModel.toJson(look), 'face': face};
    await _remote.writeLook(accountId, id, record);
    await _pictures.keepRecord(accountId, id, record);
    return unit;
  });

  @override
  Future<Either<Failure, MakeupLook?>> look(
    String accountId, {
    required String facePhoto,
    required String outfitSignature,
  }) => _guard('look', limit: picturesTimeLimit, () async {
    final face = await _fingerprints.of(facePhoto);
    final id = MakeupLookModel.idOf(face, outfitSignature);
    // A look made before looks were kept by face photo is named by its
    // outfit, and belongs to the first face photo that finds it.
    for (final name in [id, outfitSignature]) {
      final kept = _pictures.record(accountId, name);
      if (kept?['face'] != face) continue;
      final look = MakeupLookModel.fromJson(name, kept!);
      if (look != null) return _onPhone(accountId, name, look);
    }
    var name = id;
    var record = await _remote.look(accountId, id);
    if (record == null) {
      name = outfitSignature;
      record = await _remote.look(accountId, outfitSignature);
      if (record != null && record['face'] == null) {
        await _remote.setLookFace(accountId, outfitSignature, face);
        record = {...record, 'face': face};
      }
      if (record?['face'] != face) return null;
    }
    final look = record == null ? null : MakeupLookModel.fromJson(name, record);
    if (look == null) return null;
    final onPhone = await _onPhone(accountId, name, look);
    await _pictures.keepRecord(accountId, name, {
      ...MakeupLookModel.toJson(look),
      'face': face,
    });
    return onPhone;
  });

  @override
  Future<Either<Failure, MakeupLook?>> latestLook(String accountId) =>
      _guard('latestLook', limit: picturesTimeLimit, () async {
        final latest = await _remote.latestLook(accountId);
        if (latest == null) return null;
        final (name, json) = latest;
        final look = MakeupLookModel.fromJson(name, json);
        return look == null ? null : _onPhone(accountId, name, look);
      });

  @override
  Future<Either<Failure, Unit>> forgetPictures(String accountId) =>
      _guard('forgetPictures', () async {
        await _pictures.forget(accountId);
        return unit;
      });

  /// The look [name], whose pictures are file names, with each picture on
  /// the phone, fetched from the account when missing.
  Future<MakeupLook> _onPhone(
    String accountId,
    String name,
    MakeupLook look,
  ) async {
    Future<String> picture(String file) async =>
        _pictures.kept(accountId, name, file) ??
        await _pictures.keep(
          accountId,
          name,
          file,
          await _remote.download(
            MakeupLookModel.storagePath(accountId, name, file),
          ),
        );
    return MakeupLook(
      outfitSignature: look.outfitSignature,
      date: look.date,
      occasion: look.occasion,
      palette: look.palette,
      cheeks: look.cheeks,
      lips: look.lips,
      before: await picture(look.before),
      steps: [
        for (final step in look.steps)
          step.withPicture(await picture(step.picture!)),
      ],
      matched: look.matched,
    );
  }

  /// The name of the look of [outfitSignature] on the face photo at
  /// [facePhoto].
  Future<String> _lookOf(String facePhoto, String outfitSignature) async =>
      MakeupLookModel.idOf(await _fingerprints.of(facePhoto), outfitSignature);

  Future<Either<Failure, T>> _guard<T>(
    String method,
    Future<T> Function() call, {
    Duration limit = timeLimit,
  }) async {
    try {
      return Right(await call().timeout(limit));
    } on TimeoutException catch (error, stack) {
      _log(method, error, stack);
      return const Left(NetworkFailure());
    } on NetworkException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    } on ServerException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(ServerFailure());
    } on CacheException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(CacheFailure());
    } on FileSystemException catch (error, stack) {
      _log(method, error, stack);
      return const Left(CacheFailure());
    } on FormatException catch (error, stack) {
      _log(method, error, stack);
      return const Left(CacheFailure());
    }
  }

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logger.logError(
        callerClass: 'MakeupRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
