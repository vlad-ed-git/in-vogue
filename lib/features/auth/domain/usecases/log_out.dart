import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';

/// Signs out and forgets the account's name, so the next account brings its
/// own.
class LogOut implements UseCase<Unit, NoParams> {
  const LogOut({required this._auth, required this._profile});

  final AuthRepository _auth;
  final ProfileRepository _profile;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    final signedOut = await _auth.signOut();
    if (signedOut.isLeft()) return signedOut;
    return _profile.clearName();
  }
}
