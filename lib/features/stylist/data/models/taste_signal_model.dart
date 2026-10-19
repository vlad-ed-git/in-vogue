import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';

/// A taste signal as the phone and the account keep it.
abstract final class TasteSignalModel {
  static Map<String, Object?> toJson(TasteSignal signal) => {
    'id': signal.id,
    'kind': signal.kind.name,
    'at': signal.at.toUtc().toIso8601String(),
    'outfit': signal.outfitId,
    'families': signal.families.toList()..sort(),
  };

  /// Null when [json] is not a readable signal.
  static TasteSignal? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'kind': final String kind,
      'at': final String at,
    }) {
      final named = TasteSignalKind.values.asNameMap()[kind];
      final when = DateTime.tryParse(at);
      if (named == null || when == null) return null;
      return TasteSignal(
        id: id,
        kind: named,
        at: when,
        outfitId: switch (json['outfit']) {
          final String outfit => outfit,
          _ => null,
        },
        families: switch (json['families']) {
          final List<Object?> families => families.whereType<String>().toSet(),
          _ => const {},
        },
      );
    }
    return null;
  }
}
