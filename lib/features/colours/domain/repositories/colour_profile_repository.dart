import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';

/// The colours read from each face photo, kept on the account by the
/// photo's content. The one saved last is the person's reading.
abstract interface class ColourProfileRepository {
  /// The colours read from [facePhoto]; null when it hasn't been read.
  Future<Either<Failure, FaceColours?>> colours(
    String accountId,
    String facePhoto,
  );

  /// The person's reading: the colours saved last, from any face photo;
  /// null when none has been read.
  Future<Either<Failure, FaceColours?>> latest(String accountId);

  /// Keeps [colours] as [facePhoto]'s and makes them the person's reading.

  Future<Either<Failure, Unit>> save(
    String accountId,
    String facePhoto,
    FaceColours colours,
  );
}
