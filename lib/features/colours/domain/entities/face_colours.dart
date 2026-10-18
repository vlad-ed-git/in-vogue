import 'package:equatable/equatable.dart';

/// The colours the skin-tone analysis sampled from a face photo, as
/// `#RRGGBB`.
class FaceColours extends Equatable {
  const FaceColours({
    required this.skin,
    required this.eyebrow,
    required this.lip,
    required this.hair,
    required this.clear,
    this.eye,
  });

  final String skin;
  final String eyebrow;
  final String lip;
  final String hair;

  /// Null in colours read before the eyes were kept.
  final String? eye;

  /// Whether the photo was clear enough for the colours to be trusted.
  final bool clear;

  @override
  List<Object?> get props => [skin, eyebrow, lip, hair, eye, clear];
}
