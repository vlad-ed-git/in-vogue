import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';

/// A day as its record in `users/{uid}/days/{date}_{occasion}` holds it,
/// and its picture's kind.
abstract final class DayModel {
  /// The record's fields, without its time of change.
  static Map<String, Object?> toJson(Day day) => {
    'forDate': TryOnJob.dateKey(day.date),
    'occasion': day.occasion.name,
    'cell': day.cell,
    'outfitId': day.outfitId,
    'signature': day.signature,
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
      'cell': final String cell,
      'outfitId': final String outfitId,
      'signature': final String signature,
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
        cell: cell,
        outfitId: outfitId,
        signature: signature,
        status: state,
        device: device,
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
