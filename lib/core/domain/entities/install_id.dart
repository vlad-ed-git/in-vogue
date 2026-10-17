import 'package:equatable/equatable.dart';

/// Identifies this install of the app among the phones signed in to an
/// account.
class InstallId extends Equatable {
  const InstallId(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}
