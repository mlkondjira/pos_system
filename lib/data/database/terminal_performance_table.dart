import 'package:flutter/material.dart';
import '../../../data/database/pos_database.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';

class TerminalPerformanceTable extends StatelessWidget {
  final PosDatabase db;
  final String shopId;
  final DateTimeRange dateRange;

  const TerminalPerformanceTable({
    super.key,
    required this.db,
    required this.shopId,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.salesDao.getSalesStatsByTerminal(
        from: dateRange.start,
        to: dateRange.end,
        shopId: shopId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }

        final stats = snapshot.data ?? [];

        if (stats.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Aucune donnée de vente pour cette période.'),
            ),
          );
        }

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.05),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'Terminal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Ventes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Panier Moyen',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: true,
                ),
              ],
              rows: stats.map((stat) {
                final id = stat['terminalId'] as String;
                final shortId = id.length > 8 ? id.substring(0, 8) : id;

                return DataRow(
                  cells: [
                    DataCell(Text('Appareil #$shortId')),
                    DataCell(Text(stat['saleCount'].toString())),
                    DataCell(
                      Text(
                        Fmt.currency(
                          (stat['averageBasket'] as num?)?.toDouble() ?? 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
