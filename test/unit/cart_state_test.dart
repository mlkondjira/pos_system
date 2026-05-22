// test/unit/cart_state_test.dart
// ============================================================
//  Tests unitaires — CartItem & CartState
//  Couvre : calculs TTC/HT/taxes, remises, globalDiscount
//  NOTE : Ces tests couvrent la logique PURE de CartItem et
//  CartState sans dépendance à la BDD ni au BLoC complet.
// ============================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/presentation/blocs/cart_bloc.dart';
import 'test_helpers.dart';

void main() {
  // ══════════════════════════════════════════════════════════
  //  CartItem — calculs de prix
  // ══════════════════════════════════════════════════════════

  group('CartItem.priceTtc', () {
    test('calcule correctement le TTC avec TVA 18%', () {
      // HT = 1000 FCFA, TVA 18% → TTC = 1180 FCFA
      final item = makeCartItem(priceHt: 1000, taxRate: 0.18);
      expect(round2(item.priceTtc), 1180.0);
    });

    test('calcule correctement avec TVA 0%', () {
      final item = makeCartItem(priceHt: 500, taxRate: 0.0);
      expect(item.priceTtc, 500.0);
    });

    test('calcule correctement avec TVA 20%', () {
      final item = makeCartItem(priceHt: 1000, taxRate: 0.20);
      expect(item.priceTtc, 1200.0);
    });
  });

  group('CartItem.lineTotalTtc', () {
    test('sans remise : qty * priceTtc', () {
      // 3 × 1180 = 3540
      final item = makeCartItem(priceHt: 1000, taxRate: 0.18, quantity: 3);
      expect(round2(item.lineTotalTtc), 3540.0);
    });

    test('avec remise manuelle en % : applique correctement', () {
      // TTC = 1180, qty = 2, remise 10%
      // Total brut = 2360, après remise = 2360 * 0.9 = 2124
      final item = makeCartItem(
        priceHt: 1000,
        taxRate: 0.18,
        quantity: 2,
        discountPct: 10,
      );
      expect(round2(item.lineTotalTtc), 2124.0);
    });

    test('avec remise auto en % : applique correctement', () {
      final item = makeCartItem(
        priceHt: 1000,
        taxRate: 0.18,
        quantity: 2,
        autoDiscountPct: 10,
      );
      expect(round2(item.lineTotalTtc), 2124.0);
    });

    test('prend le MAX entre remise manuelle et auto', () {
      // discountPct=10, autoDiscountPct=25 → utilise 25%
      final item = makeCartItem(
        priceHt: 1000,
        taxRate: 0.18,
        quantity: 2,
        discountPct: 10,
        autoDiscountPct: 25,
      );
      final expected = 2360.0 * 0.75; // 25% de remise
      expect(round2(item.lineTotalTtc), round2(expected));
    });

    test('remise manuelle > auto : utilise la manuelle', () {
      final item = makeCartItem(
        priceHt: 1000,
        taxRate: 0.18,
        quantity: 1,
        discountPct: 30,
        autoDiscountPct: 10,
      );
      final expected = 1180.0 * 0.70; // 30% de remise
      expect(round2(item.lineTotalTtc), round2(expected));
    });

    test('avec remise montant fixe : soustrait correctement', () {
      // TTC = 1180, remise fixe 100 FCFA → 1080
      final item = makeCartItem(
        priceHt: 1000,
        taxRate: 0.18,
        quantity: 1,
        discountAmount: 100,
      );
      expect(round2(item.lineTotalTtc), 1080.0);
    });

    test('remise fixe > total → clamp à 0 (jamais négatif)', () {
      final item = makeCartItem(
        priceHt: 1000,
        taxRate: 0.18,
        quantity: 1,
        discountAmount: 5000, // Remise > prix
      );
      expect(item.lineTotalTtc, 0.0);
    });

    test('combinaison % + montant fixe', () {
      // TTC = 1180, 10% → 1062, puis -50 → 1012
      final item = makeCartItem(
        priceHt: 1000,
        taxRate: 0.18,
        quantity: 1,
        discountPct: 10,
        discountAmount: 50,
      );
      expect(round2(item.lineTotalTtc), round2(1180 * 0.9 - 50));
    });
  });

  // ══════════════════════════════════════════════════════════
  //  CartState — agrégations
  // ══════════════════════════════════════════════════════════

  group('CartState.subtotalTtc', () {
    test('somme correcte de plusieurs articles', () {
      // Produit A : 2 × 1180 = 2360
      // Produit B : 1 × 590  = 590
      // Total = 2950
      final state = CartState(
        items: [
          makeCartItem(productId: 1, priceHt: 1000, taxRate: 0.18, quantity: 2),
          makeCartItem(productId: 2, priceHt: 500, taxRate: 0.18, quantity: 1),
        ],
      );
      expect(round2(state.subtotalTtc), 2950.0);
    });

    test('panier vide → subtotal 0', () {
      expect(const CartState().subtotalTtc, 0.0);
    });
  });

  group('CartState.totalTtc (avec globalDiscount)', () {
    test('soustrait la remise globale du sous-total', () {
      // Sous-total = 2360, remise globale = 200 → total = 2160
      final state = CartState(
        items: [makeCartItem(priceHt: 1000, taxRate: 0.18, quantity: 2)],
        globalDiscount: 200,
      );
      expect(round2(state.totalTtc), 2160.0);
    });

    test('remise globale > sous-total → clamp à 0', () {
      final state = CartState(
        items: [makeCartItem(priceHt: 100, quantity: 1)],
        globalDiscount: 999,
      );
      expect(state.totalTtc, 0.0);
    });

    test('remise globale 0 → total = sous-total', () {
      final state = CartState(
        items: [makeCartItem(priceHt: 1000, taxRate: 0.18, quantity: 1)],
      );
      expect(round2(state.totalTtc), round2(state.subtotalTtc));
    });
  });

  group('CartState.totalHt et totalTax', () {
    test('HT + Tax = TTC (cohérence comptable)', () {
      final state = CartState(
        items: [
          makeCartItem(priceHt: 1000, taxRate: 0.18, quantity: 2),
          makeCartItem(productId: 2, priceHt: 500, taxRate: 0.18, quantity: 3),
        ],
      );
      // HT + Tax doit être égal au totalTtc (à 1 centime près)
      expect(nearEqual(state.totalHt + state.totalTax, state.totalTtc), isTrue);
    });

    test('taux 0% → totalTax = 0 et totalHt = totalTtc', () {
      final state = CartState(
        items: [makeCartItem(priceHt: 1000, taxRate: 0.0, quantity: 1)],
      );
      expect(round2(state.totalTax), 0.0);
      expect(round2(state.totalHt), round2(state.totalTtc));
    });

    test('HT + Tax = TTC avec remise globale', () {
      // Avec globalDiscount, le prorata doit être appliqué
      final state = CartState(
        items: [makeCartItem(priceHt: 1000, taxRate: 0.18, quantity: 2)],
        globalDiscount: 300,
      );
      expect(nearEqual(state.totalHt + state.totalTax, state.totalTtc), isTrue);
    });

    test('articles multi-taux — HT + Tax = TTC', () {
      final state = CartState(
        items: [
          makeCartItem(productId: 1, priceHt: 1000, taxRate: 0.18, quantity: 1),
          makeCartItem(productId: 2, priceHt: 2000, taxRate: 0.20, quantity: 1),
          makeCartItem(productId: 3, priceHt: 500, taxRate: 0.0, quantity: 2),
        ],
      );
      expect(nearEqual(state.totalHt + state.totalTax, state.totalTtc), isTrue);
    });
  });

  group('CartState.itemCount', () {
    test('compte le total des quantités', () {
      final state = CartState(
        items: [
          makeCartItem(productId: 1, quantity: 3),
          makeCartItem(productId: 2, quantity: 2),
          makeCartItem(productId: 3, quantity: 1),
        ],
      );
      expect(state.itemCount, 6);
    });

    test('panier vide → itemCount = 0', () {
      expect(const CartState().itemCount, 0);
    });
  });

  group('CartState.isEmpty', () {
    test('vrai si pas d\'articles', () {
      expect(const CartState().isEmpty, isTrue);
    });

    test('faux si au moins un article', () {
      final state = CartState(items: [makeCartItem()]);
      expect(state.isEmpty, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════
  //  CartItem.copyWith
  // ══════════════════════════════════════════════════════════

  group('CartItem.copyWith', () {
    test('modifie uniquement la quantité', () {
      final item = makeCartItem(quantity: 1, discountPct: 10);
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.discountPct, 10); // Inchangé
    });

    test('modifie uniquement le discountPct', () {
      final item = makeCartItem(quantity: 3, discountPct: 0);
      final updated = item.copyWith(discountPct: 20);
      expect(updated.discountPct, 20);
      expect(updated.quantity, 3); // Inchangé
    });

    test('le produit est préservé dans copyWith', () {
      final item = makeCartItem(productId: 42, priceHt: 999);
      final updated = item.copyWith(quantity: 2);
      expect(updated.product.id, 42);
      expect(updated.product.priceHt, 999);
    });
  });

  // ══════════════════════════════════════════════════════════
  //  Scénarios de caisse réels (intégration logique)
  // ══════════════════════════════════════════════════════════

  group('Scénarios réels de caisse', () {
    test('Achat Wave : 3 produits, remise 10%, total correct', () {
      // Simulation : client paye par Wave
      // Produit A (huile) : 2 × 590 FCFA TTC = 1180
      // Produit B (riz)   : 5 × 472 FCFA TTC = 2360
      // Sous-total = 3540, remise globale 10% = 354
      // Total = 3186 FCFA
      final state = CartState(
        items: [
          makeCartItem(productId: 1, priceHt: 500, taxRate: 0.18, quantity: 2),
          makeCartItem(productId: 2, priceHt: 400, taxRate: 0.18, quantity: 5),
        ],
        globalDiscount: 354.0,
      );
      expect(round2(state.totalTtc), closeTo(3186.0, 1.0));
      expect(nearEqual(state.totalHt + state.totalTax, state.totalTtc), isTrue);
    });

    test('Vente à crédit : client avec remise ligne + remise globale', () {
      final state = CartState(
        items: [
          makeCartItem(
            priceHt: 2000,
            taxRate: 0.18,
            quantity: 1,
            discountPct: 5, // Remise ligne 5%
          ),
        ],
        globalDiscount: 100, // Remise globale fixe
      );
      // TTC = 2360, -5% = 2242, -100 = 2142
      expect(round2(state.totalTtc), closeTo(2142.0, 1.0));
    });

    test('Panier avec article à 0 FCFA après remise totale', () {
      final state = CartState(
        items: [
          makeCartItem(
            priceHt: 100,
            taxRate: 0.0,
            quantity: 1,
            discountPct: 100,
          ), // 100% de remise
        ],
      );
      expect(state.totalTtc, 0.0); //
      expect(state.totalHt, 0.0); //
    });
  });
}
