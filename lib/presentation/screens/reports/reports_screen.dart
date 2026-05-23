// lib/presentation/screens/reports/reports_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _db = getIt<PosDatabase>();
  late TabController _tab;

  Map<String, dynamic> _todaySummary = {};
  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _topProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final shopId = await _db.getSetting('shop_id') ?? '';
    final today = await _db.salesDao.getDailySummary(DateTime.now(), shopId);
    final weekly = await _db.salesDao.getDailySalesChart(
      days: 7,
      shopId: shopId,
    );
    final top = await _db.salesDao.getTopProducts(shopId: shopId);
    setState(() {
      _todaySummary = today;
      _weeklyData = weekly;
      _topProducts = top;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header avec tabs
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: _load,
                      tooltip: 'Actualiser',
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tab,
                tabs: const [
                  Tab(text: "Aujourd'hui"),
                  Tab(text: '7 Jours'),
                  Tab(text: 'Top produits'),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 2,
              ),
            ],
          ),
        ),

        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : TabBarView(
                  controller: _tab,
                  children: [
                    _TodayTab(summary: _todaySummary, db: _db),
                    _WeeklyTab(data: _weeklyData),
                    _TopProductsTab(products: _topProducts),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── ONGLET AUJOURD'HUI ────────────────────────
class _TodayTab extends StatelessWidget {
  final Map<String, dynamic> summary;
  final PosDatabase db;

  const _TodayTab({required this.summary, required this.db});

  @override
  Widget build(BuildContext context) {
    final count = summary['sale_count'] as int? ?? 0;
    final revenue = (summary['revenue'] as double?) ?? 0.0;
    final taxes = (summary['taxes'] as double?) ?? 0.0;
    final avg = (summary['avg_basket'] as double?) ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bilan du ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now())}', // Ligne 119
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),

        // 4 stat cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.65,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _StatCard(
              label: 'Transactions',
              value: '$count',
              icon: Icons.receipt_outlined,
              color: AppColors.info,
            ),
            _StatCard(
              label: 'Chiffre d\'affaires',
              value: Fmt.currency(revenue),
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
              small: true,
            ),
            _StatCard(
              label: 'Taxes collectées',
              value: Fmt.currency(taxes),
              icon: Icons.account_balance_outlined,
              color: AppColors.warning,
              small: true,
            ),
            _StatCard(
              label: 'Panier moyen',
              value: Fmt.currency(avg),
              icon: Icons.shopping_basket_outlined,
              color: AppColors.primaryLight,
              small: true,
            ),
          ],
        ),

        const SizedBox(height: 24),
        const _SectionLabel('DERNIÈRES VENTES'),
        const SizedBox(height: 10),

        StreamBuilder<List<Sale>>(
          stream: db.salesDao.watchTodaySales(),
          builder: (ctx, snap) {
            final sales = snap.data ?? [];
            if (sales.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'Aucune vente aujourd\'hui',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              );
            }
            return Column(
              children: sales.take(15).map((s) => _SaleRow(sale: s)).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── ONGLET 7 JOURS ────────────────────────────
class _WeeklyTab extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _WeeklyTab({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Pas encore de données',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final maxRev = data
        .map((d) => (d['revenue'] as double))
        .fold(0.0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionLabel('REVENUS SUR 7 JOURS'),
        const SizedBox(height: 12),

        // Graphique barres
        Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: BarChart(
            BarChartData(
              maxY: maxRev * 1.25 + 1,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxRev > 0 ? maxRev / 3 : 1,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.border, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 58,
                    getTitlesWidget: (v, _) => Text(
                      _shortAmount(v),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.length) {
                        return const SizedBox();
                      }
                      final d = DateTime.parse(data[i]['day'] as String);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('E', 'fr_FR').format(d),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: data.asMap().entries.map((e) {
                final isToday = e.key == data.length - 1;
                final rev = (e.value['revenue'] as double);
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: rev,
                      color: isToday
                          ? AppColors
                                .accent // Ligne 273
                          : AppColors.primaryLight.withValues(alpha: 0.65),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 20),
        const _SectionLabel('DÉTAIL PAR JOUR'),
        const SizedBox(height: 10),

        ...data.reversed.map((d) {
          final date = DateTime.parse(d['day'] as String);
          final rev = d['revenue'] as double;
          final cnt = d['count'] as int;
          final isToday = _sameDay(date, DateTime.now());
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primaryLight.withValues(alpha: 0.06)
                  : AppColors.surfaceCard(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday
                    ? AppColors.primaryLight.withValues(alpha: 0.25)
                    : Theme.of(context).dividerColor,
              ),
            ), // Ligne 300
            child: Row(
              children: [
                Text(
                  isToday
                      ? "Aujourd'hui"
                      : DateFormat('EEE d MMM', 'fr_FR').format(date),
                  style: TextStyle(
                    color: isToday
                        ? AppColors
                              .primaryLight // Ligne 310
                        : AppColors.textPrimary,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '$cnt vente${cnt > 1 ? 's' : ''}',
                  style: const TextStyle(
                    // Ligne 317
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  Fmt.currency(rev),
                  style: TextStyle(
                    color: isToday ? AppColors.accent : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _shortAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

// ── ONGLET TOP PRODUITS ───────────────────────
class _TopProductsTab extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _TopProductsTab({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Pas encore de ventes enregistrées',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final maxQty = (products.first['total_qty'] as int).toDouble();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length + 1,
      itemBuilder: (ctx, i) {
        // Ligne 351
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _SectionLabel('TOP 10 — 30 DERNIERS JOURS'),
          );
        }
        final idx = i - 1;
        final p = products[idx];
        final qty = (p['total_qty'] as int).toDouble();
        final rev = p['total_revenue'] as double;
        final pct = maxQty > 0 ? qty / maxQty : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Rang
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: idx < 3
                      ? AppColors.accent.withValues(alpha: 0.18)
                      : Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12, // Ligne 394
                    color: idx < 3 ? AppColors.accentDark : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] as String,
                      style: const TextStyle(
                        color: AppColors.textPrimary, // Ligne 400
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          idx < 3 ? AppColors.accent : AppColors.primaryLight,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p['total_qty']} ${p['unit']}',
                    style: const TextStyle(
                      color: AppColors.textPrimary, // Ligne 420
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    Fmt.currency(rev),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── WIDGETS COMMUNS ───────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool small;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: small ? 16 : 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final Sale sale;
  const _SaleRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        // Ligne 500
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            sale.ref,
            style: const TextStyle(
              color: AppColors.textSecondary, // Ligne 503
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('HH:mm').format(sale.createdAt),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 14), // Ligne 512
          Text(
            Fmt.currency(sale.totalTtc),
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
