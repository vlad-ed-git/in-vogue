import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_picker_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_prepare_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_store_data_source.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl({
    required PhotoPickerDataSource pickerDataSource,
    required PhotoPrepareDataSource prepareDataSource,
    required PhotoStoreDataSource storeDataSource,
    required LogMessages logMessages,
  }) : _picker = pickerDataSource,
       _prepare = prepareDataSource,
       _store = storeDataSource,
       _logger = logMessages;

  final PhotoPickerDataSource _picker;
  final PhotoPrepareDataSource _prepare;
  final PhotoStoreDataSource _store;
  final LogMessages _logger;

  @override
  Future<Either<Failure, ChosenPhoto?>> choose(PhotoRole role) async {
    try {
      final picked = await _picker.choose();
      if (picked == null) return const Right(null);
      return Right(await _prepare.prepare(picked, role));
    } on PhotoException catch (error) {
      // A photo too small is the person's to replace, not an error.
      if (error.problem != PhotoProblem.tooSmall) {
        _log('choose', error.cause, error.stackTrace);
      }
      return Left(PhotoFailure(error.problem));
    }
  }

  @override
  Future<Either<Failure, UserPhoto>> keep(String path, PhotoRole role) async {
    try {
      return Right(await _store.keep(path, role));
    } on CacheException catch (error) {
      _log('keep', error.cause, error.stackTrace);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, UserPhoto?>> kept(PhotoRole role) async {
    try {
      return Right(_store.kept(role));
    } on CacheException catch (error) {
      _log('kept', error.cause, error.stackTrace);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> forget(PhotoRole role) async {
    try {
      await _store.forget(role);
      return const Right(unit);
    } on CacheException catch (error) {
      _log('forget', error.cause, error.stackTrace);
      return const Left(CacheFailure());
    }
  }

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logger.logError(
        callerClass: 'PhotoRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
