import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/account/domain/entities/account_setup.dart';

abstract interface class AccountRepository {
  /// Whether the account [accountId] has been saved.
  Future<Either<Failure, bool>> exists(String accountId);

  /// Saves [setup] on the account [accountId]. Photos are uploaded only when
  /// the account holds another revision; the wishlist mirrors the picks.
  Future<Either<Failure, Unit>> save(String accountId, AccountSetup setup);
}
