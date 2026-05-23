// lib/presentation/blocs/cart/cart_bloc.dart
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/promotion_engine.dart';
import '../../../data/database/pos_database.dart';
import '../../../core/di/injection.dart';

// ── STATE ──────────────────────────────────────────────────────

class CartItem extends Equatable {
  final Product product; // L'objet complet généré par Drift
  final int quantity;
  final double discountPct;
  final double
  autoDiscountPct; // Nouveau: Remise automatique (Happy Hour, etc.)
  final double discountAmount;

  const CartItem({
    required this.product,
    required this.quantity,
    this.discountPct = 0,
    this.autoDiscountPct = 0,
    this.discountAmount = 0,
  });

  int get productId => product.id;
  double get unitPriceHt => product.priceHt;
  double get priceTtc => product.priceTtc; // Utilise l'extension sur Product

  double get lineTotalTtc {
    // On prend la remise la plus avantageuse entre manuelle et automatique
    final effectivePct = max(discountPct, autoDiscountPct);
    final totalBrut = priceTtc * quantity;
    final totalApresPct = totalBrut * (1 - effectivePct / 100);
    return (totalApresPct - discountAmount).clamp(0, double.infinity);
  }

  CartItem copyWith({
    int? quantity,
    double? discountPct,
    double? autoDiscountPct,
    double? discountAmount,
  }) => CartItem(
    product: product,
    quantity: quantity ?? this.quantity,
    discountPct: discountPct ?? this.discountPct,
    autoDiscountPct: autoDiscountPct ?? this.autoDiscountPct,
    discountAmount: discountAmount ?? this.discountAmount,
  );

  @override
  List<Object?> get props => [
    product,
    quantity,
    discountPct,
    autoDiscountPct,
    discountAmount,
  ];
  // Utiliser l'objet product complet dans les props assure que si une donnée
  // du produit change (ex: prix mis à jour), le Bloc émettra un nouvel état
  // et l'UI se rafraîchira.
}

class CartParkedState extends Equatable {
  final int? id; // L'ID de la base de données
  final List<CartItem> items;
  final double globalDiscount;
  final int? customerId;
  final String? customerName;
  final String note;
  final DateTime parkedAt;
  final String label; // ex: "Table 5" ou "Client pressé"

  const CartParkedState({
    this.id,
    required this.items,
    required this.globalDiscount,
    this.customerId,
    this.customerName,
    required this.note,
    required this.parkedAt,
    required this.label,
  });

  @override
  List<Object?> get props => [
    items,
    globalDiscount,
    customerId,
    note,
    parkedAt,
    label,
  ];
}

class CartState extends Equatable {
  final List<CartItem> items;
  final double globalDiscount; // montant fixe
  final int? customerId;
  final String? customerName;
  final String note;
  final String? couponCode;
  final Discount? appliedDiscount;
  final List<CartParkedState> parkedSales;
  final double loyaltyPointsEarned;
  final String? error;

  const CartState({
    this.items = const [],
    this.globalDiscount = 0,
    this.customerId,
    this.customerName,
    this.note = '',
    this.couponCode,
    this.appliedDiscount,
    this.parkedSales = const [],
    this.loyaltyPointsEarned = 0,
    this.error,
  });

  double get subtotalTtc => items.fold(0, (s, i) => s + i.lineTotalTtc);
  double get totalTtc =>
      (subtotalTtc - globalDiscount).clamp(0, double.infinity);

  /// Facteur de prorata pour ventiler la remise globale sur chaque ligne
  double get _globalDiscountFactor =>
      subtotalTtc > 0 ? totalTtc / subtotalTtc : 1.0;

  /// Calcule le total HT exact après toutes les remises (ligne + globale)
  double get totalHt {
    return items.fold(0.0, (sum, item) {
      // 1. On prend le total TTC de la ligne (déjà réduit par les remises lignes)
      // 2. On lui applique le prorata de la remise globale
      final lineTtcEffective = item.lineTotalTtc * _globalDiscountFactor;
      // 3. On extrait le HT à partir du TTC effectif selon le taux de l'article
      final lineHtEffective =
          lineTtcEffective / (1 + (item.product.taxRate ?? 0.0));
      return sum + lineHtEffective;
    });
  }

  /// Calcule le total des taxes exact après remises
  double get totalTax {
    return items.fold(0.0, (sum, item) {
      final lineTtcEffective = item.lineTotalTtc * _globalDiscountFactor;
      final lineHtEffective =
          lineTtcEffective / (1 + (item.product.taxRate ?? 0.0));
      final lineTaxEffective = lineTtcEffective - lineHtEffective;
      return sum + lineTaxEffective;
    });
  }

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    double? globalDiscount,
    int? customerId,
    String? customerName,
    String? note,
    String? couponCode,
    Discount? appliedDiscount,
    List<CartParkedState>? parkedSales,
    double? loyaltyPointsEarned,
    String? error,
  }) => CartState(
    items: items ?? this.items,
    globalDiscount: globalDiscount ?? this.globalDiscount,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    note: note ?? this.note,
    couponCode: couponCode ?? this.couponCode,
    appliedDiscount: appliedDiscount ?? this.appliedDiscount,
    parkedSales: parkedSales ?? this.parkedSales,
    loyaltyPointsEarned: loyaltyPointsEarned ?? this.loyaltyPointsEarned,
    error: error,
  );

  @override
  List<Object?> get props => [
    items,
    globalDiscount,
    customerId,
    customerName,
    note,
    couponCode,
    appliedDiscount,
    parkedSales,
    loyaltyPointsEarned,
    error,
  ];
}

// ── EVENTS ─────────────────────────────────────────────────────

abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;
  AddToCart(this.product);
  @override
  List<Object?> get props => [product.id];
}

class RemoveFromCart extends CartEvent {
  final int productId;
  RemoveFromCart(this.productId);
  @override
  List<Object?> get props => [productId];
}

class UpdateQuantity extends CartEvent {
  final int productId;
  final int quantity;
  UpdateQuantity(this.productId, this.quantity);
  @override
  List<Object?> get props => [productId, quantity];
}

class SetItemDiscount extends CartEvent {
  final int productId;
  final double discountPct;
  SetItemDiscount(this.productId, this.discountPct);
  @override
  List<Object?> get props => [productId, discountPct];
}

class SetItemDiscountAmount extends CartEvent {
  final int productId;
  final double discountAmount;
  SetItemDiscountAmount(this.productId, this.discountAmount);
}

class SetGlobalDiscount extends CartEvent {
  final double amount;
  SetGlobalDiscount(this.amount);
  @override
  List<Object?> get props => [amount];
}

class SetCustomer extends CartEvent {
  final int? customerId;
  final String? customerName;
  SetCustomer(this.customerId, this.customerName);
}

class SetCoupon extends CartEvent {
  final String? code;
  SetCoupon(this.code);
  @override
  List<Object?> get props => [code];
}

class SetNote extends CartEvent {
  final String note;
  SetNote(this.note);
}

class ClearCart extends CartEvent {}

class LoadParkedCarts extends CartEvent {}

class ClearParkedSales extends CartEvent {}

class ParkCart extends CartEvent {
  final String label;
  ParkCart(this.label);
  @override
  List<Object?> get props => [label];
}

class RestoreParkedCart extends CartEvent {
  final int index;
  RestoreParkedCart(this.index);
  @override
  List<Object?> get props => [index];
}

class DeleteParkedCart extends CartEvent {
  final int index;
  DeleteParkedCart(this.index);
  @override
  List<Object?> get props => [index];
}

class _UpdateLoyaltyPoints extends CartEvent {
  final double points;
  _UpdateLoyaltyPoints(this.points);
  @override
  List<Object?> get props => [points];
}

class ClearCartError extends CartEvent {}

// ── BLOC ───────────────────────────────────────────────────────

class CartBloc extends Bloc<CartEvent, CartState> {
  final PosDatabase _db = getIt<PosDatabase>();
  Map<String, String>? _cachedSettings;

  CartBloc() : super(const CartState()) {
    on<LoadParkedCarts>(_onLoadParkedCarts);
    on<AddToCart>((e, emit) async {
      final items = _updateItemQuantity(e.product, 1);
      emit(await _calculateState(items: items));
    });

    on<ClearCartError>((_, emit) => emit(state.copyWith(error: null)));

    on<RemoveFromCart>((e, emit) async {
      final items = state.items
          .where((i) => i.productId != e.productId)
          .toList();
      emit(await _calculateState(items: items));
    });

    on<UpdateQuantity>((e, emit) async {
      if (e.quantity <= 0) {
        add(RemoveFromCart(e.productId));
        return;
      }
      final items = state.items
          .map(
            (i) => i.productId == e.productId
                ? i.copyWith(quantity: e.quantity)
                : i,
          )
          .toList();
      emit(await _calculateState(items: items));
    });

    on<SetItemDiscount>((e, emit) async {
      final items = state.items
          .map(
            (i) => i.productId == e.productId
                ? i.copyWith(discountPct: e.discountPct)
                : i,
          )
          .toList();
      emit(await _calculateState(items: items));
    });

    on<SetItemDiscountAmount>((e, emit) async {
      final items = state.items
          .map(
            (i) => i.productId == e.productId
                ? i.copyWith(discountAmount: e.discountAmount)
                : i,
          )
          .toList();
      emit(await _calculateState(items: items));
    });

    on<SetGlobalDiscount>((e, emit) async {
      final newState = await _calculateState(
        items: state.items,
        clearDiscount: true,
      );
      emit(
        newState.copyWith(
          globalDiscount: e.amount,
          couponCode: null,
          appliedDiscount: null,
        ),
      );
    });

    on<SetCoupon>((e, emit) async {
      if (e.code == null || e.code!.isEmpty) {
        emit(await _calculateState(clearDiscount: true, error: null));
        return;
      }

      // Recherche du coupon dans la table Discounts (champ name utilisé comme code)
      final discount =
          await (_db.select(_db.discounts)..where(
                (d) =>
                    d.name.equals(e.code!.toUpperCase()) &
                    d.isActive.equals(true) &
                    d.isArchived.equals(false),
              ))
              .getSingleOrNull();

      if (discount == null) {
        emit(
          await _calculateState(
            clearDiscount: true,
            error: 'Code coupon invalide ou expiré.',
          ),
        );
        return;
      }

      // Vérification spécifique : Une fois par client
      if (discount.limitPerCustomer && state.customerId != null) {
        final alreadyUsed = await _db.checkCouponAlreadyUsedByCustomer(
          state.customerId!,
          discount.name,
        );
        if (alreadyUsed) {
          emit(
            await _calculateState(
              clearDiscount: true,
              error: 'Ce client a déjà utilisé ce coupon.',
            ),
          );
          return;
        }
      }

      emit(await _calculateState(discountOverride: discount, error: null));
    });

    on<SetCustomer>((e, emit) async {
      // Si un coupon avec limite par client est déjà présent, on vérifie le nouveau client
      if (state.appliedDiscount != null &&
          state.appliedDiscount!.limitPerCustomer &&
          e.customerId != null) {
        final alreadyUsed = await _db.checkCouponAlreadyUsedByCustomer(
          e.customerId!,
          state.appliedDiscount!.name,
        );
        if (alreadyUsed) {
          final newState = await _calculateState(
            customerId: e.customerId,
            clearDiscount: true,
            error: 'Ce client ne peut pas bénéficier de la remise active.',
          );
          emit(newState.copyWith(customerName: e.customerName));
          return;
        }
      }
      final newState = await _calculateState(customerId: e.customerId);
      emit(newState.copyWith(customerName: e.customerName));
    });
    on<SetNote>((e, emit) => emit(state.copyWith(note: e.note)));

    on<_UpdateLoyaltyPoints>((e, emit) {
      emit(state.copyWith(loyaltyPointsEarned: e.points));
    });

    on<ClearCart>((_, emit) => emit(CartState(parkedSales: state.parkedSales)));

    on<ParkCart>((e, emit) async {
      if (state.items.isEmpty) return;

      final parkedAt = DateTime.now();
      final cartData = jsonEncode(
        state.items
            .map(
              (i) => {
                'product': i.product.toJson(),
                'quantity': i.quantity,
                'discountPct': i.discountPct,
                'discountAmount': i.discountAmount,
              },
            )
            .toList(),
      );

      final id = await _db
          .into(_db.parkedCarts)
          .insert(
            ParkedCartsCompanion.insert(
              label: e.label,
              globalDiscount: Value(state.globalDiscount),
              customerId: Value(state.customerId),
              customerName: Value(state.customerName),
              note: Value(state.note),
              parkedAt: Value(parkedAt),
              cartData: cartData,
            ),
          );

      final parked = CartParkedState(
        id: id,
        items: List<CartItem>.from(state.items),
        globalDiscount: state.globalDiscount,
        customerId: state.customerId,
        customerName: state.customerName,
        note: state.note,
        parkedAt: parkedAt,
        label: e.label,
      );

      final newParkedSales = List<CartParkedState>.from(state.parkedSales)
        ..add(parked);
      emit(CartState(parkedSales: newParkedSales));
    });

    on<RestoreParkedCart>((e, emit) async {
      if (e.index < 0 || e.index >= state.parkedSales.length) return;

      final parked = state.parkedSales[e.index];
      if (parked.id != null) {
        await (_db.delete(
          _db.parkedCarts,
        )..where((t) => t.id.equals(parked.id!))).go();
      }

      final newParkedSales = List<CartParkedState>.from(state.parkedSales)
        ..removeAt(e.index);
      emit(
        CartState(
          items: parked.items,
          globalDiscount: parked.globalDiscount,
          customerId: parked.customerId,
          customerName: parked.customerName,
          note: parked.note,
          parkedSales: newParkedSales,
        ),
      );
    });

    on<DeleteParkedCart>((e, emit) async {
      final parked = state.parkedSales[e.index];
      if (parked.id != null) {
        await (_db.delete(
          _db.parkedCarts,
        )..where((t) => t.id.equals(parked.id!))).go();
      }

      final newParkedSales = List<CartParkedState>.from(state.parkedSales)
        ..removeAt(e.index);
      emit(state.copyWith(parkedSales: newParkedSales));
    });

    on<ClearParkedSales>((e, emit) async {
      await _db.delete(_db.parkedCarts).go();
      emit(state.copyWith(parkedSales: const []));
    });

    add(LoadParkedCarts());
  }

  Future<void> _onLoadParkedCarts(
    LoadParkedCarts e,
    Emitter<CartState> emit,
  ) async {
    final rows = await _db.select(_db.parkedCarts).get();

    final parkedSales = rows.map((row) {
      final List<dynamic> data = jsonDecode(row.cartData);
      final items = data
          .map(
            (itemJson) => CartItem(
              product: Product.fromJson(itemJson['product']),
              quantity: itemJson['quantity'],
              discountPct: (itemJson['discountPct'] as num?)?.toDouble() ?? 0.0,
              discountAmount:
                  (itemJson['discountAmount'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();

      return CartParkedState(
        id: row.id,
        label: row.label,
        items: items,
        globalDiscount: row.globalDiscount,
        customerId: row.customerId,
        customerName: row.customerName,
        note: row.note,
        parkedAt: row.parkedAt,
      );
    }).toList();

    emit(state.copyWith(parkedSales: parkedSales));
  }

  // This method now fetches discounts and applies them synchronously.
  // It should be called from _calculateState.
  Future<List<CartItem>> _getAndApplyAdvancedRules(List<CartItem> items) async {
    final shopId = await _db.getSetting('shop_id') ?? '';
    final activeDiscounts = await (_db.select(
      _db.discounts,
    )..where((d) => d.shopId.equals(shopId) & d.isActive.equals(true))).get();

    return PromotionEngine.applyPromotions(items, activeDiscounts);
  }

  /// Méthode centrale pour calculer l'état et appliquer les remises automatiques
  Future<CartState> _calculateState(
  // Make _calculateState async
  {
    List<CartItem>? items,
    Discount? discountOverride,
    bool clearDiscount = false,
    int? customerId,
    String? error,
  }) async {
    // On combine la récupération et l'application des règles pour rendre la variable finale
    final currentItems = await _getAndApplyAdvancedRules(items ?? state.items);

    final Discount? activeDiscount = clearDiscount
        ? null
        : (discountOverride ?? state.appliedDiscount);
    final int? currentCustomerId = customerId ?? state.customerId;
    final String? currentError = error;

    final String? couponCode = clearDiscount
        ? null
        : (activeDiscount?.name ?? state.couponCode);

    final double globalDiscount;
    if (activeDiscount != null) {
      final now = DateTime.now();
      final subtotal = currentItems.fold<double>(
        0,
        (s, i) => s + i.lineTotalTtc,
      );

      // Vérification des dates de validité
      final isDateValid =
          (activeDiscount.startDate == null ||
              !now.isBefore(activeDiscount.startDate!)) &&
          (activeDiscount.endDate == null ||
              !now.isAfter(activeDiscount.endDate!));

      // Vérification de la limite d'usage
      final isLimitOk =
          activeDiscount.usageLimit == null ||
          activeDiscount.currentUsage < activeDiscount.usageLimit!;

      if (activeDiscount.isActive &&
          isDateValid &&
          isLimitOk &&
          subtotal >= activeDiscount.minAmount) {
        globalDiscount = activeDiscount.type == 'percentage'
            ? subtotal * (activeDiscount.value / 100)
            : activeDiscount.value;
      } else {
        globalDiscount = 0;
      }
    } else {
      // Si pas de remise active, on garde la remise actuelle ou on remet à 0 si demandé
      globalDiscount = (discountOverride != null || clearDiscount)
          ? 0
          : state.globalDiscount;
    }

    // --- NOUVEAU : Calcul des points de fidélité ---
    final double finalTotal =
        (currentItems.fold<double>(0, (s, i) => s + i.lineTotalTtc) -
                globalDiscount)
            .clamp(0, double.infinity);

    double calculatedLoyalty = 0;
    if (currentCustomerId != null) {
      // Utilisation d'un cache pour éviter les lectures DB à chaque micro-changement du panier
      _cachedSettings ??= await _db.getAllSettings();

      if (_cachedSettings!['loyalty_enabled'] == '1') {
        final rate =
            double.tryParse(
              _cachedSettings!['loyalty_points_rate'] ?? '0.01',
            ) ??
            0.01;
        calculatedLoyalty = finalTotal * rate;
      }
    }

    return CartState(
      items: currentItems,
      globalDiscount: globalDiscount,
      customerId: currentCustomerId,
      customerName: state.customerName,
      note: state.note,
      couponCode: couponCode,
      appliedDiscount: activeDiscount,
      loyaltyPointsEarned: calculatedLoyalty,
      parkedSales: state.parkedSales,
      error: currentError,
    );
  }

  List<CartItem> _updateItemQuantity(Product product, int delta) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.productId == product.id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + delta);
    } else {
      items.add(CartItem(product: product, quantity: delta));
    }
    return items;
  }
}
