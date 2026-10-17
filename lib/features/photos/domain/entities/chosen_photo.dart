import 'package:equatable/equatable.dart';

/// A photo just chosen and made ready for YouCam, not yet kept.
class ChosenPhoto extends Equatable {
  const ChosenPhoto({required this.path, this.converted = false});

  final String path;

  /// Its format was changed to one YouCam takes.
  final bool converted;

  @override
  List<Object?> get props => [path, converted];
}
