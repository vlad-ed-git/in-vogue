import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_shop_pieces.dart';

sealed class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object?> get props => [];
}

/// Shows the colourways [colourwayIds], in that order.
final class ShopRequested extends ShopEvent {
  const ShopRequested(this.colourwayIds);
  final List<String> colourwayIds;

  @override
  List<Object?> get props => [colourwayIds];
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
  ShopBloc({required this._getShopPieces}) : super(const ShopState()) {
    on<ShopRequested>(_load, transformer: droppable());
  }

  final GetShopPieces _getShopPieces;

  Future<void> _load(ShopRequested event, Emitter<ShopState> emit) async {
    final found = await _getShopPieces(event.colourwayIds);
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
}
