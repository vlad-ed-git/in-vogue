import 'package:equatable/equatable.dart';

/// What an account keeps that a phone can take back.
class SavedAccount extends Equatable {
  const SavedAccount({this.name, this.face, this.favourites = const {}});

  final String? name;

  /// Where the face photo is kept on the account.
  final String? face;

  /// Ids of the loved colourways.
  final Set<String> favourites;

  @override
  List<Object?> get props => [name, face, favourites];
}
