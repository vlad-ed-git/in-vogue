import 'package:cloud_firestore/cloud_firestore.dart';

/// Error reports, each a document in the top-level `errors` collection,
/// which the app may only add to.
abstract interface class ErrorReportRemoteDataSource {
  /// Files [report].
  Future<void> send(Map<String, Object?> report);
}

class ErrorReportRemoteDataSourceImpl implements ErrorReportRemoteDataSource {
  const ErrorReportRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const collection = 'errors';

  @override
  Future<void> send(Map<String, Object?> report) =>
      _firestore.collection(collection).add(report);
}
