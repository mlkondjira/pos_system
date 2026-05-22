import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/services/sync_service.dart';
import '../../widgets/shared_widgets.dart';

class TopProductsReportScreen extends StatefulWidget {
  const TopProductsReportScreen({super.key});

  @override
  State<TopProductsReportScreen> createState() =>
      _TopProductsReportScreenState();
}

class _TopProductsReportScreenState extends State<TopProductsReportScreen> {
  final _syncService = getIt<SyncService>();

  int _days = 30;
  bool _isLoading = true;
  List<Map<String, dynamic>> _topProducts = [];
  double _totalRevenueFromTopProducts = 0;
  double _totalItemsSold = 0;
  bool _sortByRevenue = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final fromDate = DateTime.now().subtract(Duration(days: _days));
    final toDate = DateTime.now();

    try {
      // On utilise la fonction RPC du cloud via le SyncService
      final stats = await _syncService.getDashboardStats(
        startDate: fromDate,
        endDate: toDate,
        sortByRevenue: _sortByRevenue,
      );

      final List<dynamic> productsRaw = stats['top_products'] ?? [];
      _topProducts = productsRaw
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Calcul des totaux pour le top
      _totalRevenueFromTopProducts = _topProducts.fold<double>(
        0.0,
        (sum, item) => sum + (item['revenue'] as num).toDouble(),
      );
      _totalItemsSold = _topProducts.fold<double>(
        0.0,
        (sum, item) => sum + (item['qty'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('Erreur Top Produits: $e');
      _topProducts = [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          DropdownButton<int>(
            value: _days,
            underline: const SizedBox(),
            dropdownColor: theme.colorScheme.surface,
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 jours')),
              DropdownMenuItem(value: 30, child: Text('30 jours')),
              DropdownMenuItem(value: 90, child: Text('3 mois')),
            ],
            onChanged: (v) {
              if (v != null) {
                _days = v;
                _loadData();
              }
            },
          ),
          const SizedBox(width: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('CA'),
                icon: Icon(Icons.money_rounded),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('Qté'),
                icon: Icon(Icons.numbers_rounded),
              ),
            ],
            selected: {_sortByRevenue},
            onSelectionChanged: (newSelection) {
              setState(() => _sortByRevenue = newSelection.first);
              _loadData();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topProducts.isEmpty
          ? const EmptyState(
              icon: Icons.analytics_outlined,
              title: 'Aucune donnée',
              subtitle: 'Pas de ventes enregistrées sur cette période.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildChart(),
                  const SizedBox(height: 32),
                  const Text(
                    'DÉTAIL DES PERFORMANCES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProductsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sortByRevenue ? 'CA DU TOP PROD.' : 'VOLUME DU TOP PROD.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _sortByRevenue
                    ? Fmt.currency(_totalRevenueFromTopProducts)
                    : '${_totalItemsSold.toInt()} unités vendues',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final theme = Theme.of(context);
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Ligne 198
        borderRadius: BorderRadius.circular(24),
        border: const Border.fromBorderSide(
          BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _topProducts.isEmpty
              ? (_sortByRevenue ? 1000 : 10) // Default max for empty data
              : (_sortByRevenue
                        ? (_topProducts.first['revenue'] as num).toDouble()
                        : (_topProducts.first['qty'] as num).toDouble()) *
                    1.2,
          barTouchData: const BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _topProducts.length) {
                    return const SizedBox();
                  }
                  final name =
                      _topProducts[value.toInt()]['product_name'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 7)}.' : name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: _topProducts.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (_sortByRevenue
                      ? (e.value['revenue'] as num).toDouble()
                      : (e.value['qty'] as num).toDouble()),
                  color: AppColors.primary,
                  width: 25,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY:
                        (_sortByRevenue
                            ? (_topProducts.first['revenue'] as num).toDouble()
                            : (_topProducts.first['qty'] as num).toDouble()) *
                        1.2,
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _topProducts.length,
      itemBuilder: (context, index) {
        final product = _topProducts[index];
        final displayValue = _sortByRevenue
            ? (product['revenue'] as num).toDouble()
            : (product['qty'] as num).toDouble();
        final totalForPercent = _sortByRevenue
            ? _totalRevenueFromTopProducts
            : _totalItemsSold;
        final percent = totalForPercent > 0
            ? (displayValue / totalForPercent) * 100
            : 0; // Calculate percentage based on total revenue

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              product['product_name'] ?? 'Inconnu',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: AppColors.border,
                    color: AppColors.success,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _sortByRevenue
                      ? Fmt.currency(displayValue)
                      : '${displayValue.toInt()} ${product['unit'] ?? 'unités'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
