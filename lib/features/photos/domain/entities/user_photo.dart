import 'package:equatable/equatable.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';

/// A photo of the person, kept privately on the phone.
class UserPhoto extends Equatable {
  const UserPhoto({
    required this.role,
    required this.path,
    required this.revision,
  });

  final PhotoRole role;

  /// The private file.
  final String path;

  /// 1 for the first photo; one more for each replacement.
  final int revision;

  @override
  List<Object?> get props => [role, path, revision];
}
