import 'package:equatable/equatable.dart';

/// An outfit on the person: the try-on picture and why it suits the day.
class TriedOnOutfit extends Equatable {
  const TriedOnOutfit({
    required this.imagePath,
    required this.description,
    required this.reason,
  });

  /// The try-on picture, saved on the phone.
  final String imagePath;

  /// The person in the outfit, naming its pieces, for screen readers.
  final String description;

  /// One sentence on why it suits the day's weather and occasion.
  final String reason;

  @override
  List<Object?> get props => [imagePath, description, reason];
}
