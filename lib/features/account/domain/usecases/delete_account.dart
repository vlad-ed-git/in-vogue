import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/colours/domain/repositories/analysis_job_repository.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_job_repository.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';
import 'package:in_vogue/features/stylist/domain/repositories/taste_repository.dart';
import 'package:in_vogue/features/wardrobe/domain/repositories/wardrobe_repository.dart';

/// Deletes the signed-in account: the person confirms with their provider,
/// then the account's data and files go from the server, then the account
/// itself, then everything the phone keeps for it. Stops at the first step
/// that fails, so nothing is left half-deleted on the phone.
class DeleteAccount implements UseCase<Unit, NoParams> {
  const DeleteAccount({
    required this._auth,
    required this._account,
    required this._photos,
    required this._picks,
    required this._profile,
    required this._location,
    required this._days,
    required this._jobs,
    required this._analyses,
    required this._wardrobe,
    required this._widget,
    required this._taste,
  });

  final AuthRepository _auth;
  final AccountRepository _account;
  final PhotoRepository _photos;
  final PicksRepository _picks;
  final ProfileRepository _profile;
  final LocationRepository _location;
  final DayRepository _days;
  final TryOnJobRepository _jobs;
  final AnalysisJobRepository _analyses;
  final WardrobeRepository _wardrobe;
  final HomeWidgetRepository _widget;
  final TasteRepository _taste;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    final signedIn = (await _auth.currentAccount()).fold<Account?>(
      (_) => null,
      (account) => account,
    );
    if (signedIn == null) {
      return const Left(SignInFailure(SignInProblem.failed));
    }
    for (final step in [
      _auth.reauthenticate,
      () => _account.delete(signedIn.id),
      _auth.deleteUser,
    ]) {
      final done = await step();
      if (done case Left(value: final failure)) return Left(failure);
    }
    // The phone's copies; one that cannot be removed does not undo the rest.
    await _photos.forget(PhotoRole.body);
    await _photos.forget(PhotoRole.face);
    await _picks.clear();
    await _profile.clearName();
    await _location.forget();
    await _days.forgetPictures(signedIn.id);
    await _jobs.clearAccount(signedIn.id);
    await _analyses.forgetAccount(signedIn.id);
    await _wardrobe.forgetPhotos(signedIn.id);
    await _widget.clear();
    await _taste.clear();
    return const Right(unit);
  }
}
