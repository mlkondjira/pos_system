import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import '../../data/database/pos_database.dart';

// --- Events ---
abstract class ProductsEvent extends Equatable {
  const ProductsEvent();
  @override
  List<Object?> get props => [];
}

class UpdateProductPrice extends ProductsEvent {
  final int productId;
  final double newPriceHt;
  final int actorId;

  const UpdateProductPrice({
    required this.productId,
    required this.newPriceHt,
    required this.actorId,
  });
}

class DeleteProduct extends ProductsEvent {
  final int productId;
  final int actorId;
  const DeleteProduct(this.productId, this.actorId);
  @override
  List<Object?> get props => [productId, actorId];
}

// --- State ---
class ProductsState extends Equatable {
  final bool isLoading;
  final String? error;
  final bool success;

  const ProductsState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  ProductsState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    bool? clearError,
  }) {
    return ProductsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError == true ? null : error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, success];
}

// --- Bloc ---
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final PosDatabase _db;

  ProductsBloc(this._db) : super(const ProductsState()) {
    on<UpdateProductPrice>(_onUpdateProductPrice);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onUpdateProductPrice(
    UpdateProductPrice event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, success: false, clearError: true));
    try {
      // 1. Récupérer le produit actuel pour comparer le prix
      final currentProduct = await (_db.select(
        _db.products,
      )..where((p) => p.id.equals(event.productId))).getSingle();

      // 2. Mettre à jour le produit dans la base de données
      final companion = ProductsCompanion(
        priceHt: Value(event.newPriceHt),
        updatedAt: Value(DateTime.now()),
      );
      await (_db.update(
        _db.products,
      )..where((p) => p.id.equals(event.productId))).write(companion);

      // 3. Enregistrer l'audit si le prix a changé
      if (currentProduct.priceHt != event.newPriceHt) {
        await _db.addAuditLog(
          actorId: event.actorId,
          action: 'product_price_changed',
          targetEntityType: 'product',
          targetEntityId: event.productId,
          details: jsonEncode({
            'productName': currentProduct.name,
            'from': currentProduct.priceHt,
            'to': event.newPriceHt,
          }),
        );
      }
      emit(state.copyWith(isLoading: false, success: true));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Erreur de mise à jour du prix: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, success: false, clearError: true));
    try {
      await _db.deleteProduct(event.productId, event.actorId);
      emit(state.copyWith(isLoading: false, success: true));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Erreur lors de la suppression du produit : $e',
        ),
      );
    }
  }
}
