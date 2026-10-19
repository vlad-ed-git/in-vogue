import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// A day as its record in `users/{uid}/days/{date}_{occasion}` holds it,
/// and its picture's kind.
abstract final class DayModel {
  /// The record's fields, without its time of change.
  static Map<String, Object?> toJson(Day day) => {
    'forDate': TryOnJob.dateKey(day.date),
    'occasion': day.occasion.name,
    'outfitId': day.outfitId,
    'reason': switch (day.reason) {
      final reason? => _reasonToJson(reason),
      null => null,
    },
    'cold': day.cold?.name,
    'warm': day.warm?.name,
    'rain': day.rain,
    'snow': day.snow,
    'windy': day.windy,
    'status': day.status.name,
    'device': day.device,
    'piece': day.piece,
    'pieces': day.pieces,
    'picturePath': day.picturePath,
    'problem': day.problem?.name,
  };

  /// Null when [json] is not a readable day.
  static Day? fromJson(Map<String, Object?> json, {DateTime? updatedAt}) {
    if (json case {
      'forDate': final String forDate,
      'occasion': final String occasion,
      'outfitId': final String outfitId,
      'status': final String status,
      'device': final String device,
      'piece': final int piece,
      'pieces': final int pieces,
    }) {
      final date = DateTime.tryParse('${forDate}T00:00:00Z');
      final kind = Occasion.values.asNameMap()[occasion];
      final state = DayStatus.values.asNameMap()[status];
      if (date == null || kind == null || state == null) return null;
      return Day(
        date: date,
        occasion: kind,
        outfitId: outfitId,
        status: state,
        device: device,
        reason: _reasonFromJson(json['reason']),
        cold: WarmthBand.values.asNameMap()[json['cold']],
        warm: WarmthBand.values.asNameMap()[json['warm']],
        rain: json['rain'] == true,
        snow: json['snow'] == true,
        windy: json['windy'] == true,
        piece: piece,
        pieces: pieces,
        picturePath: switch (json['picturePath']) {
          final String path => path,
          _ => null,
        },
        problem: TryOnProblem.values.asNameMap()[json['problem']],
        updatedAt: updatedAt,
      );
    }
    return null;
  }

  static Map<String, Object?> _reasonToJson(OutfitReason reason) => {
    'kind': reason.kind.name,
    'coldest': reason.coldest,
    'coldestAt': reason.coldestAt.toIso8601String(),
    'warmest': reason.warmest,
    'warmestAt': reason.warmestAt.toIso8601String(),
    'from': reason.from?.toIso8601String(),
    'season': reason.season?.name,
  };

  /// Null when [json] is not a readable reason.
  static OutfitReason? _reasonFromJson(Object? json) {
    if (json case {
      'kind': final String kind,
      'coldest': final num coldest,
      'coldestAt': final String coldestAt,
      'warmest': final num warmest,
      'warmestAt': final String warmestAt,
    }) {
      final named = ReasonKind.values.asNameMap()[kind];
      final coldAt = DateTime.tryParse(coldestAt);
      final warmAt = DateTime.tryParse(warmestAt);
      if (named == null || coldAt == null || warmAt == null) return null;
      return OutfitReason(
        kind: named,
        coldest: coldest.toDouble(),
        coldestAt: coldAt,
        warmest: warmest.toDouble(),
        warmestAt: warmAt,
        from: switch (json['from']) {
          final String from => DateTime.tryParse(from),
          _ => null,
        },
        season: ColourSeason.values.asNameMap()[json['season']],
      );
    }
    return null;
  }

  /// "jpg" or "png", from the picture's first bytes; "jpg" when unknown.
  static String extensionOf(List<int> picture) =>
      picture.length >= 4 &&
          picture[0] == 0x89 &&
          picture[1] == 0x50 &&
          picture[2] == 0x4E &&
          picture[3] == 0x47
      ? 'png'
      : 'jpg';

  static String contentType(String extension) =>
      extension == 'png' ? 'image/png' : 'image/jpeg';
}
