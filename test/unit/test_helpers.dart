// test/unit/test_helpers.dart
// ============================================================
//  Factories de mocks partagées par tous les tests GPOS
//  Crée des objets Product, Discount et CartItem sans BDD
// ============================================================
import 'package:pos_system/data/database/pos_database.dart';
import 'package:pos_system/presentation/blocs/cart_bloc.dart';

// ── PRODUCT FACTORY ───────────────────────────────────────────

Product makeProduct({
  int id = 1,
  String name = 'Produit Test',
  double priceHt = 1000.0,
  double taxRate = 0.18, // 18% TVA — standard Sénégal
  int stockQty = 100,
  int? categoryId,
  DateTime? expiryDate,
  String? barcode,
}) {
  return Product(
    id: id,
    name: name,
    priceHt: priceHt,
    taxRate: taxRate,
    stockQty: stockQty,
    stockAlert: 5,
    categoryId: categoryId,
    expiryDate: expiryDate,
    barcode: barcode,
    isActive: true,
    unit: 'pce',
    costPrice: priceHt * 0.6,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    // Champs nullable optionnels
    description: null,
    imagePath: null,
    shopId: 'shop-test-001',
    preferredSupplierId: null,
  );
}

// ── CART ITEM FACTORY ─────────────────────────────────────────

CartItem makeCartItem({
  int productId = 1,
  String productName = 'Produit Test',
  double priceHt = 1000.0,
  double taxRate = 0.18,
  int quantity = 1,
  double discountPct = 0,
  double autoDiscountPct = 0,
  double discountAmount = 0,
  int? categoryId,
  DateTime? expiryDate,
}) {
  return CartItem(
    product: makeProduct(
      id: productId,
      name: productName,
      priceHt: priceHt,
      taxRate: taxRate,
      categoryId: categoryId,
      expiryDate: expiryDate,
    ),
    quantity: quantity,
    discountPct: discountPct,
    autoDiscountPct: autoDiscountPct,
    discountAmount: discountAmount,
  );
}

// ── DISCOUNT FACTORY ──────────────────────────────────────────

Discount makeDiscount({
  int id = 1,
  String name = 'Promo Test',
  String type = 'percentage',
  double value = 10.0,
  bool isActive = true,
  bool isArchived = false,
  bool isStackable = true,
  double minAmount = 0.0,
  DateTime? startDate,
  DateTime? endDate,
  int? usageLimit,
  int currentUsage = 0,
  String? rules,
  int priority = 0,
}) {
  return Discount(
    id: id,
    name: name,
    type: type,
    value: value,
    isActive: isActive,
    isArchived: isArchived,
    isStackable: isStackable,
    minAmount: minAmount,
    startDate: startDate,
    endDate: endDate,
    usageLimit: usageLimit,
    currentUsage: currentUsage,
    rules: rules,
    priority: priority,
    shopId: 'shop-test-001',
    limitPerCustomer: false,
  );
}

// ── HELPERS D'ASSERTION ───────────────────────────────────────

/// Arrondit à 2 décimales pour les comparaisons de prix
double round2(double v) => (v * 100).round() / 100;

/// Vérifie que deux montants sont égaux à 1 centime près
bool nearEqual(double a, double b, {double epsilon = 0.01}) {
  return (a - b).abs() < epsilon;
}
