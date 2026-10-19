import 'package:equatable/equatable.dart';

/// What a person did that says something about their taste, and how much
/// it says (design §8.1): a label of +1 or −1 and a weight.
enum TasteSignalKind {
  /// Picked an outfit in setup.
  picked(1, 1),

  /// Loved an outfit on Home.
  loved(1, 0.8),

  /// Unloved an outfit.
  unloved(-1, 0.4),

  /// Tapped Buy on one of an outfit's pieces.
  bought(1, 0.5),

  /// Kept the outfit made for a day.
  kept(1, 0.2),

  /// Added an outfit of their own; only its colours count.
  wardrobe(1, 0.3);

  const TasteSignalKind(this.label, this.weight);

  final int label;
  final double weight;
}

/// One thing a person did that the taste model learns from.
class TasteSignal extends Equatable {
  const TasteSignal({
    required this.id,
    required this.kind,
    required this.at,
    this.outfitId,
    this.families = const {},
  });

  /// Unique, so a signal kept on two phones counts once.
  final String id;
  final TasteSignalKind kind;
  final DateTime at;

  /// The catalog outfit it is about; null for one of the person's own.
  final String? outfitId;

  /// The colour families of an outfit of the person's own.
  final Set<String> families;

  @override
  List<Object?> get props => [id, kind, at, outfitId, families];
}
