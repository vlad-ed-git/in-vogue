import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// How far a day's outfit is.
enum DayStatus { making, ready, failed }

/// A day's outfit as the account keeps it, shared by every phone signed in
/// to the account.
class Day extends Equatable {
  const Day({
    required this.date,
    required this.occasion,
    required this.outfitId,
    required this.status,
    required this.device,
    this.reason,
    this.cold,
    this.warm,
    this.rain = false,
    this.snow = false,
    this.windy = false,
    this.piece = 0,
    this.pieces = 0,
    this.picturePath,
    this.problem,
    this.updatedAt,
  });

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  /// The catalog outfit chosen.
  final String outfitId;
  final DayStatus status;

  /// Why it was chosen; null for a day kept without one.
  final OutfitReason? reason;

  /// The bands of the coldest and warmest hours it was chosen for.
  final WarmthBand? cold;
  final WarmthBand? warm;

  /// Whether rain, snow or strong wind came in its hours.
  final bool rain;
  final bool snow;
  final bool windy;

  /// The install making the outfit, or that made it.
  final String device;

  /// The piece being put on, counted from 1, of [pieces]; 0 before the
  /// first.
  final int piece;
  final int pieces;

  /// Where the picture is kept on the account, once ready.
  final String? picturePath;

  /// Why the making failed.
  final TryOnProblem? problem;

  /// When the day last changed, by the server's clock; null until the
  /// server has the change.
  final DateTime? updatedAt;

  String get key => keyFor(date, occasion);

  /// Identifies the day of [date] and [occasion], such as "2026-10-18_work".
  static String keyFor(DateTime date, Occasion occasion) =>
      '${TryOnJob.dateKey(date)}_${occasion.name}';

  /// Being made by [by] from the first piece.
  Day makingBy(String by) => _copy(status: DayStatus.making, device: by);

  /// Putting on [piece] of [pieces].
  Day progressing(int piece, int pieces) =>
      _copy(status: DayStatus.making, piece: piece, pieces: pieces);

  /// Made, with its picture at [path] on the account.
  Day readyAt(String path) =>
      _copy(status: DayStatus.ready, piece: pieces, picturePath: path);

  Day failedWith(TryOnProblem why) =>
      _copy(status: DayStatus.failed, problem: why);

  Day _copy({
    required DayStatus status,
    String? device,
    int piece = 0,
    int? pieces,
    String? picturePath,
    TryOnProblem? problem,
  }) => Day(
    date: date,
    occasion: occasion,
    outfitId: outfitId,
    status: status,
    device: device ?? this.device,
    reason: reason,
    cold: cold,
    warm: warm,
    rain: rain,
    snow: snow,
    windy: windy,
    piece: piece,
    pieces: pieces ?? this.pieces,
    picturePath: picturePath,
    problem: problem,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    date,
    occasion,
    outfitId,
    status,
    device,
    reason,
    cold,
    warm,
    rain,
    snow,
    windy,
    piece,
    pieces,
    picturePath,
    problem,
    updatedAt,
  ];
}

/// What claiming a day came to.
sealed class DayClaim extends Equatable {
  const DayClaim();

  @override
  List<Object?> get props => [];
}

/// The day is this install's to make: new, resumed, taken over or tried
/// again.
final class DayClaimed extends DayClaim {
  const DayClaimed(this.day);
  final Day day;

  @override
  List<Object?> get props => [day];
}

/// The day is made, or another install is making it: it stays as it is.
final class DayKept extends DayClaim {
  const DayKept(this.day);
  final Day day;

  @override
  List<Object?> get props => [day];
}

/// The outfit proposed was suggested meanwhile, or the day vanished:
/// choose again.
final class DayConflict extends DayClaim {
  const DayConflict();
}
