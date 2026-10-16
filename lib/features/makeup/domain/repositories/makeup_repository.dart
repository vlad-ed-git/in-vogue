import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';

/// The knowledge base's makeup recipes, the colours analysed from each
/// face photo, and the looks made for each account with their pictures.
abstract interface class MakeupRepository {
  /// The recipe [key]; null when the knowledge base has none.
  Future<Either<Failure, MakeupRecipe?>> recipe(String key);

  /// The colours analysed from the face photo at [facePhoto]; null when it
  /// was never analysed.
  Future<Either<Failure, FaceColours?>> faceColours(
    String accountId,
    String facePhoto,
  );

  /// Keeps [colours] on the account as analysed from the face photo at
  /// [facePhoto].
  Future<Either<Failure, Unit>> saveFaceColours(
    String accountId,
    String facePhoto,
    FaceColours colours,
  );

  /// The picture [fileName] of the look for [outfitSignature] on the
  /// phone; null when there is none.
  Future<Either<Failure, String?>> keptPicture(
    String accountId,
    String outfitSignature,
    String fileName,
  );

  /// Keeps [picture] on the phone as [name] of the look for
  /// [outfitSignature], with its image type's extension; its file.
  Future<Either<Failure, String>> keepPicture(
    String accountId,
    String outfitSignature,
    String name,
    List<int> picture,
  );

  /// Saves [look] and its pictures on the account.
  Future<Either<Failure, Unit>> record(String accountId, MakeupLook look);

  /// The look made for the outfit [outfitSignature], with its pictures on
  /// the phone; null when none was made.
  Future<Either<Failure, MakeupLook?>> look(
    String accountId,
    String outfitSignature,
  );

  /// The look made last for [accountId]; null when none was.
  Future<Either<Failure, MakeupLook?>> latestLook(String accountId);

  /// Deletes [accountId]'s makeup pictures from the phone.
  Future<Either<Failure, Unit>> forgetPictures(String accountId);
}
