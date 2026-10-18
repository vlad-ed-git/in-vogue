import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';

/// The outfits the person owns, kept on the account with their photos, and
/// a copy of each photo on the phone.
abstract interface class WardrobeRepository {
  /// The account's outfits, newest first, whenever they change on any
  /// phone.
  Stream<Either<Failure, List<WardrobeOutfit>>> watch(String accountId);

  /// Adds the outfit in the photo at [photo] with its [details].
  Future<Either<Failure, WardrobeOutfit>> add(
    String accountId, {
    required String photo,
    required OutfitDetails details,
  });

  /// Removes [outfit] and its photo from the account and the phone.
  Future<Either<Failure, Unit>> remove(String accountId, WardrobeOutfit outfit);

  /// Forgets the account's outfit photos on this phone.
  Future<void> forgetPhotos(String accountId);
}
