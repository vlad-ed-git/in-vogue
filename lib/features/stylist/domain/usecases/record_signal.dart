import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';
import 'package:in_vogue/features/stylist/domain/repositories/taste_repository.dart';

/// Keeps a taste signal on the phone and, for a signed-in person, on the
/// account. A failed account save never stops the person: the next save
/// takes the signal along.
class RecordSignal implements UseCase<Unit, TasteSignal> {
  const RecordSignal({required this._taste, required this._getCurrentAccount});

  final TasteRepository _taste;
  final GetCurrentAccount _getCurrentAccount;

  @override
  Future<Either<Failure, Unit>> call(TasteSignal signal) async {
    final kept = await _taste.keep(signal);
    if (kept case Left()) return kept;
    final account = await _getCurrentAccount(const NoParams());
    if (account case Right(value: final account?)) {
      await _taste.save(account.id);
    }
    return const Right(unit);
  }
}
