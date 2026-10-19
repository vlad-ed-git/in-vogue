import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';
import 'package:in_vogue/features/stylist/domain/repositories/taste_repository.dart';
import 'package:in_vogue/features/stylist/domain/usecases/record_signal.dart';

/// Taste signals in memory: the phone's, and each account's.
class MemoryTaste implements TasteRepository {
  final phone = <TasteSignal>[];
  final accounts = <String, List<TasteSignal>>{};
  final saves = <String>[];
  var clears = 0;
  var reads = 0;

  @override
  Future<Either<Failure, List<TasteSignal>>> signals() async {
    reads++;
    return Right([...phone]);
  }

  @override
  Future<Either<Failure, Unit>> keep(TasteSignal signal) async {
    if (!phone.any((known) => known.id == signal.id)) phone.add(signal);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> restore(String accountId) async {
    for (final signal in accounts[accountId] ?? const <TasteSignal>[]) {
      await keep(signal);
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> save(String accountId) async {
    saves.add(accountId);
    final kept = accounts.putIfAbsent(accountId, () => []);
    for (final signal in phone) {
      if (!kept.any((known) => known.id == signal.id)) kept.add(signal);
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> clear() async {
    clears++;
    phone.clear();
    return const Right(unit);
  }
}

class _Auth extends Fake implements AuthRepository {
  _Auth(this.accountId);
  final String? accountId;

  @override
  Future<Either<Failure, Account?>> currentAccount() async =>
      Right(accountId == null ? null : Account(id: accountId!));
}

/// [RecordSignal] into [taste], for [accountId] when someone is signed in.
RecordSignal recordSignalInto(MemoryTaste taste, {String? accountId}) =>
    RecordSignal(
      taste: taste,
      getCurrentAccount: GetCurrentAccount(_Auth(accountId)),
    );
