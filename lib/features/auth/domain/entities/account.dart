import 'package:equatable/equatable.dart';

/// The signed-in person.
class Account extends Equatable {
  const Account({required this.id, this.name});

  final String id;

  /// The name the provider shared, if any.
  final String? name;

  @override
  List<Object?> get props => [id, name];
}
