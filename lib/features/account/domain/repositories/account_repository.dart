import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/account/domain/entities/account_plan.dart';
import 'package:in_vogue/features/account/domain/entities/account_setup.dart';
import 'package:in_vogue/features/account/domain/entities/saved_account.dart';

abstract interface class AccountRepository {
  /// Whether the account [accountId] has been saved.
  Future<Either<Failure, bool>> exists(String accountId);

  /// The account's plan; null before the account is saved.
  Future<Either<Failure, AccountPlan?>> plan(String accountId);

  /// Deletes the account [accountId]'s data and files from the server.
  Future<Either<Failure, Unit>> delete(String accountId);

  /// Saves [setup] on the account [accountId]. A photo is uploaded only when
  /// the account holds another; a favourite is removed only when the phone
  /// unloved it since it last saved.
  Future<Either<Failure, Unit>> save(String accountId, AccountSetup setup);

  /// What the account [accountId] keeps for a phone to take back; null
  /// before the account is saved.
  Future<Either<Failure, SavedAccount?>> saved(String accountId);

  /// Downloads the account photo kept at [path]; the file it is in on the
  /// phone.
  Future<Either<Failure, String>> downloadPhoto(String path);
}
