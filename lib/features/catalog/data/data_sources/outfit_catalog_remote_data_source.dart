import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';

/// The curated catalog in Firestore: its summary, `catalog/outfits`, and
/// one document per outfit, `outfits/{id}`. Every method reads the server
/// and throws [NetworkException] or [ServerException].
abstract interface class OutfitCatalogRemoteDataSource {
  /// The catalog's version, which changes whenever the catalog does.
  Future<int> version();

  /// The onboarding sample's documents, which anyone may read.
  Future<List<Map<String, Object?>>> sample();

  /// Every outfit's document; needs a signed-in person.
  Future<List<Map<String, Object?>>> outfits();
}

class OutfitCatalogRemoteDataSourceImpl
    implements OutfitCatalogRemoteDataSource {
  OutfitCatalogRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _server = GetOptions(source: Source.server);

  static const _offline = {
    'unavailable',
    'deadline-exceeded',
    'network-request-failed',
  };

  CollectionReference<Map<String, dynamic>> get _outfits =>
      _firestore.collection('outfits');

  @override
  Future<int> version() => _guard(() async {
    final summary = await _firestore
        .collection('catalog')
        .doc('outfits')
        .get(_server);
    return switch (summary.data()) {
      {'version': final int version} => version,
      _ => throw ServerException(
        const FormatException('No catalog version'),
        StackTrace.current,
      ),
    };
  });

  @override
  Future<List<Map<String, Object?>>> sample() => _guard(
    () async => _documents(
      await _outfits.where('sample', isEqualTo: true).get(_server),
    ),
  );

  @override
  Future<List<Map<String, Object?>>> outfits() =>
      _guard(() async => _documents(await _outfits.get(_server)));

  /// The documents' fields, without the server's timestamp.
  static List<Map<String, Object?>> _documents(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => [
    for (final doc in snapshot.docs)
      Map<String, Object?>.of(doc.data())..remove('updatedAt'),
  ];

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (error, stack) {
      throw _offline.contains(error.code)
          ? NetworkException(error, stack)
          : ServerException(error, stack);
    }
  }
}
