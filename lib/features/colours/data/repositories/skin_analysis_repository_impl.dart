import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/colours/data/data_sources/face_picture_data_source.dart';
import 'package:in_vogue/features/colours/data/models/face_colours_model.dart';
import 'package:in_vogue/features/colours/domain/repositories/skin_analysis_repository.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';

/// The skin-tone analysis on YouCam: the Facial Color Tones Analyzer.
class SkinAnalysisRepositoryImpl implements SkinAnalysisRepository {
  SkinAnalysisRepositoryImpl({
    required YouCamRemoteDataSource remoteDataSource,
    required FacePictureDataSource faceDataSource,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _faces = faceDataSource,
       _logger = logMessages;

  final YouCamRemoteDataSource _remote;
  final FacePictureDataSource _faces;
  final LogMessages _logger;

  @override
  bool get available => true;

  @override
  Future<Either<Failure, String>> uploadFace(String path) async {
    final List<int> face;
    try {
      face = await _faces.prepare(path);
    } on PhotoException catch (error) {
      _log('uploadFace', error.cause, error.stackTrace);
      return const Left(AnalysisFailure(AnalysisProblem.photo));
    }
    return _guard(
      'uploadFace',
      () =>
          _remote.uploadFile(face, contentType: 'image/png', name: 'face.png'),
    );
  }

  @override
  Future<Either<Failure, String>> start(String fileId) => _guard(
    'start',
    () => _remote.start(YouCamTool.skinTone, {
      'src_file_id': fileId,
      // YouCam's levels run strict, high (its default), medium, low and
      // flexible; the app trusts the person's photo.
      'face_angle_strictness_level': 'low',
    }),
  );

  @override
  Future<Either<Failure, AnalysisTask>> check(String taskId) => _guard(
    'check',
    () async => switch (await _remote.task(YouCamTool.skinTone, taskId)) {
      YouCamTaskSucceeded(:final results) => AnalysisDone(
        FaceColoursModel.fromAnalysis(results),
      ),
      final YouCamTaskFailed failed => _failed(failed),
      YouCamTaskRunning() => const AnalysisRunning(),
    },
  );

  @override
  Future<void> discard(String taskId) async {
    // Only tidies up: YouCam deletes tasks after about 30 days anyway.
    await _guard('discard', () => _remote.deleteTask(taskId));
  }

  /// [failed] as an analysis task, logged with YouCam's code.
  AnalysisFailed _failed(YouCamTaskFailed failed) {
    _logger.logError(
      callerClass: 'SkinAnalysisRepositoryImpl',
      callerMethod: 'check',
      error: YouCamTaskError(failed.code),
    );
    return AnalysisFailed(_problem(failed.problem), advice: failed.advice);
  }

  static AnalysisProblem _problem(YouCamProblem problem) => switch (problem) {
    YouCamProblem.failed || YouCamProblem.reference => AnalysisProblem.failed,
    YouCamProblem.photo => AnalysisProblem.photo,
    YouCamProblem.noCredit => AnalysisProblem.noCredit,
    YouCamProblem.unauthorized => AnalysisProblem.unavailable,
  };

  Future<Either<Failure, T>> _guard<T>(
    String method,
    Future<T> Function() call,
  ) async {
    try {
      return Right(await call());
    } on YouCamException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return Left(AnalysisFailure(_problem(error.problem)));
    } on NetworkException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    }
  }

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logger.logError(
        callerClass: 'SkinAnalysisRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
