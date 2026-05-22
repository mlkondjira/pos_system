// test/unit/promotion_engine_test.dart
// ============================================================
//  Tests unitaires — PromotionEngine
//  Couvre : BXGY, Happy Hour, Expiry Near, priorité, cumul
// ============================================================
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/services/promotion_engine.dart';
import 'test_helpers.dart';

void main() {
  group('PromotionEngine', () {
    // ── GARDE-FOUS ───────────────────────────────────────────

    group('Gardes (isActive / isArchived / dates)', () {
      test('ignore une promo inactive', () {
        final items = [makeCartItem(quantity: 3)];
        final discounts = [
          makeDiscount(isActive: false, type: 'percentage', value: 20),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });

      test('ignore une promo archivée', () {
        final items = [makeCartItem(quantity: 3)];
        final discounts = [
          makeDiscount(isArchived: true, type: 'percentage', value: 20),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });

      test('ignore une promo dont startDate est dans le futur', () {
        final items = [makeCartItem(quantity: 2)];
        final discounts = [
          makeDiscount(
            startDate: DateTime.now().add(const Duration(days: 1)),
            rules: jsonEncode({'type': 'bxgy', 'buy_qty': 2, 'get_qty': 1}),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });

      test('ignore une promo expirée (endDate dans le passé)', () {
        final items = [makeCartItem(quantity: 2)];
        final discounts = [
          makeDiscount(
            endDate: DateTime.now().subtract(const Duration(days: 1)),
            rules: jsonEncode({'type': 'bxgy', 'buy_qty': 2, 'get_qty': 1}),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });

      test('applique une promo dans la fenêtre de dates valide', () {
        final items = [makeCartItem(quantity: 3)];
        final discounts = [
          makeDiscount(
            startDate: DateTime.now().subtract(const Duration(days: 1)),
            endDate: DateTime.now().add(const Duration(days: 1)),
            rules: jsonEncode({'type': 'bxgy', 'buy_qty': 2, 'get_qty': 1}),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, greaterThan(0.0));
      });
    });

    // ── BUY X GET Y ──────────────────────────────────────────

    group('BXGY (Buy X Get Y)', () {
      test('2+1 gratuit : 3 articles → remise 33.3%', () {
        // Achète 2, obtient 1 gratuit → sur 3 articles, 1 est gratuit
        // % équivalent = 1/3 = 33.33%
        final items = [makeCartItem(quantity: 3, priceHt: 1000)];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({'type': 'bxgy', 'buy_qty': 2, 'get_qty': 1}),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(round2(result.first.autoDiscountPct), closeTo(33.33, 0.1));
      });

      test('2+1 gratuit : 2 articles → pas de remise (pas assez)', () {
        final items = [makeCartItem(quantity: 2)];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({'type': 'bxgy', 'buy_qty': 2, 'get_qty': 1}),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });

      test('2+1 gratuit : 6 articles → 2 sets → remise 33.3%', () {
        // 2 sets de (2+1) → 2 articles gratuits sur 6 = 33.33%
        final items = [makeCartItem(quantity: 6, priceHt: 500)];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({'type': 'bxgy', 'buy_qty': 2, 'get_qty': 1}),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(round2(result.first.autoDiscountPct), closeTo(33.33, 0.1));
      });

      test('BXGY ciblé : ne s\'applique qu\'au bon produit', () {
        final item1 = makeCartItem(productId: 1, quantity: 3);
        final item2 = makeCartItem(productId: 2, quantity: 3);
        final discounts = [
          makeDiscount(
            rules: jsonEncode({
              'type': 'bxgy',
              'buy_qty': 2,
              'get_qty': 1,
              'product_id': 1, // Seulement le produit 1
            }),
          ),
        ];
        final result = PromotionEngine.applyPromotions([
          item1,
          item2,
        ], discounts);
        expect(result[0].autoDiscountPct, greaterThan(0)); // produit 1 → remise
        expect(result[1].autoDiscountPct, 0.0); // produit 2 → pas de remise
      });

      test('BXGY sans product_id : s\'applique à tous les produits', () {
        final item1 = makeCartItem(productId: 1, quantity: 3);
        final item2 = makeCartItem(productId: 2, quantity: 3);
        final discounts = [
          makeDiscount(
            rules: jsonEncode({
              'type': 'bxgy',
              'buy_qty': 2,
              'get_qty': 1,
              // Pas de product_id → tous les produits
            }),
          ),
        ];
        final result = PromotionEngine.applyPromotions([
          item1,
          item2,
        ], discounts);
        expect(result[0].autoDiscountPct, greaterThan(0));
        expect(result[1].autoDiscountPct, greaterThan(0));
      });
    });

    // ── HAPPY HOUR ────────────────────────────────────────────

    group('Happy Hour', () {
      test('applique la remise si l\'heure actuelle est dans la fenêtre', () {
        // On utilise une fenêtre qui couvre les 24h pour être indépendant
        // de l'heure d'exécution du test
        final items = [makeCartItem(quantity: 1)];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({
              'type': 'happy_hour',
              'start_hour': 0, // Minuit
              'end_hour': 24, // Toute la journée
              'pct': 15.0,
            }),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 15.0);
      });

      test('n\'applique pas la remise hors fenêtre horaire', () {
        // Fenêtre passée : de 0h à 1h du matin (heure très tôt)
        // Si on exécute après 1h, la remise ne s'applique pas
        final items = [makeCartItem(quantity: 1)];
        // Créneau dans le passé lointain : 2h–3h
        // La remise ne doit pas s'appliquer si now.hour >= 3
        final discounts = [
          makeDiscount(
            rules: jsonEncode({
              'type': 'happy_hour',
              'start_hour': 25, // Heure invalide > 24 → jamais vrai
              'end_hour': 26,
              'pct': 25.0,
            }),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });

      test('Happy Hour avec filtre de catégorie — bon produit', () {
        final items = [makeCartItem(categoryId: 5, quantity: 1)];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({
              'type': 'happy_hour',
              'start_hour': 0,
              'end_hour': 24,
              'category_id': 5, // Même catégorie
              'pct': 20.0,
            }),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 20.0);
      });

      test('Happy Hour avec filtre de catégorie — mauvaise catégorie', () {
        final items = [
          makeCartItem(categoryId: 3, quantity: 1), // Catégorie 3 ≠ 5
        ];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({
              'type': 'happy_hour',
              'start_hour': 0,
              'end_hour': 24,
              'category_id': 5, // Catégorie différente
              'pct': 20.0,
            }),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });
    });

    // ── EXPIRY NEAR ───────────────────────────────────────────

    group('Expiry Near (produits proches expiration)', () {
      test('applique la remise si la date expire dans X jours', () {
        final items = [
          makeCartItem(
            expiryDate: DateTime.now().add(const Duration(days: 3)),
            quantity: 1,
          ),
        ];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({
              'type': 'expiry_near',
              'days': 7, // Seuil 7 jours
              'pct': 30.0,
            }),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 30.0);
      });

      test('n\'applique pas la remise si expiration lointaine', () {
        final items = [
          makeCartItem(
            expiryDate: DateTime.now().add(const Duration(days: 30)),
            quantity: 1,
          ),
        ];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({'type': 'expiry_near', 'days': 7, 'pct': 30.0}),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });

      test('n\'applique pas si le produit n\'a pas de date d\'expiration', () {
        final items = [makeCartItem(expiryDate: null, quantity: 1)];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({'type': 'expiry_near', 'days': 7, 'pct': 30.0}),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });

      test('n\'applique pas si produit déjà expiré', () {
        final items = [
          makeCartItem(
            expiryDate: DateTime.now().subtract(const Duration(days: 1)),
            quantity: 1,
          ),
        ];
        final discounts = [
          makeDiscount(
            rules: jsonEncode({'type': 'expiry_near', 'days': 7, 'pct': 30.0}),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 0.0);
      });
    });

    // ── PRIORITÉ ET CUMUL ─────────────────────────────────────

    group('Priorité et cumul des promotions', () {
      test('garde la remise la plus haute (max) entre deux promos', () {
        // Deux promos : 10% et 20% → doit prendre 20%
        final items = [makeCartItem(quantity: 1)];
        final discounts = [
          makeDiscount(
            id: 1,
            rules: jsonEncode({
              'type': 'happy_hour',
              'start_hour': 0,
              'end_hour': 24,
              'pct': 10.0,
            }),
            isStackable: true,
          ),
          makeDiscount(
            id: 2,
            rules: jsonEncode({
              'type': 'happy_hour',
              'start_hour': 0,
              'end_hour': 24,
              'pct': 20.0,
            }),
            isStackable: true,
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        expect(result.first.autoDiscountPct, 20.0);
      });

      test(
        'promo non-cumulable : s\'arrête après la première promo active',
        () {
          final items = [makeCartItem(quantity: 3)];
          final discounts = [
            // Priorité haute, non-cumulable
            makeDiscount(
              id: 1,
              priority: 10,
              isStackable: false,
              rules: jsonEncode({'type': 'bxgy', 'buy_qty': 2, 'get_qty': 1}),
            ),
            // Deuxième promo : ne doit PAS s'appliquer
            makeDiscount(
              id: 2,
              priority: 5,
              isStackable: false,
              rules: jsonEncode({
                'type': 'happy_hour',
                'start_hour': 0,
                'end_hour': 24,
                'pct': 50.0, // Très haute mais ne doit pas s'appliquer
              }),
            ),
          ];
          final result = PromotionEngine.applyPromotions(items, discounts);
          // La remise BXGY s'applique (33.33%) mais pas le happy hour (50%)
          // car isStackable = false → stop après la première
          expect(result.first.autoDiscountPct, closeTo(33.33, 0.1));
        },
      );

      test('trie par priorité descendante (haute priorité en premier)', () {
        final items = [makeCartItem(quantity: 3)];
        final discounts = [
          makeDiscount(
            id: 1,
            priority: 5,
            isStackable: false,
            rules: jsonEncode({
              'type': 'happy_hour',
              'start_hour': 0,
              'end_hour': 24,
              'pct': 15.0,
            }),
          ),
          makeDiscount(
            id: 2,
            priority: 10,
            isStackable: false,
            rules: jsonEncode({
              'type': 'happy_hour',
              'start_hour': 0,
              'end_hour': 24,
              'pct': 25.0,
            }),
          ),
        ];
        final result = PromotionEngine.applyPromotions(items, discounts);
        // Priorité 10 passe en premier → 25% appliqué, puis stop (non-cumulable)
        expect(result.first.autoDiscountPct, 25.0);
      });
    });

    // ── CAS LIMITES ───────────────────────────────────────────

    group('Cas limites', () {
      test('liste vide d\'articles → retourne liste vide', () {
        final result = PromotionEngine.applyPromotions([], [
          makeDiscount(
            rules: jsonEncode({
              'type': 'happy_hour',
              'start_hour': 0,
              'end_hour': 24,
              'pct': 10.0,
            }),
          ),
        ]);
        expect(result, isEmpty);
      });

      test('liste vide de promotions → articles inchangés', () {
        final items = [makeCartItem(quantity: 2, discountPct: 5)];
        final result = PromotionEngine.applyPromotions(items, []);
        expect(result.first.autoDiscountPct, 0.0);
        expect(result.first.discountPct, 5.0); // Remise manuelle préservée
      });

      test('règles JSON nulles → pas de crash', () {
        final items = [makeCartItem(quantity: 1)];
        final discounts = [makeDiscount(rules: null)];
        expect(
          () => PromotionEngine.applyPromotions(items, discounts),
          returnsNormally,
        );
      });
    });
  });
}
