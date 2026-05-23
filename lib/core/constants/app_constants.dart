// lib/core/constants/app_constants.dart
class AppConstants {
  // ── Rôles ──────────────────────────────────
  static const roleAdmin = 'admin';
  static const roleManager = 'manager';
  static const roleCashier = 'cashier';

  // ── Statuts vente ─────────────────────────
  static const saleCompleted = 'completed';
  static const saleCancelled = 'cancelled';
  static const saleRefunded = 'refunded';
  static const saleHold = 'hold';

  // ── Modes de paiement ────────────────────
  static const paymentCash = 'cash';
  static const paymentCard = 'card';
  static const paymentMobileMoney = 'mobile_money';
  static const paymentCredit = 'credit';

  // ── Types mouvement stock ─────────────────
  static const moveSale = 'sale';
  static const movePurchase = 'purchase';
  static const moveAdjustment = 'adjustment';
  static const moveReturn = 'return';
  static const moveWaste = 'waste';
  static const moveInventory = 'inventory';

  // ── Statuts inventaire ────────────────────
  static const inventoryPending = 'pending';
  static const inventoryInProgress = 'in_progress';
  static const inventoryCompleted = 'completed';
  static const inventoryCancelled = 'cancelled';

  // ── Devise par défaut ─────────────────────
  static const defaultCurrency = 'FCFA';
  static const defaultCurrencySymbol = 'F';

  // ── Index navigation ──────────────────────
  static const navCaisse = 0;
  static const navProduits = 1;
  static const navInventaire = 2;
  static const navVentes = 3;
  static const navClients = 4;
  static const navSettings = 5;
}
