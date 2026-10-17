import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_model.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/makeup/data/data_sources/face_picture_data_source.dart';
import 'package:in_vogue/features/makeup/data/models/face_colours_model.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_service_repository.dart';
import 'package:in_vogue/features/photos/data/photo_content_type.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';
import 'package:path/path.dart' as p;

/// The makeup service on YouCam: the Facial Color Tones Analyzer, and
/// Makeup VTO with the effects of each step as they are given.
class MakeupServiceRepositoryImpl implements MakeupServiceRepository {
  MakeupServiceRepositoryImpl({
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
  Future<Either<Failure, List<int>>> prepareFace(String path) async {
    try {
      return Right(await _faces.prepare(path));
    } on PhotoException catch (error) {
      _log('prepareFace', error.cause, error.stackTrace);
      return const Left(MakeupFailure(MakeupProblem.photo));
    }
  }

  @override
  Future<Either<Failure, String>> upload(String path) async {
    final List<int> bytes;
    try {
      bytes = await File(path).readAsBytes();
    } on FileSystemException catch (error, stack) {
      _log('upload', error, stack);
      return const Left(CacheFailure());
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
  Future<Either<Failure, String>> startAnalysis(String fileId) => _guard(
    'startAnalysis',
    () => _remote.start(YouCamTool.skinTone, {
      'src_file_id': fileId,
      'face_angle_strictness_level': 'high',
    }),
  );

  @override
  Future<Either<Failure, MakeupTask<FaceColours>>> checkAnalysis(
    String taskId,
  ) => _guard(
    'checkAnalysis',
    () async => switch (await _remote.task(YouCamTool.skinTone, taskId)) {
      YouCamTaskSucceeded(:final results) => MakeupTaskDone(
        FaceColoursModel.fromAnalysis(results),
      ),
      YouCamTaskFailed(:final problem) => MakeupTaskFailed(_problem(problem)),
      YouCamTaskRunning() => const MakeupTaskRunning(),
    },
  );

  @override
  Future<Either<Failure, String>> startStep(
    String fileId,
    List<Map<String, Object?>> effects,
  ) => _guard(
    'startStep',
    () => _remote.start(YouCamTool.makeup, {
      'src_file_id': fileId,
      'version': '1.0',
      'effects': effects,
    }),
  );

  /// A success without a picture is a failure.
  @override
  Future<Either<Failure, MakeupTask<String>>> checkStep(String taskId) =>
      _guard('checkStep', () async {
        final task = await _remote.task(YouCamTool.makeup, taskId);
        if (task case YouCamTaskSucceeded(:final results)) {
          final url = YouCamModel.resultUrl(results);
          return url == null
              ? const MakeupTaskFailed(MakeupProblem.failed)
              : MakeupTaskDone(url);
        }
        return switch (task) {
          YouCamTaskFailed(:final problem) => MakeupTaskFailed(
            _problem(problem),
          ),
          _ => const MakeupTaskRunning(),
        };
      });

  @override
  Future<Either<Failure, List<int>>> download(String url) =>
      _guard('download', () => _remote.download(url));

  @override
  Future<void> discard(String taskId) async {
    // Only tidies up: YouCam deletes tasks after about 30 days anyway.
    await _guard('discard', () => _remote.deleteTask(taskId));
  }

  static MakeupProblem _problem(YouCamProblem problem) => switch (problem) {
    YouCamProblem.failed || YouCamProblem.reference => MakeupProblem.failed,
    YouCamProblem.photo => MakeupProblem.photo,
    YouCamProblem.noCredit => MakeupProblem.noCredit,
    YouCamProblem.unauthorized => MakeupProblem.unavailable,
  };

  Future<Either<Failure, T>> _guard<T>(
    String method,
    Future<T> Function() call,
  ) async {
    try {
      return Right(await call());
    } on YouCamException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return Left(MakeupFailure(_problem(error.problem)));
    } on NetworkException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    }
  }

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logger.logError(
        callerClass: 'MakeupServiceRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
