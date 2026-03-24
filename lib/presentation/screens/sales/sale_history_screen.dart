import 'package:drift/drift.dart' hide Column;
import '../../widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utils.dart';
import '../../../core/di/injection.dart';

import '../../../data/database/pos_database.dart';

class SaleHistoryScreen extends StatefulWidget {
  const SaleHistoryScreen({super.key});
  @override
  State<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends State<SaleHistoryScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final db = getIt<PosDatabase>();
    return Column(
      children: [
        _dateRangeHeader(context),
        Expanded(
          child: StreamBuilder<List<Sale>>(
            stream: _watchSales(db),
            builder: (ctx, snap) {
              final sales = snap.data ?? [];
              if (sales.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Aucune vente sur cette période',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: sales.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) => _SaleCard(
                  sale: sales[i],
                  db: db,
                  onRefund: () => _confirmRefund(ctx, sales[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<List<Sale>> _watchSales(PosDatabase db) {
    final start = DateTime(_from.year, _from.month, _from.day);
    final end = DateTime(_to.year, _to.month, _to.day)
        .add(const Duration(days: 1));
    return (db.select(db.sales)
          ..where((s) =>
              s.createdAt.isBiggerOrEqualValue(start) &
              s.createdAt.isSmallerThanValue(end))
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch();
  }

  Widget _dateRangeHeader(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: _dateChip(
              'Du',
              _from,
              () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: _from,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (_, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primaryLight,
                        surface: AppColors.card,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _from = d);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('→',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            child: _dateChip(
              'Au',
              _to,
              () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: _to,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (_, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primaryLight,
                        surface: AppColors.card,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _to = d);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label : ${DateUtils2.formatDate(date)}',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12),
            ),
            const Icon(Icons.calendar_today,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _confirmRefund(BuildContext ctx, Sale sale) {
    if (sale.status != 'completed') return;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Remboursement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vente ${sale.ref}'),
            const SizedBox(height: 8),
            Text(
              CurrencyUtils.format(sale.totalTtc),
              style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Le stock sera restitué pour chaque article. Cette action est irréversible.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await _processRefund(ctx, sale);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Rembourser'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRefund(BuildContext ctx, Sale sale) async {
    final db = getIt<PosDatabase>();
    await db.transaction(() async {
      // Marquer la vente comme remboursée
      await (db.update(db.sales)..where((s) => s.id.equals(sale.id)))
          .write(const SalesCompanion(status: Value('refunded')));

      // Restituer le stock pour chaque ligne
      final items = await db.salesDao.getSaleItems(sale.id);
      for (final item in items) {
        final prod = await (db.select(db.products)
              ..where((p) => p.id.equals(item.productId)))
            .getSingle();
        final newQty = prod.stockQty + item.quantity;
        await db.updateStock(item.productId, newQty);
        await db.into(db.stockMovements).insert(
              StockMovementsCompanion(
                productId: Value(item.productId),
                userId: const Value(1),
                type: const Value('return'),
                qtyDelta: Value(item.quantity),
                qtyAfter: Value(newQty),
                reason: Value('Remboursement ${sale.ref}'),
              ),
            );
      }
    });
  }
}

class _SaleCard extends StatefulWidget {
  final Sale sale;
  final PosDatabase db;
  final VoidCallback onRefund;
  const _SaleCard(
      {required this.sale, required this.db, required this.onRefund});

  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _expanded = false;
  List<SaleItem> _items = [];

  Future<void> _loadItems() async {
    if (_items.isEmpty) {
      final items = await widget.db.salesDao.getSaleItems(widget.sale.id);
      setState(() => _items = items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final statusColor = switch (sale.status) {
      'completed' => AppColors.success,
      'refunded' => AppColors.warning,
      'cancelled' => AppColors.danger,
      _ => AppColors.textMuted,
    };
    final statusLabel = switch (sale.status) {
      'completed' => 'Encaissée',
      'refunded' => 'Remboursée',
      'cancelled' => 'Annulée',
      _ => sale.status,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // En-tête de la vente
          InkWell(
            onTap: () async {
              await _loadItems();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.ref,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateUtils2.formatDateTime(sale.createdAt),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyUtils.formatCompact(sale.totalTtc),
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                          label: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Détail des articles
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ..._items.map((item) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.productName}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                            ),
                            Text(
                              CurrencyUtils.formatCompact(
                                  item.lineTotal),
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                  if (sale.status == 'completed') ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                              Icons.print_outlined, size: 14),
                          label: const Text('Réimprimer'),
                          style: OutlinedButton.styleFrom(
                            textStyle:
                                const TextStyle(fontSize: 12),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.onRefund,
                          icon: const Icon(
                              Icons.replay_outlined, size: 14),
                          label: const Text('Rembourser'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: const BorderSide(
                                color: AppColors.warning),
                            textStyle:
                                const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
