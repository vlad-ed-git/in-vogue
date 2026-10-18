import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';

class MakeupLookParams extends Equatable {
  const MakeupLookParams({
    required this.accountId,
    required this.outfitSignature,
  });

  final String accountId;
  final String outfitSignature;

  @override
  List<Object?> get props => [accountId, outfitSignature];
}

/// The look made for an outfit on the face photo; null when none was, or
/// without a face photo.
class GetMakeupLook implements UseCase<MakeupLook?, MakeupLookParams> {
  const GetMakeupLook(this._repository, this._photos);
  final MakeupRepository _repository;
  final PhotoRepository _photos;

  @override
  Future<Either<Failure, MakeupLook?>> call(MakeupLookParams params) async {
    final face = (await _photos.kept(
      PhotoRole.face,
    )).fold<UserPhoto?>((_) => null, (photo) => photo);
    if (face == null) return const Right(null);
    return _repository.look(
      params.accountId,
      facePhoto: face.path,
      outfitSignature: params.outfitSignature,
    );
  }
}
