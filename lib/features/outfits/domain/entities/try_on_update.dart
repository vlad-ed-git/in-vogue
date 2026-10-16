import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';

/// What making an outfit reports.
sealed class TryOnUpdate extends Equatable {
  const TryOnUpdate();

  @override
  List<Object?> get props => [];
}

/// The try-on is putting on [piece] of [pieces], counted from 1.
final class TryOnProgress extends TryOnUpdate {
  const TryOnProgress({required this.piece, required this.pieces});

  final int piece;
  final int pieces;

  @override
  List<Object?> get props => [piece, pieces];
}

/// The outfit is made.
final class TryOnDone extends TryOnUpdate {
  const TryOnDone(this.outfit);
  final DayOutfit outfit;

  @override
  List<Object?> get props => [outfit];
}

/// The outfit could not be made.
final class TryOnFailed extends TryOnUpdate {
  const TryOnFailed(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
