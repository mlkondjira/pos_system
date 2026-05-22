import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../data/database/pos_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class TerminalRevenuePieChart extends StatefulWidget {
  final PosDatabase db;
  final String shopId;
  final DateTimeRange dateRange;

  const TerminalRevenuePieChart({
    super.key,
    required this.db,
    required this.shopId,
    required this.dateRange,
  });

  @override
  State<TerminalRevenuePieChart> createState() =>
      _TerminalRevenuePieChartState();
}

class _TerminalRevenuePieChartState extends State<TerminalRevenuePieChart> {
  // Liste de couleurs pour distinguer les terminaux
  static const List<Color> _chartColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.info,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  int _touchedIndex = -1; // Index de la section touchée

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.db.salesDao.getSalesStatsByTerminal(
        from: widget.dateRange.start,
        to: widget.dateRange.end,
        shopId: widget.shopId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data ?? [];
        final totalGlobalRevenue = stats.fold<double>(
          0,
          (sum, item) =>
              sum + ((item['totalRevenue'] as num?)?.toDouble() ?? 0.0),
        );

        if (stats.isEmpty || totalGlobalRevenue == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Répartition du CA par Terminal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback:
                            (
                              FlTouchEvent event,
                              PieTouchResponse? pieTouchResponse,
                            ) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse
                                    .touchedSection!
                                    .touchedSectionIndex;
                              });
                            },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildSections(
                        stats,
                        totalGlobalRevenue,
                        _touchedIndex,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Légende simple
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: List.generate(stats.length, (index) {
                    final id = stats[index]['terminalId'] as String;
                    final shortId = id.length > 8 ? id.substring(0, 8) : id;
                    final isTouched = index == _touchedIndex;
                    final revenue = stats[index]['totalRevenue'] as double;
                    final saleCount = stats[index]['saleCount'] as int;
                    final averageBasket =
                        stats[index]['averageBasket'] as double;

                    return _buildLegendItem(
                      label: 'Appareil #$shortId',
                      color: _chartColors[index % _chartColors.length],
                      isTouched: isTouched,
                      details: isTouched
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CA: ${Fmt.currency(revenue)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Ventes: $saleCount',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Panier Moyen: ${Fmt.currency(averageBasket)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(
    List<Map<String, dynamic>> stats,
    double total,
    int touchedIndex,
  ) {
    return List.generate(stats.length, (i) {
      final isTouched = i == touchedIndex;
      final value = stats[i]['totalRevenue'] as double;
      final percentage = (value / total) * 100;
      final radius = isTouched ? 60.0 : 50.0; // Agrandit la section touchée
      final fontSize = isTouched ? 14.0 : 12.0;

      return PieChartSectionData(
        color: _chartColors[i % _chartColors.length],
        value: value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? _buildBadge(
                stats[i]['terminalId'] as String,
                _chartColors[i % _chartColors.length],
              )
            : null,
        badgePositionPercentageOffset: .98,
      );
    });
  }

  Widget _buildLegendItem({
    required String label,
    required Color color,
    bool isTouched = false,
    Widget? details,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isTouched ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String terminalId, Color color) {
    final shortId = terminalId.length > 8
        ? terminalId.substring(0, 8)
        : terminalId;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Text(
          shortId,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
