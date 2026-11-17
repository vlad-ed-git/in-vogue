import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/stylist/data/data_sources/taste_local_data_source.dart';
import 'package:in_vogue/features/stylist/data/data_sources/taste_remote_data_source.dart';
import 'package:in_vogue/features/stylist/data/models/taste_signal_model.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';
import 'package:in_vogue/features/stylist/domain/repositories/taste_repository.dart';

/// Signals on the phone in Hive, and on the account in Firestore. Both
/// only grow, and a signal is known by its id, so phones merge by union.
/// The phone remembers which the account has, and sends only the others.
class TasteRepositoryImpl implements TasteRepository {
  TasteRepositoryImpl({
    required this._local,
    required this._remote,
    required this._logMessages,
  });

  final TasteLocalDataSource _local;
  final TasteRemoteDataSource _remote;
  final LogMessages _logMessages;

  List<TasteSignal> _read(List<Object?> json) => [
    for (final signal in json) ?TasteSignalModel.fromJson(signal),
  ];

  @override
  Future<Either<Failure, List<TasteSignal>>> signals() =>
      _guard('signals', () async => _read(_local.signals()));

  @override
  Future<Either<Failure, Unit>> keep(TasteSignal signal) =>
      _guard('keep', () async {
        final kept = _read(_local.signals());
        if (kept.any((known) => known.id == signal.id)) return unit;
        await _local.save([
          for (final known in [...kept, signal]) TasteSignalModel.toJson(known),
        ]);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> restore(String accountId) =>
      _guard('restore', () async {
        final saved = _read(await _remote.signals(accountId));
        // Read after the account, so a signal kept meanwhile stays.
        final kept = _read(_local.signals());
        final known = {for (final signal in kept) signal.id};
        final added = [
          for (final signal in saved)
            if (known.add(signal.id)) signal,
        ];
        if (added.isNotEmpty) {
          await _local.save([
            for (final signal in [...kept, ...added])
              TasteSignalModel.toJson(signal),
          ]);
        }
        await _local.saveSynced({
          ..._local.synced(),
          for (final signal in saved) signal.id,
        });
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> save(String accountId) =>
      _guard('save', () async {
        final synced = _local.synced();
        final unsent = [
          for (final signal in _read(_local.signals()))
            if (!synced.contains(signal.id)) signal,
        ];
        if (unsent.isEmpty) return unit;
        await _remote.add(accountId, [
          for (final signal in unsent) TasteSignalModel.toJson(signal),
        ]);
        // Read again: a restore may have added some meanwhile.
        await _local.saveSynced({
          ..._local.synced(),
          for (final signal in unsent) signal.id,
        });
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> clear() => _guard('clear', () async {
    await _local.forget();
    return unit;
  });

  Future<Either<Failure, T>> _guard<T>(
    String method,
    Future<T> Function() call,
  ) async {
    try {
      return Right(await call());
    } on NetworkException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    } on ServerException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(ServerFailure());
    } on CacheException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(CacheFailure());
    }
  }

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logMessages.logError(
        callerClass: 'TasteRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
