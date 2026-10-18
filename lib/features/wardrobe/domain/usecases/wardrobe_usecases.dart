import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/wardrobe/domain/repositories/wardrobe_repository.dart';

/// The account's outfits, newest first, as they change on any phone.
class WatchWardrobe {
  const WatchWardrobe(this._repository);
  final WardrobeRepository _repository;

  Stream<Either<Failure, List<WardrobeOutfit>>> call(String accountId) =>
      _repository.watch(accountId);
}

/// Adds an outfit the person owns, from the photo at [photo].
class AddToWardrobe {
  const AddToWardrobe(this._repository);
  final WardrobeRepository _repository;

  Future<Either<Failure, WardrobeOutfit>> call(
    String accountId, {
    required String photo,
    required OutfitDetails details,
  }) => _repository.add(accountId, photo: photo, details: details);
}

/// Removes an outfit and its photo, everywhere.
class RemoveFromWardrobe {
  const RemoveFromWardrobe(this._repository);
  final WardrobeRepository _repository;

  Future<Either<Failure, Unit>> call(String accountId, WardrobeOutfit outfit) =>
      _repository.remove(accountId, outfit);
}
