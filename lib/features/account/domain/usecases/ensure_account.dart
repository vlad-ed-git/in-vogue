import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';

/// Saves the phone's setup on the signed-in account when the account has
/// not been saved yet; does nothing when nobody is signed in.
class EnsureAccount implements UseCase<Unit, NoParams> {
  const EnsureAccount({
    required this._auth,
    required this._account,
    required this._saveSetupToAccount,
  });

  final AuthRepository _auth;
  final AccountRepository _account;
  final SaveSetupToAccount _saveSetupToAccount;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    final signedIn = (await _auth.currentAccount()).getOrElse(() => null);
    if (signedIn == null) return const Right(unit);
    final exists = await _account.exists(signedIn.id);
    if (exists case Left(value: final failure)) return Left(failure);
    if (exists.getOrElse(() => true)) return const Right(unit);
    return _saveSetupToAccount(signedIn.id);
  }
}
