import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/features/colours/data/data_sources/colour_profile_remote_data_source.dart';
import 'package:in_vogue/features/colours/data/data_sources/face_picture_data_source.dart';
import 'package:in_vogue/features/colours/data/repositories/analysis_job_repository_impl.dart';
import 'package:in_vogue/features/colours/data/repositories/colour_profile_repository_impl.dart';
import 'package:in_vogue/features/colours/data/repositories/skin_analysis_repository_impl.dart';
import 'package:in_vogue/features/colours/data/repositories/unavailable_skin_analysis_repository.dart';
import 'package:in_vogue/features/colours/domain/repositories/analysis_job_repository.dart';
import 'package:in_vogue/features/colours/domain/repositories/colour_profile_repository.dart';
import 'package:in_vogue/features/colours/domain/repositories/skin_analysis_repository.dart';
import 'package:in_vogue/features/colours/domain/services/analyse_face.dart';
import 'package:in_vogue/features/colours/presentation/bloc/colours_bloc.dart';
import 'package:in_vogue/features/colours/presentation/bloc/skin_analysis_bloc.dart';

/// Without a YouCam client no colours can be read.
void init(GetIt locator) {
  locator
    ..registerLazySingleton<ColourProfileRemoteDataSource>(
      () => ColourProfileRemoteDataSourceImpl(FirebaseFirestore.instance),
    )
    ..registerLazySingleton<ColourProfileRepository>(
      () => ColourProfileRepositoryImpl(
        remoteDataSource: locator(),
        fingerprints: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<AnalysisJobRepository>(
      () => AnalysisJobRepositoryImpl(locator()),
    )
    ..registerLazySingleton<FacePictureDataSource>(
      () => const FacePictureDataSourceImpl(),
    )
    ..registerLazySingleton<SkinAnalysisRepository>(
      () => locator.isRegistered<YouCamRemoteDataSource>()
          ? SkinAnalysisRepositoryImpl(
              remoteDataSource: locator(),
              faceDataSource: locator(),
              logMessages: locator(),
            )
          : const UnavailableSkinAnalysisRepository(),
    )
    ..registerLazySingleton<AnalyseFace>(
      () => AnalyseFace(
        service: locator(),
        profiles: locator(),
        jobs: locator(),
        photos: locator(),
        saveSetupToAccount: locator(),
      ),
    )
    ..registerFactory<ColoursBloc>(
      () => ColoursBloc(
        getCurrentAccount: locator(),
        getKeptPhoto: locator(),
        analyseFace: locator(),
      ),
    )
    ..registerFactory<SkinAnalysisBloc>(
      () => SkinAnalysisBloc(
        getCurrentAccount: locator(),
        analyseFace: locator(),
      ),
    );
}
