import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_shop_pieces.dart';

sealed class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object?> get props => [];
}

/// Shows the pieces of a catalog [outfit], outer layer first.
final class ShopOutfitRequested extends ShopEvent {
  const ShopOutfitRequested(this.outfit);
  final CatalogOutfit outfit;

  @override
  List<Object?> get props => [outfit];
}

enum ShopStatus { loading, ready, failed }

class ShopState extends Equatable {
  const ShopState({
    this.status = ShopStatus.loading,
    this.brand = '',
    this.pieces = const [],
  });

  final ShopStatus status;

  /// The partner that sells the pieces.
  final String brand;
  final List<ShopPiece> pieces;

  @override
  List<Object?> get props => [status, brand, pieces];
}

/// The pieces of an outfit, to buy from the partner.
class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc({required this._getOutfitShop}) : super(const ShopState()) {
    on<ShopOutfitRequested>(
      (event, emit) async => _show(await _getOutfitShop(event.outfit), emit),
      transformer: droppable(),
    );
  }

  final GetOutfitShop _getOutfitShop;

  void _show(Either<Failure, ShopPieces> found, Emitter<ShopState> emit) =>
      emit(
        found.fold(
          (_) => const ShopState(status: ShopStatus.failed),
          (shop) => ShopState(
            status: ShopStatus.ready,
            brand: shop.brand,
            pieces: shop.pieces,
          ),
        ),
      );
}
