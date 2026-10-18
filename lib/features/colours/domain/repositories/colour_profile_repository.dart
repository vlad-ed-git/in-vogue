import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';

/// The colours read from each face photo, kept on the account by the
/// photo's content, so a photo is read once.
abstract interface class ColourProfileRepository {
  /// The colours read from [facePhoto]; null when it hasn't been read.
  Future<Either<Failure, FaceColours?>> colours(
    String accountId,
    String facePhoto,
  );

  Future<Either<Failure, Unit>> save(
    String accountId,
    String facePhoto,
    FaceColours colours,
  );
}
