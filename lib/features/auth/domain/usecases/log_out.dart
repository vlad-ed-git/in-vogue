import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_job_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';

/// Signs out, then forgets what the phone keeps for the account: its outfit
/// and makeup pictures, what the widget shows, and its name, so the next
/// account brings its own. The body and face photos and the picks stay.
class LogOut implements UseCase<Unit, NoParams> {
  const LogOut({
    required this._auth,
    required this._profile,
    required this._days,
    required this._makeup,
    required this._makeupJobs,
    required this._widget,
  });

  final AuthRepository _auth;
  final ProfileRepository _profile;
  final DayRepository _days;
  final MakeupRepository _makeup;
  final MakeupJobRepository _makeupJobs;
  final HomeWidgetRepository _widget;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    final account = (await _auth.currentAccount()).fold<Account?>(
      (_) => null,
      (account) => account,
    );
    final signedOut = await _auth.signOut();
    if (signedOut.isLeft()) return signedOut;
    if (account != null) {
      // One that cannot be removed does not undo the rest. Makeup jobs name
      // the pictures they made, so they go too.
      await _days.forgetPictures(account.id);
      await _makeup.forgetPictures(account.id);
      await _makeupJobs.clearAccount(account.id);
      await _widget.clear();
    }
    return _profile.clearName();
  }
}
