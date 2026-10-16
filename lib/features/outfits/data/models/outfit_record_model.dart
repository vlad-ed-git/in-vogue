import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';

/// An outfit made for an account, as its record in
/// `users/{uid}/outfits/{signature}` holds it.
typedef OutfitRecord = ({
  String signature,
  String outfitId,
  List<String> pieces,
  String cell,
  DateTime date,
  Occasion occasion,
  String imagePath,
  DateTime? createdAt,
});

/// The outfit records' fields and the pictures' paths.
abstract final class OutfitRecordModel {
  /// Where the picture of [signature] is kept in Storage; [extension]
  /// names its image type.
  static String imagePath(
    String accountId,
    String signature,
    String extension,
  ) => 'users/$accountId/outfits/$signature.$extension';

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

  /// The record's fields, without its creation time.
  static Map<String, Object?> toJson(OutfitRecord record) => {
    'outfitId': record.outfitId,
    'pieces': record.pieces,
    'cell': record.cell,
    'forDate': TryOnJob.dateKey(record.date),
    'occasion': record.occasion.name,
    'imagePath': record.imagePath,
  };

  /// Null when [json] is not a readable record.
  static OutfitRecord? fromJson(
    String signature,
    Map<String, Object?> json, {
    DateTime? createdAt,
  }) {
    if (json case {
      'outfitId': final String outfitId,
      'pieces': final List<Object?> pieces,
      'cell': final String cell,
      'forDate': final String forDate,
      'occasion': final String occasion,
      'imagePath': final String imagePath,
    }) {
      final date = DateTime.tryParse('${forDate}T00:00:00Z');
      final kind = Occasion.values.asNameMap()[occasion];
      if (date == null || kind == null) return null;
      return (
        signature: signature,
        outfitId: outfitId,
        pieces: pieces.whereType<String>().toList(),
        cell: cell,
        date: date,
        occasion: kind,
        imagePath: imagePath,
        createdAt: createdAt,
      );
    }
    return null;
  }
}
