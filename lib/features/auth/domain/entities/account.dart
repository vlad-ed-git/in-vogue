import 'package:equatable/equatable.dart';
import 'package:in_vogue/features/auth/domain/entities/sign_in_method.dart';

/// The signed-in person.
class Account extends Equatable {
  const Account({required this.id, this.name, this.method});

  final String id;

  /// The name the provider shared, if any.
  final String? name;

  /// How the person signed in; null when unknown.
  final SignInMethod? method;

  @override
  List<Object?> get props => [id, name, method];
}
