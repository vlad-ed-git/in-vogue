import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/outfits/data/data_sources/you_cam_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/outfits_model.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/photos/data/photo_content_type.dart';
import 'package:path/path.dart' as p;

/// Try-ons with YouCam's AI Clothes: each pass keeps the person's shoes and
/// dresses the person most in the photo.
class TryOnRepositoryImpl implements TryOnRepository {
  TryOnRepositoryImpl({
    required YouCamRemoteDataSource remoteDataSource,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _logger = logMessages;

  final YouCamRemoteDataSource _remote;
  final LogMessages _logger;

  @override
  Future<Either<Failure, String>> upload(String path) async {
    final List<int> bytes;
    try {
      bytes = await File(path).readAsBytes();
    } on FileSystemException catch (error, stack) {
      _log('upload', error, stack);
      return const Left(TryOnFailure(TryOnProblem.photo));
    }
    return _guard(
      'upload',
      () => _remote.uploadFile(
        bytes,
        contentType: photoContentType(path),
        name: p.basename(path),
      ),
    );
  }

  @override
  Future<Either<Failure, String>> start(
    TryOnPass pass, {
    String? fileId,
    String? pictureUrl,
  }) => _guard(
    'start',
    () => _remote.startClothes({
      'src_file_id': ?fileId,
      'src_file_url': ?pictureUrl,
      'ref_file_url': pass.reference,
      'garment_category': OutfitsModel.categoryName(pass.category),
      'change_shoes': false,
      'filter_multi_person': 'normal',
    }),
  );

  @override
  Future<Either<Failure, TryOnTask>> check(String taskId) =>
      _guard('check', () => _remote.clothesTask(taskId));

  @override
  Future<Either<Failure, List<int>>> download(String url) =>
      _guard('download', () => _remote.download(url));

  @override
  Future<void> discard(String taskId) async {
    // Only tidies up: YouCam deletes tasks after about 30 days anyway.
    await _guard('discard', () => _remote.deleteTask(taskId));
  }

  Future<Either<Failure, T>> _guard<T>(
    String method,
    Future<T> Function() call,
  ) async {
    try {
      return Right(await call());
    } on YouCamException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return Left(TryOnFailure(error.problem));
    } on NetworkException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    }
  }

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logger.logError(
        callerClass: 'TryOnRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
