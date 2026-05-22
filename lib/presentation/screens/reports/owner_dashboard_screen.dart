import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/services/sync_service.dart';
import '../../../data/database/pos_database.dart';
import '../../widgets/shared_widgets.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _db = getIt<PosDatabase>();
  final _syncService = getIt<SyncService>(); // Get SyncService instance
  int _days = 14;
  String? _selectedShopId; // null = Tous les magasins
  List<Shop> _availableShops = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _chartData = [];
  Map<String, double> _expenseBreakdown = {};
  List<Map<String, dynamic>> _shopPerformance = [];
  List<Map<String, dynamic>> _terminalPerformance = [];
  List<Map<String, dynamic>> _stockAdvice = [];
  double _totalRevenue = 0;
  double _grossMargin = 0; // Renamed from _totalCogs for clarity based on RPC
  double _netProfitValue = 0; // To store the net profit from RPC
  double _totalExpenses = 0;
  int _totalSales = 0;
  int _outOfStockCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Charger la liste des magasins disponibles si ce n'est pas déjà fait
    if (_availableShops.isEmpty) {
      _availableShops = await _db.select(_db.shops).get();
    }

    final fromDate = DateTime.now().subtract(Duration(days: _days));
    final toDate = DateTime.now();

    try {
      final dashboardStats = await _syncService.getDashboardStats(
        startDate: fromDate,
        endDate: toDate,
        terminalId:
            null, // The RPC function takes an optional terminalId, but for owner dashboard, we usually want all terminals.
      );

      // Parse the response from the RPC function
      _totalRevenue =
          (dashboardStats['total_revenue'] as num?)?.toDouble() ?? 0.0;
      _totalSales = (dashboardStats['total_sales'] as num?)?.toInt() ?? 0;
      _grossMargin =
          (dashboardStats['gross_margin'] as num?)?.toDouble() ?? 0.0;
      _netProfitValue =
          (dashboardStats['net_profit'] as num?)?.toDouble() ?? 0.0;
      _totalExpenses =
          (dashboardStats['total_expenses'] as num?)?.toDouble() ?? 0.0;
      _outOfStockCount =
          (dashboardStats['out_of_stock_count'] as num?)?.toInt() ?? 0;

      // Daily stats for the main chart
      _chartData =
          (dashboardStats['daily_stats'] as List?)
              ?.map(
                (e) => {
                  'day': e['day'] as String,
                  'revenue': (e['amount'] as num).toDouble(),
                },
              )
              .toList() ??
          [];

      // Shop performance for comparison chart
      _shopPerformance =
          (dashboardStats['shop_performances'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];

      // Récupérer les conseils d'approvisionnement
      _stockAdvice = await _syncService.getStockPredictions(
        shopId: _selectedShopId,
      );

      // Terminal performance (if needed for a separate chart or display)
      _terminalPerformance =
          (dashboardStats['terminal_performances'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];

      // Expense breakdown (assuming the RPC provides this or we calculate it from raw expenses)
      // The RPC already provides total_expenses, but not a breakdown by category.
      // If the RPC is enhanced to provide this, we can use it. For now, we'll keep the local calculation for breakdown.
      // Or, if the RPC provides it, we would parse it here.
      // For now, let's assume the RPC doesn't provide breakdown and keep the local logic for it.
      final expenses = await _db
          .watchExpenses(_selectedShopId ?? '', from: fromDate)
          .first;
      _expenseBreakdown = {};
      for (var e in expenses) {
        _expenseBreakdown[e.category] =
            (_expenseBreakdown[e.category] ?? 0) + e.amount;
      }
    } catch (e) {
      debugPrint('Error loading dashboard data from cloud: $e');
      // Fallback to local data or show an error message
      // For now, let's just set everything to zero or empty on error
      _totalRevenue = 0;
      _totalSales = 0;
      _grossMargin = 0;
      _netProfitValue = 0;
      _totalExpenses = 0;
      _outOfStockCount = 0;
      _chartData = [];
      _shopPerformance = [];
      _terminalPerformance = [];
      _expenseBreakdown = {};
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _generatePOFromAdvice(Map<String, dynamic> advice) async {
    final int? supplierId = advice['preferred_supplier_id'];
    if (supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun fournisseur préféré défini pour ce produit. Allez dans l\'onglet Produits.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Générer Bon de Commande'),
        content: Text(
          'Voulez-vous créer une commande de ${advice['recommended_order_qty']} ${advice['unit']} pour "${advice['product_name']}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Générer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final terminalId = await _db.getSetting('terminal_id') ?? '';

      await _db.createPurchaseOrder(
        supplierId: supplierId,
        shopId: advice['shop_id'],
        terminalId: terminalId,
        items: [
          {
            'productId': advice['product_id'],
            'qty': (advice['recommended_order_qty'] as num).toInt(),
            'unitCost': (advice['cost_price'] as num?)?.toDouble() ?? 0.0,
          },
        ],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bon de commande généré avec succès.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) _loadData();
    }
  }

  Widget _buildStockAdviceSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology_outlined, color: AppColors.accent),
            const SizedBox(width: 12),
            Text(
              'EXPERTISE CONSEIL : RÉAPPROVISIONNEMENT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 150,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _stockAdvice.length,
          itemBuilder: (context, index) {
            final item = _stockAdvice[index];
            final int days = item['days_remaining'];
            final color = days <= 2 ? AppColors.danger : AppColors.warning;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['product_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _generatePOFromAdvice(item),
                        icon: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 20,
                        ),
                        color: AppColors.primary,
                        tooltip: 'Générer Bon de Commande',
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Magasin : ${item['shop_name']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      StatusBadge(
                        label: days <= 0 ? 'RUPTURE' : 'J-$days',
                        color: color,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_cart_checkout_rounded,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conseil : Commander ${item['recommended_order_qty']} ${item['unit']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // double get _netProfit => _totalRevenue - _totalCogs - _totalExpenses; // This calculation is now directly from RPC
  double get _marginPct =>
      _totalRevenue > 0 ? ((_grossMargin) / _totalRevenue) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        actions: [
          // Ligne 85
          // Filtre Magasin
          DropdownButton<String?>(
            value: _selectedShopId,
            underline: const SizedBox(),
            dropdownColor: Theme.of(context).colorScheme.surface,
            hint: const Text(
              'Tous les magasins',
              style: TextStyle(fontSize: 14),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Tous les magasins'),
              ),
              ..._availableShops.map(
                (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
              ),
            ],
            onChanged: (v) {
              setState(() {
                _selectedShopId = v;
                _loadData();
              });
            },
          ),
          const VerticalDivider(width: 20, indent: 15, endIndent: 15),
          DropdownButton<int>(
            value: _days,
            underline: const SizedBox(),
            dropdownColor: Theme.of(context).colorScheme.surface,
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 derniers jours')),
              DropdownMenuItem(value: 14, child: Text('14 derniers jours')),
              DropdownMenuItem(value: 30, child: Text('30 derniers jours')),
            ],
            onChanged: (v) {
              if (v != null) {
                _days = v;
                _loadData();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiSection(isDesktop),
                  const SizedBox(height: 24),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildMainChart()),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildExpenseChart()),
                      ],
                    )
                  else ...[
                    _buildMainChart(),
                    const SizedBox(height: 24),
                    _buildExpenseChart(),
                  ],
                  if (_stockAdvice.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildStockAdviceSection(), // NOUVEAU
                  ],
                  if (_selectedShopId == null &&
                      _shopPerformance.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildShopComparisonChart(),
                  ],
                  if (_terminalPerformance.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildTerminalComparisonChart(), // New chart for terminal performance
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildKpiSection(bool isDesktop) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _kpiCard(
          'CHIFFRE D\'AFFAIRES',
          Fmt.currency(_totalRevenue),
          Icons.payments_outlined, // Ligne 133
          AppColors.primary,
          isDesktop,
        ),
        _kpiCard(
          'MARGE COMMERCIALE',
          '${_marginPct.toStringAsFixed(1)}%',
          Icons.trending_up_rounded,
          AppColors.accent, // Ligne 140
          isDesktop,
        ),
        _kpiCard(
          'PROFIT NET ESTIMÉ',
          Fmt.currency(_netProfitValue), // Use _netProfitValue from RPC
          Icons.account_balance_wallet_outlined,
          _netProfitValue >= 0 ? AppColors.success : AppColors.danger,
          isDesktop,
        ),
        _kpiCard(
          'VENTES TOTALES',
          _totalSales.toString(),
          Icons.shopping_cart_outlined,
          AppColors.info,
          isDesktop,
        ),
        _kpiCard(
          'PRODUITS EN RUPTURE',
          _outOfStockCount.toString(),
          Icons.inventory_2_outlined,
          _outOfStockCount > 0 ? AppColors.warning : AppColors.success,
          isDesktop, // Ligne 161
        ),
      ],
    );
  }

  Widget _kpiCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDesktop,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: isDesktop
          ? (MediaQuery.of(context).size.width - 100) / 3
          : double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Ligne 173
        // Ligne 173
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    final theme = Theme.of(context);
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERFORMANCE DES VENTES VS PROFIT',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        theme.colorScheme.surfaceContainerHighest,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      // Ligne 210
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          Fmt.currency(touchedSpot.y),
                          TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: theme.dividerColor, strokeWidth: 1),
                ),
                titlesData: _buildTitlesData(theme),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Courbe de Revenu (Bleu)
                  LineChartBarData(
                    spots: _chartData
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(
                            e.key.toDouble(),
                            (e.value['revenue'] as num).toDouble(),
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    color: AppColors.primary, // Ligne 240
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  // Courbe de Profit (Émeraude) - Profit net journalier estimé
                  LineChartBarData(
                    // Assuming net profit is a percentage of revenue for this chart,
                    // or if RPC provides daily net profit, use that.
                    // For now, let's use a simplified representation if RPC doesn't provide daily net profit breakdown.
                    spots: _chartData
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(
                            e.key.toDouble(),
                            (e.value['revenue'] as num).toDouble() *
                                (_netProfitValue / _totalRevenue).clamp(
                                  0.0,
                                  1.0,
                                ),
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 3, // Ligne 248
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseChart() {
    final theme = Theme.of(context);
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉPARTITION DES CHARGES',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _expenseBreakdown.isEmpty
                ? Center(
                    child: Text(
                      'Aucune donnée de dépense',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: _expenseBreakdown.entries.map((e) {
                        final List<Color> colors = [
                          AppColors.primary,
                          AppColors.accent,
                          AppColors.warning,
                          AppColors.danger,
                          Colors.purple,
                        ];
                        final index =
                            _expenseBreakdown.keys.toList().indexOf(e.key) %
                            colors.length;
                        return PieChartSectionData(
                          color: colors[index],
                          value: e.value,
                          title:
                              '${((e.value / _totalExpenses) * 100).toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          _buildExpenseLegend(theme),
        ],
      ),
    );
  }

  Widget _buildShopComparisonChart() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHIFFRE D\'AFFAIRES PAR MAGASIN',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        theme.colorScheme.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      // Ligne 316
                      return BarTooltipItem(
                        '${_shopPerformance[groupIndex]['name']}\n',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: Fmt.currency(rod.toY),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  // Ligne 330
                  show: true, // Ligne 330
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _shopPerformance.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _shopPerformance[index]['name'],
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _shopPerformance.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['revenue'] as num).toDouble(),
                        color: AppColors.primary, // Ligne 365
                        width: 30,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalComparisonChart() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHIFFRE D\'AFFAIRES PAR CAISSE',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        theme.colorScheme.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${_terminalPerformance[groupIndex]['terminal_name']}\n',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: Fmt.currency(rod.toY),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _terminalPerformance.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _terminalPerformance[index]['terminal_name'],
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _terminalPerformance.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['revenue'] as num).toDouble(),
                        color: AppColors
                            .accent, // Different color for terminal chart
                        width: 30,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseLegend(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _expenseBreakdown.entries.map((e) {
        final List<Color> colors = [
          AppColors.primary,
          AppColors.accent,
          AppColors.warning,
          AppColors.danger,
          Colors.purple,
        ];
        final index =
            _expenseBreakdown.keys.toList().indexOf(e.key) % colors.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                // Ligne 380
                color: colors[index],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4), // Ligne 380
            Text(
              e.key,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  FlTitlesData _buildTitlesData(ThemeData theme) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(
        // Ligne 390
        sideTitles: SideTitles(showTitles: false),
      ), // Ligne 390
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= _chartData.length || value.toInt() < 0) {
              return const SizedBox();
            }
            // On affiche un jour sur 3 pour ne pas encombrer
            if (value.toInt() % 3 != 0) {
              return const SizedBox();
            }
            if (_chartData.isEmpty || value.toInt() % 3 != 0) {
              return const SizedBox();
            }
            final dateStr = _chartData[value.toInt()]['day'] as String;
            final date = DateTime.parse(dateStr);
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${date.day}/${date.month}',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: (_totalRevenue / 4).clamp(1000, 50000), // Dynamic interval
          reservedSize: 42,
          getTitlesWidget: (value, meta) {
            return Text(
              value >= 1000
                  ? '${(value / 1000).toStringAsFixed(0)}k'
                  : value.toStringAsFixed(0),
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            );
          },
        ),
      ),
    );
  }
}
