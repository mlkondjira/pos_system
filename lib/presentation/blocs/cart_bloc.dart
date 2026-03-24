// lib/presentation/blocs/cart/cart_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/database/pos_database.dart';

// ── STATE ──────────────────────────────────────────────────────

class CartItem extends Equatable {
  final int productId;
  final String name;
  final double unitPriceHt;
  final double taxRate;
  final double priceTtc;
  final int quantity;
  final double discountPct;
  final String unit;

  const CartItem({
    required this.productId,
    required this.name,
    required this.unitPriceHt,
    required this.taxRate,
    required this.priceTtc,
    required this.quantity,
    this.discountPct = 0,
    this.unit = 'pce',
  });

  double get lineTotalTtc {
    final base = priceTtc * quantity;
    return base * (1 - discountPct / 100);
  }

  CartItem copyWith({int? quantity, double? discountPct}) => CartItem(
    productId: productId, name: name,
    unitPriceHt: unitPriceHt, taxRate: taxRate, priceTtc: priceTtc,
    quantity: quantity ?? this.quantity,
    discountPct: discountPct ?? this.discountPct,
    unit: unit,
  );

  @override
  List<Object?> get props => [productId, quantity, discountPct];
}

class CartState extends Equatable {
  final List<CartItem> items;
  final double globalDiscount; // montant fixe
  final int? customerId;
  final String? customerName;
  final String note;

  const CartState({
    this.items = const [],
    this.globalDiscount = 0,
    this.customerId,
    this.customerName,
    this.note = '',
  });

  double get subtotalTtc => items.fold(0, (s, i) => s + i.lineTotalTtc);
  double get totalTtc => (subtotalTtc - globalDiscount).clamp(0, double.infinity);
  double get totalHt => items.fold(0, (s, i) => s + i.unitPriceHt * i.quantity * (1 - i.discountPct / 100));
  double get totalTax => totalTtc - totalHt;
  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items, double? globalDiscount,
    int? customerId, String? customerName, String? note,
  }) => CartState(
    items: items ?? this.items,
    globalDiscount: globalDiscount ?? this.globalDiscount,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    note: note ?? this.note,
  );

  @override
  List<Object?> get props => [items, globalDiscount, customerId, note];
}

// ── EVENTS ─────────────────────────────────────────────────────

abstract class CartEvent extends Equatable {
  @override List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;
  AddToCart(this.product);
  @override List<Object?> get props => [product.id];
}

class RemoveFromCart extends CartEvent {
  final int productId;
  RemoveFromCart(this.productId);
  @override List<Object?> get props => [productId];
}

class UpdateQuantity extends CartEvent {
  final int productId;
  final int quantity;
  UpdateQuantity(this.productId, this.quantity);
  @override List<Object?> get props => [productId, quantity];
}

class SetItemDiscount extends CartEvent {
  final int productId;
  final double discountPct;
  SetItemDiscount(this.productId, this.discountPct);
  @override List<Object?> get props => [productId, discountPct];
}

class SetGlobalDiscount extends CartEvent {
  final double amount;
  SetGlobalDiscount(this.amount);
  @override List<Object?> get props => [amount];
}

class SetCustomer extends CartEvent {
  final int? customerId;
  final String? customerName;
  SetCustomer(this.customerId, this.customerName);
}

class SetNote extends CartEvent {
  final String note;
  SetNote(this.note);
}

class ClearCart extends CartEvent {}

// ── BLOC ───────────────────────────────────────────────────────

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>((e, emit) {
      final items = List<CartItem>.from(state.items);
      final idx = items.indexWhere((i) => i.productId == e.product.id);
      if (idx >= 0) {
        items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
      } else {
        final priceTtc = e.product.priceHt * (1 + e.product.taxRate);
        items.add(CartItem(
          productId: e.product.id,
          name: e.product.name,
          unitPriceHt: e.product.priceHt,
          taxRate: e.product.taxRate,
          priceTtc: priceTtc,
          quantity: 1,
          unit: e.product.unit,
        ));
      }
      emit(state.copyWith(items: items));
    });

    on<RemoveFromCart>((e, emit) {
      emit(state.copyWith(
        items: state.items.where((i) => i.productId != e.productId).toList(),
      ));
    });

    on<UpdateQuantity>((e, emit) {
      if (e.quantity <= 0) {
        add(RemoveFromCart(e.productId));
        return;
      }
      final items = state.items.map((i) =>
          i.productId == e.productId ? i.copyWith(quantity: e.quantity) : i).toList();
      emit(state.copyWith(items: items));
    });

    on<SetItemDiscount>((e, emit) {
      final items = state.items.map((i) =>
          i.productId == e.productId ? i.copyWith(discountPct: e.discountPct) : i).toList();
      emit(state.copyWith(items: items));
    });

    on<SetGlobalDiscount>((e, emit) => emit(state.copyWith(globalDiscount: e.amount)));
    on<SetCustomer>((e, emit) => emit(state.copyWith(customerId: e.customerId, customerName: e.customerName)));
    on<SetNote>((e, emit) => emit(state.copyWith(note: e.note)));
    on<ClearCart>((_, emit) => emit(const CartState()));
  }
}
