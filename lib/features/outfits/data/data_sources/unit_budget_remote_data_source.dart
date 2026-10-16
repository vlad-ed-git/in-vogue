import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/outfits/data/models/unit_budget_model.dart';

/// The try-on budget in Firestore (`usage/youcam`: units spent and their
/// limit).
///
/// Every method throws [NetworkException] or [ServerException].
abstract interface class UnitBudgetRemoteDataSource {
  /// Adds [units] to the units spent unless that passes the limit; whether
  /// it did.
  Future<bool> reserve(int units);

  /// Takes [units] off the units spent.
  Future<void> release(int units);
}

class UnitBudgetRemoteDataSourceImpl implements UnitBudgetRemoteDataSource {
  UnitBudgetRemoteDataSourceImpl(this._firestore);
  final FirebaseFirestore _firestore;

  static const _offline = {'unavailable', 'deadline-exceeded'};

  DocumentReference<Map<String, dynamic>> get _usage =>
      _firestore.collection('usage').doc('youcam');

  @override
  Future<bool> reserve(int units) => _guard(
    () => _firestore.runTransaction((transaction) async {
      final usage = (await transaction.get(_usage)).data();
      final spent = (usage?['unitsSpent'] as num?)?.toInt() ?? 0;
      final limit =
          (usage?['unitLimit'] as num?)?.toInt() ??
          UnitBudgetModel.developmentLimit;
      if (!UnitBudgetModel.allows(spent: spent, limit: limit, units: units)) {
        return false;
      }
      transaction.set(_usage, {
        'unitsSpent': spent + units,
        'unitLimit': limit,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }),
  );

  @override
  Future<void> release(int units) => _guard(
    () => _usage.update({
      'unitsSpent': FieldValue.increment(-units),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (error, stack) {
      if (_offline.contains(error.code)) throw NetworkException(error, stack);
      throw ServerException(error, stack);
    }
  }
}
