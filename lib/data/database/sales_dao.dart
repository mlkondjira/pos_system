// lib/data/database/daos/sales_dao.dart
import 'package:drift/drift.dart';
import 'pos_database.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [
  Sales,
  SaleItems,
  Payments,
  Products,
  StockMovements,
  Customers,
  CashSessions
])
class SalesDao extends DatabaseAccessor<PosDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  // ── VENTES ────────────────────────────────────────────────────

  Future<int> createSale({
    required int userId,
    required int cashSessionId,
    int? customerId,
    required List<SaleItemsCompanion> items,
    required String paymentMethod,
    required double amountPaid,
    String? note,
  }) async {
    return transaction(() async {
      double totalHt = 0, totalTtc = 0;
      for (final item in items) {
        final ht = item.unitPriceHt.value *
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

      final saleId = await into(sales).insert(SalesCompanion.insert(
        ref: ref,
        userId: userId,
        cashSessionId: Value(cashSessionId),
        customerId: Value(customerId),
        totalHt: totalHt,
        totalTax: totalTax,
        totalTtc: totalTtc,
        note: Value(note ?? ''),
      ));

      for (final item in items) {
        await into(saleItems).insert(item.copyWith(saleId: Value(saleId)));
        final prod = await (select(products)
              ..where((p) => p.id.equals(item.productId.value)))
            .getSingle();
        final newQty = prod.stockQty - item.quantity.value;
        await (update(products)
              ..where((p) => p.id.equals(item.productId.value)))
            .write(ProductsCompanion(
          stockQty: Value(newQty),
          updatedAt: Value(now),
        ));
        await into(stockMovements).insert(StockMovementsCompanion.insert(
          productId: item.productId.value,
          userId: Value(userId),
          type: 'sale',
          qtyDelta: -item.quantity.value,
          qtyAfter: newQty,
          reason: Value('Vente $ref'),
        ));
      }

      await into(payments).insert(PaymentsCompanion.insert(
        saleId: saleId,
        method: paymentMethod,
        amount: amountPaid,
        changeGiven:
            Value(amountPaid - totalTtc > 0 ? amountPaid - totalTtc : 0),
      ));

      if (customerId != null) {
        final pts = totalTtc * 0.01;
        await (update(customers)..where((c) => c.id.equals(customerId)))
            .write(CustomersCompanion(loyaltyPoints: Value(pts)));
      }

      return saleId;
    });
  }

  Future<List<Sale>> getSalesForPeriod(DateTime from, DateTime to) =>
      (select(sales)
            ..where((s) =>
                s.createdAt.isBetweenValues(from, to) &
                s.status.equals('completed'))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .get();

  Future<List<SaleItem>> getSaleItems(int saleId) =>
      (select(saleItems)..where((i) => i.saleId.equals(saleId))).get();

  Future<List<Payment>> getPaymentsForSession(int sessionId) {
    return (select(payments).join([
      innerJoin(sales, sales.id.equalsExp(payments.saleId))
    ])..where(sales.cashSessionId.equals(sessionId)))
    .map((row) => row.readTable(payments)).get();
  }

  /// Stream des ventes du jour (statut completed)
  Stream<List<Sale>> watchTodaySales() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(sales)
          ..where((s) =>
              s.createdAt.isBetweenValues(start, end) &
              s.status.equals('completed'))
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch();
  }

  /// Stream des ventes d'une session spécifique (pour le total temps réel)
  Stream<List<Sale>> watchSessionSales(int sessionId) {
    return (select(sales)
          ..where((s) => s.cashSessionId.equals(sessionId) & s.status.equals('completed')))
        .watch();
  }

  // ── RAPPORTS & STATS ──────────────────────────────────────────

  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final daySales = await getSalesForPeriod(start, end);
    final revenue = daySales.fold(0.0, (s, v) => s + v.totalTtc);
    final taxes = daySales.fold(0.0, (s, v) => s + v.totalTax);
    return {
      'sale_count': daySales.length,
      'revenue': revenue,
      'taxes': taxes,
      'avg_basket': daySales.isEmpty ? 0.0 : revenue / daySales.length,
    };
  }

  Future<List<Map<String, dynamic>>> getTopProducts({int days = 30}) async {
    // Cette méthode nécessite une requête personnalisée qui est mieux gérée
    // dans le fichier de base de données principal. Pour l'instant, nous la
    // laissons ici.
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await customSelect('''
      SELECT p.name, p.barcode, p.unit,
             SUM(si.quantity)   AS total_qty,
             SUM(si.line_total) AS total_revenue
      FROM sale_items si
      JOIN products p ON p.id = si.product_id
      JOIN sales    s ON s.id = si.sale_id
      WHERE s.created_at >= ? AND s.status = 'completed'
      GROUP BY si.product_id
      ORDER BY total_qty DESC
      LIMIT 10
    ''', variables: [Variable.withDateTime(since)]).get();

    return rows.map((r) => {
      'name': r.read<String>('name'),
      'barcode': r.readNullable<String>('barcode'),
      'unit': r.read<String>('unit'),
      'total_qty': r.read<double>('total_qty').toInt(),
      'total_revenue': r.read<double>('total_revenue'),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getDailySalesChart({int days = 14}) async {
    // Cette méthode nécessite également une requête personnalisée.
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await customSelect('''
      SELECT date(created_at/1000, 'unixepoch', 'localtime') AS day,
             COUNT(*)                    AS count,
             COALESCE(SUM(total_ttc), 0) AS revenue
      FROM sales
      WHERE created_at >= ? AND status = 'completed'
      GROUP BY day ORDER BY day ASC
    ''', variables: [Variable.withDateTime(since)]).get();

    return rows.map((r) => {
      'day': r.read<String>('day'),
      'count': r.read<int>('count'),
      'revenue': r.read<double>('revenue'),
    }).toList();
  }

  // Petit utilitaire local pour le formatage des dates dans les refs
  String _p(int n) => n.toString().padLeft(2, '0');
}