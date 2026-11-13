import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/config/development_keys.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/domain/entities/install_id.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/directory_key_value_store.dart';
import 'package:in_vogue/core/persistence/install_id_store.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/colours/data/data_sources/colour_profile_remote_data_source.dart';
import 'package:in_vogue/features/colours/data/repositories/colour_profile_repository_impl.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/outfits/data/repositories/shared_try_on_job_repository.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/unavailable_try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/stylist/data/data_sources/taste_local_data_source.dart';
import 'package:in_vogue/features/stylist/data/data_sources/taste_remote_data_source.dart';
import 'package:in_vogue/features/stylist/data/repositories/taste_repository_impl.dart';
import 'package:in_vogue/features/stylist/domain/usecases/recommend_outfit.dart';
import 'package:path/path.dart' as path;

/// Dependencies for making outfits without opening the app's Hive box.
class BackgroundOutfits {
  BackgroundOutfits._(this.make, this._api, this._files);

  final MakeOutfit make;
  final Dio _api;
  final Dio _files;

  static Future<BackgroundOutfits> open({
    required AppEnvironment environment,
    required WidgetRefreshContext context,
    required String folder,
    required FirebaseFirestore firestore,
    required DayRepository days,
    required OutfitCatalogRepository catalog,
    required LogMessages log,
    required Future<bool> Function() canContinue,
  }) async {
    final accountId = context.accountId!;
    // This directory is removed with the account's outfit pictures.
    final store = DirectoryKeyValueStore(
      path.join(folder, 'outfits', accountId, 'background'),
    );
    final workerId = await InstallIdStore.read(store);
    final taste = TasteRepositoryImpl(
      local: TasteLocalDataSourceImpl(store),
      remote: TasteRemoteDataSourceImpl(firestore),
      logMessages: log,
    );
    await taste
        .restore(accountId)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => const Left(NetworkFailure()),
        );
    final key = environment == AppEnvironment.development
        ? await DevelopmentKeys.youCam(rootBundle)
        : null;
    final api = Dio(
      BaseOptions(
        baseUrl: YouCamRemoteDataSourceImpl.baseUrl,
        headers: {if (key != null) 'Authorization': 'Bearer $key'},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final files = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    final maker = MakeOutfit(
      logMessages: log,
      catalog: catalog,
      recommend: RecommendOutfit(catalog),
      colours: ColourProfileRepositoryImpl(
        remoteDataSource: ColourProfileRemoteDataSourceImpl(firestore),
        fingerprints: PhotoFingerprints(),
        logMessages: log,
      ),
      taste: taste,
      recordSignal: (signal) async {
        if (!await canContinue()) {
          return const Left(SignInFailure(SignInProblem.failed));
        }
        final kept = await taste.keep(signal);
        if (kept.isLeft()) return kept;
        return taste.save(accountId);
      },
      days: days,
      tryOn: key == null
          ? const UnavailableTryOnRepository()
          : TryOnRepositoryImpl(
              remoteDataSource: YouCamRemoteDataSourceImpl(
                api: api,
                files: files,
              ),
              logMessages: log,
            ),
      jobs: SharedTryOnJobRepository(path.join(folder, 'try_on_jobs')),
      loadBodyPhoto: () async {
        final photo = context.bodyPhoto;
        final revision = context.bodyPhotoRevision;
        if (photo == null || revision == null) return const Right(null);
        // iOS may move the app container during an update.
        final file = path.join(folder, 'photos', path.basename(photo));
        return Right(
          File(file).existsSync()
              ? UserPhoto(role: PhotoRole.body, path: file, revision: revision)
              : null,
        );
      },
      // The background reads the saved account; it never overwrites setup.
      saveSetupToAccount: (id) async {
        try {
          final account = await firestore
              .doc('users/$id')
              .get()
              .timeout(const Duration(seconds: 20));
          return account.exists
              ? const Right(unit)
              : const Left(SignInFailure(SignInProblem.failed));
        } on Exception {
          return const Left(NetworkFailure());
        }
      },
      installId: InstallId('background-${workerId.value}'),
      canContinue: canContinue,
    );
    return BackgroundOutfits._(maker, api, files);
  }

  void close() {
    _api.close(force: true);
    _files.close(force: true);
  }
}
