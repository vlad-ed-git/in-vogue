import 'package:equatable/equatable.dart';

/// The profile an account keeps that a phone can take back.
class SavedAccount extends Equatable {
  const SavedAccount({this.name, this.face});

  final String? name;

  /// Where the face photo is kept on the account.
  final String? face;

  @override
  List<Object?> get props => [name, face];
}
