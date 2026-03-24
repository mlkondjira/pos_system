// lib/presentation/screens/reports/owner_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Assurez-vous d'avoir fl_chart dans pubspec.yaml
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

// Modèle de données pour le dashboard complet
class DashboardData {
  final double totalRevenue;
  final int totalSales;
  final int shopCount;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> shopPerformances;
  final List<DailyStat> weeklyStats;

  DashboardData({
    required this.totalRevenue,
    required this.totalSales,
    required this.shopCount,
    required this.topProducts,
    required this.shopPerformances,
    required this.weeklyStats,
  });
}

class DailyStat {
  final String dayName;
  final double amount;
  DailyStat(this.dayName, this.amount);
}

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _supabase = Supabase.instance.client;
  late Future<DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchFullDashboardData();
  }

  Future<DashboardData> _fetchFullDashboardData() async {
    final now = DateTime.now();
    // On prend 30 jours pour avoir assez de données pour le top produits
    // Le graphique affichera ce qu'il peut, ou on filtrera les 7 derniers jours localement
    final startOfMonth = now.subtract(const Duration(days: 30));
    final startOfWeek = now.subtract(const Duration(days: 7));

    // Récupération de l'ID du magasin actuel (si multi-boutique, il faudrait itérer ou passer null)
    // Pour cet exemple, on prend le premier magasin trouvé ou un ID fixe si vous en avez un
    final shopsResponse = await _supabase.from('shops').select('id, name, address');
    final shops = shopsResponse as List;
    final String shopId = shops.isNotEmpty ? shops[0]['id'] : '';

    if (shopId.isEmpty) {
      return DashboardData(
          totalRevenue: 0, totalSales: 0, shopCount: 0, topProducts: [], shopPerformances: [], weeklyStats: []);
    }

    // APPEL RPC : C'est ici que la magie opère (Calcul côté serveur)
    final results = await Future.wait([
      _supabase.rpc('get_dashboard_stats', params: {
        'p_shop_id': shopId,
        'p_start_date': startOfMonth.toIso8601String(),
      }),
    ]);

    final stats = results[0] as Map<String, dynamic>;
    
    // --- Traitement 1 : Parsing des données RPC ---
    // Note : Le total renvoyé par RPC est sur 30 jours, on peut recalculer celui de 7 jours 
    // ou utiliser celui-ci. Pour l'exemple, utilisons les daily_stats pour calculer le 7j précis.
    
    final dailyStatsRaw = List<Map<String, dynamic>>.from(stats['daily_stats']);
    final topProductsRaw = List<Map<String, dynamic>>.from(stats['top_products']);

    // --- Traitement 2 : Graphique Semaine & Revenu 7j ---
    double revenue7d = 0;
    Map<String, double> dailyMap = {};

    // Préparer la map
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = DateFormat('E', 'fr_FR').format(d);
      dailyMap[key] = 0.0;
    }

    // Remplir avec les données du serveur
    for (var dayStat in dailyStatsRaw) {
      final date = DateTime.parse(dayStat['day']);
      
      // Si la date est dans les 7 derniers jours
      if (date.isAfter(startOfWeek)) {
        final amount = (dayStat['amount'] as num).toDouble();
        revenue7d += amount;
        
        final key = DateFormat('E', 'fr_FR').format(date);
        if (dailyMap.containsKey(key)) {
          dailyMap[key] = dailyMap[key]! + amount;
        }
      }
    }

    final weeklyStats = dailyMap.entries
        .map((e) => DailyStat(e.key, e.value))
        .toList();

    // --- Traitement 3 : Top Produits ---
    final top5 = topProductsRaw.map((e) => {
      'name': e['product_name'], 
      'qty': (e['qty'] as num).toInt()
    }).toList();

    // --- Traitement 4 : Performance par Magasin (Mockup ou requête séparée si multi-shop) ---
    // La RPC actuelle filtre par 1 shop ID. Pour du multi-shop réel, il faudrait adapter la RPC.
    // Ici on affiche juste le magasin courant.
    List<Map<String, dynamic>> shopPerfs = [];
    if (shops.isNotEmpty) {
      final currentShop = shops.firstWhere((s) => s['id'] == shopId, orElse: () => shops[0]);
      shopPerfs.add({
        'name': currentShop['name'],
        'address': currentShop['address'] ?? '',
        'revenue': revenue7d, // CA calculé pour ce shop
        'count': (stats['total_sales'] as num).toInt(), // Total global 30j (simplification)
      });
    }

    return DashboardData(
      totalRevenue: revenue7d,
      totalSales: (stats['total_sales'] as num).toInt(),
      shopCount: shops.length,
      topProducts: top5,
      shopPerformances: shopPerfs,
      weeklyStats: weeklyStats,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        title: const Text('Dashboard Cloud'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _dataFuture = _fetchFullDashboardData();
            }),
          )
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erreur: ${snapshot.error}\nVérifiez votre connexion internet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }
          if (!snapshot.hasData) return const SizedBox.shrink();

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dataFuture = _fetchFullDashboardData();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Résumé Global
                Row(
                  children: [
                    Expanded(child: _buildStatCard('CA (7j)', Fmt.currency(data.totalRevenue), Icons.attach_money, AppColors.success)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Ventes', '${data.totalSales}', Icons.receipt_long, AppColors.info)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCard('Magasins Actifs', '${data.shopCount}', Icons.store, AppColors.primary),
                
                const SizedBox(height: 24),
                
                // 2. Graphique
                const Text('Ventes de la semaine', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                _buildChart(data.weeklyStats),

                const SizedBox(height: 24),

                // 3. Liste des magasins
                const Text('Performances par magasin (7j)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...data.shopPerformances.map((shop) => _buildShopCard(shop)),

                const SizedBox(height: 24),

                // 4. Top Produits
                const Text('Top 5 Produits (30j)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _buildTopProducts(data.topProducts),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: const Icon(Icons.store, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (shop['address'] != '')
                  Text(shop['address'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.currency(shop['revenue']), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              Text('${shop['count']} ventes', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List<Map<String, dynamic>> products) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: products.map((p) {
          final index = products.indexOf(p);
          return ListTile(
            visualDensity: VisualDensity.compact,
            leading: Text('#${index + 1}', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            title: Text(p['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
            trailing: Text('${p['qty']} vtes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(List<DailyStat> stats) {
    // Calcul du max pour l'échelle
    double maxY = 0;
    for (var s in stats) {
      if (s.amount > maxY) maxY = s.amount;
    }
    if (maxY == 0) maxY = 100;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < stats.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        stats[index].dayName,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: stats.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.amount,
                  color: AppColors.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.2,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}