import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';

/// Each account's days, shared by its phones, and the outfits suggested to
/// it.
abstract interface class DayRepository {
  /// The day of [date] and [occasion] as it changes, starting from the
  /// phone's copy; null while it has no outfit.
  Stream<Either<Failure, Day?>> watch(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
  });

  Future<Either<Failure, Day?>> day(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
  });

  /// The days of [accountId] from [date] on, every occasion.
  Future<Either<Failure, List<Day>>> since(String accountId, DateTime date);

  /// When each of [outfitIds] was last suggested, null while that time is
  /// being written; outfits never suggested are left out.
  Future<Either<Failure, Map<String, DateTime?>>> suggested(
    String accountId,
    List<String> outfitIds,
  );

  /// Claims the day of [date] and [occasion] for [device]: [proposal] gives
  /// a day that needs one its outfit, recorded as suggested unless
  /// [suggested] (what the chooser saw) is out of date. With [replacing],
  /// [device]'s making of that outfit takes [proposal] instead.
  Future<Either<Failure, DayClaim>> claim(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
    required Day? proposal,
    required Map<String, DateTime?> suggested,
    required String device,
    String? replacing,
  });

  /// Records that [device] is putting on [piece] of [pieces]; false when
  /// [device] no longer makes the day.
  Future<Either<Failure, bool>> progress(
    String accountId,
    Day day, {
    required int piece,
    required int pieces,
    required String device,
  });

  /// Keeps [picture] on the phone and the account and marks the day made;
  /// the picture's file, or null when [device] no longer makes the day.
  /// The picture is also kept as the outfit's on the photo at [photo], so
  /// they are never tried on again.
  Future<Either<Failure, String?>> finish(
    String accountId,
    Day day,
    List<int> picture, {
    required String photo,
    required String device,
  });

  /// Where on the account the picture already made of the outfit
  /// [outfitId] on the photo at [photo] is, from this phone when it knows;
  /// null when none was made.
  Future<Either<Failure, String?>> madePicture(
    String accountId, {
    required String photo,
    required String outfitId,
  });

  /// Marks the day made with the picture already at [picturePath] on the
  /// account; the picture's file on the phone, or null when [device] no
  /// longer makes the day.
  Future<Either<Failure, String?>> reuse(
    String accountId,
    Day day,
    String picturePath, {
    required String device,
  });

  /// The file of a made day's picture on the phone, fetched from the
  /// account when missing.
  Future<Either<Failure, String>> picture(String accountId, Day day);

  /// Deletes [accountId]'s pictures from the phone.
  Future<Either<Failure, Unit>> forgetPictures(String accountId);
}
