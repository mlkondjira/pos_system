// lib/data/database/daos/sales_dao.dart
import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'pos_database.dart';

part 'sales_dao.g.dart';

class DebtorSummary {
  final Customer customer;
  final double totalDebt;

  DebtorSummary({required this.customer, required this.totalDebt});
}

@DriftAccessor(
  tables: [
    Sales,
    SaleItems,
    Payments,
    Products,
    StockMovements,
    Customers,
    CashSessions,
  ],
)
class SalesDao extends DatabaseAccessor<PosDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  // ── VENTES ────────────────────────────────────────────────────

  Future<int> createSale({
    required int userId,
    required int cashSessionId,
    String? customerId, // MODIFIED: customerId est maintenant un UUID (String)
    required String shopId, // NOUVEAU : ID du magasin
    required String terminalId, // NOUVEAU : ID de l'appareil
    required List<SaleItemsCompanion> items,
    required String paymentMethod,
    required double amountPaid,
    String? note,
    String? couponCode,
    // NOUVEAU : Pour les ventes à crédit
    double? amountDue,
    String? paymentStatus,
  }) async {
    return transaction(() async {
      double totalHt = 0, totalTtc = 0;
      for (final item in items) {
        final ht =
            item.unitPriceHt.value *
            item.quantity.value *
            (1 - item.discountPct.value / 100);
        totalHt += ht;
        totalTtc += item.lineTotal.value;
      }
      final totalTax = totalTtc - totalHt;
      final now = DateTime.now();
      final ref =
          'VTE-${now.year}${_p(now.month)}${_p(now.day)}'
          '-${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';

      // --- CHAÎNAGE FISCAL ---
      // 1. Récupérer le hash de la vente précédente pour ce terminal
      final lastSale =
          await (select(sales)
                ..where(
                  (s) =>
                      s.terminalId.equals(terminalId) & s.shopId.equals(shopId),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.id)])
                ..limit(1))
              .getSingleOrNull();

      final String prevHash =
          lastSale?.fiscalHash ?? '00000000000000000000000000000000';

      // 2. Concaténer les données critiques pour créer la signature
      // Format strict : Ref|ISO_Date|Total|Shop|Terminal|PrevHash
      final String fiscalPayload =
          '$ref|${now.toIso8601String()}|${totalTtc.toStringAsFixed(2)}|$shopId|$terminalId|$prevHash';
      final String currentHash = sha256
          .convert(utf8.encode(fiscalPayload))
          .toString();

      // Calcul précis du reste à payer pour éviter les erreurs de flottants
      final double restToPay = (totalTtc - amountPaid).clamp(
        0.0,
        double.infinity,
      );
      final calculatedAmountDue = amountDue ?? restToPay;
      final finalPaymentStatus =
          paymentStatus ?? (calculatedAmountDue <= 0.01 ? 'paid' : 'due');

      final saleId = await into(sales).insert(
        SalesCompanion(
          ref: Value(ref),
          userId: Value(userId),
          cashSessionId: Value(cashSessionId),
          customerId: Value(customerId),
          terminalId: Value(terminalId),
          totalHt: Value(totalHt),
          shopId: Value(shopId),
          totalTax: Value(totalTax),
          totalTtc: Value(totalTtc),
          amountDue: Value(calculatedAmountDue),
          paymentStatus: Value(finalPaymentStatus),
          couponCode: Value(couponCode),
          fiscalHash: Value(currentHash),
          previousFiscalHash: Value(prevHash),
        ),
      );

      // SYNCHRO : Enfiler la vente
      final saleData = await (select(
        sales,
      )..where((s) => s.id.equals(saleId))).getSingle();
      await db.enqueue(
        entityType: 'sale',
        entityId: saleId,
        payload: saleData.toJson(),
        shopId: shopId,
      );

      for (final item in items) {
        final prod = await (select(
          products,
        )..where((p) => p.id.equals(item.productId.value))).getSingle();

        // Capture du coût au moment de la vente pour le calcul de marge
        final saleItemId = await into(saleItems).insert(
          item.copyWith(
            saleId: Value(saleId),
            costPriceAtSale: Value(prod.costPrice ?? 0.0),
          ),
        );

        // SYNCHRO : Enfiler l'article de vente
        final itemData = await (select(
          saleItems,
        )..where((i) => i.id.equals(saleItemId))).getSingle();
        await db.enqueue(
          entityType: 'sale_item',
          entityId: saleItemId,
          payload: itemData.toJson(),
          shopId: shopId,
        );

        // SYNCHRO : Utiliser la méthode centralisée pour le stock (gère le stock_delta)
        final qtyDelta = -item.quantity.value;
        await db.updateStock(item.productId.value, qtyDelta);
        final newQty = prod.stockQty + qtyDelta;

        final movementId = await into(stockMovements).insert(
          StockMovementsCompanion(
            productId: Value(item.productId.value),
            shopId: Value(shopId),
            userId: Value(userId),
            type: const Value('sale'),
            qtyDelta: Value(qtyDelta),
            qtyAfter: Value(newQty),
            reason: Value('Vente $ref'),
          ),
        );

        // SYNCHRO : Enfiler le mouvement de stock
        final movementData = await (select(
          stockMovements,
        )..where((m) => m.id.equals(movementId))).getSingle();
        await db.enqueue(
          entityType: 'stock_movement',
          entityId: movementId,
          payload: movementData.toJson(),
          shopId: shopId,
        );
      }

      final paymentId = await into(payments).insert(
        PaymentsCompanion.insert(
          saleId: saleId,
          method: paymentMethod,
          amount: amountPaid,
          terminalId: Value(terminalId),
          changeGiven: Value(
            amountPaid - totalTtc > 0 ? amountPaid - totalTtc : 0,
          ),
        ),
      );

      // SYNCHRO : Enfiler le paiement
      final paymentData = await (select(
        payments,
      )..where((p) => p.id.equals(paymentId))).getSingle();
      await db.enqueue(
        entityType: 'payment',
        entityId: paymentId,
        payload: paymentData.toJson(),
        shopId: shopId,
      );

      if (customerId != null) {
        final pts = totalTtc * 0.01; // Calcul des points de fidélité
        final currentCustomer = await (select(
          customers,
        )..where((c) => c.remoteId.equals(customerId))).getSingleOrNull();
        if (currentCustomer != null) {
          await (update(
            customers,
          )..where((c) => c.remoteId.equals(customerId))).write(
            CustomersCompanion(
              loyaltyPoints: Value(currentCustomer.loyaltyPoints + pts),
            ),
          );

          // SYNCHRO : Enfiler la mise à jour du client (points de fidélité)
          final updatedCustomer = await (select(
            customers,
          )..where((c) => c.remoteId.equals(customerId))).getSingle();
          await db.enqueue(
            entityType: 'customer',
            entityId: updatedCustomer.id,
            payload: updatedCustomer.toJson(),
            shopId: shopId,
          );
        }
      }

      return saleId;
    });
  }

  /// Récupère toutes les ventes ayant un solde impayé, groupées par client.
  Stream<List<Sale>> watchUnpaidSales({String? customerId}) {
    final query = select(sales)
      ..where(
        (s) =>
            s.paymentStatus.equals('paid').not() & s.status.equals('completed'),
      );
    if (customerId != null) {
      query.where((s) => s.customerId.equals(customerId));
    }
    return (query..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).watch();
  }

  /// Récupère la liste des clients ayant des dettes avec le montant total dû.
  Stream<List<DebtorSummary>> watchDebtorsSummary() {
    final debt = sales.amountDue.sum();

    final query =
        select(customers).join([
            innerJoin(sales, sales.customerId.equalsExp(customers.remoteId)),
          ])
          ..where(
            sales.paymentStatus.equals('paid').not() &
                sales.status.equals('completed'),
          )
          ..addColumns([debt])
          ..groupBy([customers.id]);

    return query.watch().map(
      (rows) => rows.map((row) {
        return DebtorSummary(
          customer: row.readTable(customers),
          totalDebt: row.read(debt) ?? 0.0,
        );
      }).toList(),
    );
  }

  /// Récupère TOUS les clients avec leur solde de dette actuel (0 si aucune dette).
  Stream<List<DebtorSummary>> watchAllCustomersWithDebt() {
    final debt = sales.amountDue.sum();

    final query =
        select(customers).join([
            leftOuterJoin(
              sales, // Ligne 235
              sales.customerId.equalsExp(customers.remoteId) &
                  sales.paymentStatus.equals('paid').not() &
                  sales.status.equals('completed'),
            ),
          ])
          ..addColumns([debt])
          ..groupBy([customers.id])
          ..orderBy([OrderingTerm.asc(customers.name)]);

    return query.watch().map(
      (rows) => rows.map((row) {
        return DebtorSummary(
          customer: row.readTable(customers),
          totalDebt: row.read(debt) ?? 0.0,
        );
      }).toList(),
    );
  }

  Future<List<Sale>> getSalesForPeriod(
    DateTime from,
    DateTime to,
    String shopId, {
    String? terminalId,
  }) {
    final query = select(sales)
      ..where((s) {
        final basicFilter =
            s.createdAt.isBetweenValues(from, to) &
            (s.status.equals('completed') | s.status.equals('refunded')) &
            s.shopId.equals(shopId);

        if (terminalId != null) {
          return basicFilter & s.terminalId.equals(terminalId);
        }
        return basicFilter;
      });

    return (query..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).get();
  }

  /// Calcule le chiffre d'affaires total TTC pour un terminal spécifique sur une période donnée.
  Future<double> getTotalRevenueForTerminal({
    required DateTime from,
    required DateTime to,
    required String shopId,
    required String terminalId,
  }) async {
    final sumColumn = sales.totalTtc.sum();
    final query = selectOnly(sales)
      ..addColumns([sumColumn])
      ..where(
        sales.createdAt.isBetweenValues(from, to) &
            sales.status.equals('completed') &
            sales.shopId.equals(shopId) &
            sales.terminalId.equals(terminalId),
      );

    final result = await query.map((row) => row.read(sumColumn)).getSingle();
    return result ?? 0.0;
  }

  /// Rapport comparatif du chiffre d'affaires par terminal pour un magasin donné.
  Future<List<Map<String, dynamic>>> getRevenueComparisonByTerminal({
    required DateTime from,
    required DateTime to,
    required String shopId,
  }) async {
    final revenue = sales.totalTtc.sum();
    final terminal = sales.terminalId;

    final query = selectOnly(sales)
      ..addColumns([terminal, revenue])
      ..where(
        sales.createdAt.isBetweenValues(from, to) &
            sales.status.equals('completed') &
            sales.shopId.equals(shopId),
      )
      ..groupBy([terminal]);

    final result = await query.get();

    return result
        .map(
          (row) => {
            'terminalId': row.read(terminal) ?? 'Inconnu',
            'revenue': row.read(revenue) ?? 0.0,
          },
        )
        .toList();
  }

  /// Surveille en temps réel les statistiques de vente par terminal (Caisse).
  Stream<List<Map<String, dynamic>>> watchSalesStatsByTerminal({
    required DateTime from,
    required DateTime to,
    required String shopId,
  }) {
    final query = select(sales)
      ..where(
        (s) =>
            s.createdAt.isBetweenValues(from, to) &
            s.status.equals('completed') &
            s.shopId.equals(shopId),
      );

    return query.watch().map((salesList) {
      final Map<String, Map<String, dynamic>> stats = {};
      for (final s in salesList) {
        final tid = s.terminalId ?? 'Inconnu';
        if (!stats.containsKey(tid)) {
          stats[tid] = {'terminalId': tid, 'saleCount': 0, 'totalRevenue': 0.0};
        }
        stats[tid]!['saleCount'] = (stats[tid]!['saleCount'] as int) + 1;
        stats[tid]!['totalRevenue'] =
            (stats[tid]!['totalRevenue'] as double) + s.totalTtc;
      }
      return stats.values.toList();
    });
  }

  /// Calcule les statistiques complètes (Nombre, CA, Panier Moyen) par terminal.
  Future<List<Map<String, dynamic>>> getSalesStatsByTerminal({
    required DateTime from,
    required DateTime to,
    required String shopId,
  }) async {
    final saleCount = sales.id.count();
    final totalRevenue = sales.totalTtc.sum();
    final averageBasket = sales.totalTtc.avg();
    final terminal = sales.terminalId;

    final query = selectOnly(sales)
      ..addColumns([terminal, saleCount, totalRevenue, averageBasket])
      ..where(
        sales.createdAt.isBetweenValues(from, to) &
            sales.status.equals('completed') &
            sales.shopId.equals(shopId),
      )
      ..groupBy([terminal]);

    final result = await query.get();

    return result
        .map(
          (row) => {
            'terminalId': row.read(terminal) ?? 'Inconnu',
            'saleCount': row.read(saleCount) ?? 0,
            'totalRevenue': row.read(totalRevenue) ?? 0.0,
            'averageBasket': row.read(averageBasket) ?? 0.0,
          },
        )
        .toList();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) =>
      (select(saleItems)..where((i) => i.saleId.equals(saleId))).get();

  Future<List<Payment>> getPaymentsForSale(int saleId) =>
      (select(payments)..where((p) => p.saleId.equals(saleId))).get();

  /// Vérifie l'intégrité de la chaîne fiscale pour toutes les ventes.
  /// [limit] permet de ne vérifier que les N dernières ventes pour la performance.
  Future<bool> verifyFiscalIntegrity({int? limit}) async {
    String expectedPreviousHash = '00000000000000000000000000000000';
    List<Sale> verifyList;

    if (limit != null) {
      // On récupère limit + 1 ventes pour avoir le hash de la vente juste avant le segment
      final recentSales =
          await (select(sales)
                ..orderBy([(s) => OrderingTerm.desc(s.id)])
                ..limit(limit + 1))
              .get();

      if (recentSales.isEmpty) return true;

      // On remet dans l'ordre chronologique
      final chronoSorted = recentSales.reversed.toList();

      if (chronoSorted.length > limit) {
        // La première vente sert de point de référence (pivot)
        // Le lien avec le passé est considéré valide si cette vente possède un hash
        expectedPreviousHash =
            chronoSorted.first.fiscalHash ?? expectedPreviousHash;
        verifyList = chronoSorted.sublist(1);
      } else {
        // On a moins de ventes que la limite, on vérifie tout
        verifyList = chronoSorted;
      }
    } else {
      verifyList = await (select(
        sales,
      )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
    }

    for (final sale in verifyList) {
      // 1. Vérifier le lien avec la vente précédente
      if (sale.previousFiscalHash != expectedPreviousHash) {
        return false;
      }

      // 2. Vérifier que le hash de la ligne actuelle est mathématiquement correct
      final payload =
          '${sale.ref}|${sale.createdAt.toIso8601String()}|${sale.totalTtc.toStringAsFixed(2)}|${sale.shopId}|${sale.terminalId}|${sale.previousFiscalHash}';
      final calculatedHash = sha256.convert(utf8.encode(payload)).toString();

      if (sale.fiscalHash != calculatedHash) {
        return false;
      }

      // Le hash actuel devient le "previous" attendu pour la ligne suivante
      expectedPreviousHash =
          sale.fiscalHash ?? '00000000000000000000000000000000';
    }

    return true;
  }

  Future<List<Payment>> getPaymentsForSession(
    int sessionId, {
    String? terminalId,
  }) {
    final query = select(
      payments,
    ).join([innerJoin(sales, sales.id.equalsExp(payments.saleId))]);

    query.where(sales.cashSessionId.equals(sessionId));
    if (terminalId != null) {
      query.where(payments.terminalId.equals(terminalId));
    }

    return query.map((row) => row.readTable(payments)).get();
  }

  /// Stream des ventes du jour (statut completed)
  Stream<List<Sale>> watchTodaySales({String? terminalId}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final query = select(sales)
      ..where((s) {
        final basicFilter =
            s.createdAt.isBetweenValues(start, end) &
            (s.status.equals('completed') | s.status.equals('refunded'));

        if (terminalId != null) {
          return basicFilter & s.terminalId.equals(terminalId);
        }
        return basicFilter;
      });

    return (query..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).watch();
  }

  /// Stream des ventes d'une session spécifique (pour le total temps réel)
  Stream<List<Sale>> watchSessionSales(int sessionId) {
    return (select(sales)..where(
          (s) =>
              s.cashSessionId.equals(sessionId) &
              (s.status.equals('completed') | s.status.equals('refunded')),
        ))
        .watch();
  }

  // ── RAPPORTS & STATS ──────────────────────────────────────────

  Future<Map<String, dynamic>> getDailySummary(
    DateTime date,
    String shopId,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final daySales = await getSalesForPeriod(start, end, shopId);
    final revenue = daySales.fold(
      0.0,
      (s, v) => s + v.totalTtc - v.refundedAmount,
    );
    final taxes = daySales.fold(0.0, (s, v) => s + v.totalTax);
    return {
      'sale_count': daySales.length,
      'revenue': revenue,
      'taxes': taxes,
      'avg_basket': daySales.isEmpty ? 0.0 : revenue / daySales.length,
    };
  }

  Future<List<Map<String, dynamic>>> getTopProducts({
    int days = 30,
    required String shopId,
  }) async {
    // Cette méthode nécessite une requête personnalisée qui est mieux gérée
    // dans le fichier de base de données principal. Pour l'instant, nous la
    // laissons ici.
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await customSelect(
      '''
      SELECT p.name, p.barcode, p.unit,
             SUM(si.quantity)   AS total_qty,
             SUM(si.line_total) AS total_revenue
      FROM sale_items si
      JOIN products p ON p.id = si.product_id
      JOIN sales    s ON s.id = si.sale_id
      WHERE s.created_at >= ? AND s.status = 'completed' AND s.shop_id = ?
      GROUP BY si.product_id
      ORDER BY total_qty DESC
      LIMIT 10
    ''',
      variables: [Variable.withDateTime(since), Variable.withString(shopId)],
    ).get();

    return rows
        .map(
          (r) => {
            'name': r.read<String>('name'),
            'barcode': r.readNullable<String>('barcode'),
            'unit': r.read<String>('unit'),
            'total_qty': r.read<double>('total_qty').toInt(),
            'total_revenue': r.read<double>('total_revenue'),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getDailySalesChart({
    int days = 14,
    required String shopId,
  }) async {
    // Cette méthode nécessite également une requête personnalisée.
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await customSelect(
      '''
      SELECT date(created_at/1000, 'unixepoch', 'localtime') AS day,
             COUNT(*)                    AS count,
             COALESCE(SUM(total_ttc), 0) AS revenue
      FROM sales
      WHERE created_at >= ? AND status = 'completed' AND (shop_id = ? OR ? = '')
      GROUP BY day ORDER BY day ASC
    ''',
      variables: [
        Variable.withDateTime(since),
        Variable.withString(shopId),
        Variable.withString(shopId),
      ],
    ).get();

    return rows
        .map(
          (r) => {
            'day': r.read<String>('day'),
            'count': r.read<int>('count'),
            'revenue': r.read<double>('revenue'),
          },
        )
        .toList();
  }

  /// Récupère la performance (CA) par magasin pour une période donnée.
  Future<List<Map<String, dynamic>>> getShopPerformance({
    required DateTime from,
    required DateTime to,
  }) async {
    final revenue = sales.totalTtc.sum();
    final shopName = db.shops.name;

    final query =
        selectOnly(
            sales,
          ).join([innerJoin(db.shops, db.shops.id.equalsExp(sales.shopId))])
          ..addColumns([shopName, revenue])
          ..where(
            sales.createdAt.isBetweenValues(from, to) &
                sales.status.equals('completed'),
          )
          ..groupBy([shopName]);

    final result = await query.get();

    return result
        .map(
          (row) => {
            'name': row.read(shopName) ?? 'Inconnu',
            'revenue': row.read(revenue) ?? 0.0,
          },
        )
        .toList();
  }

  // Petit utilitaire local pour le formatage des dates dans les refs
  String _p(int n) => n.toString().padLeft(2, '0');
}
