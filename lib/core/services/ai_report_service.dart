// lib/core/services/ai_report_service.dart
// ============================================================
//  Service de rapport IA hebdomadaire WhatsApp
//  - Analyse les ventes de la semaine via Claude API
//  - Génère un résumé en 5 points envoyé sur WhatsApp
//  - Se déclenche chaque lundi matin automatiquement
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../data/database/pos_database.dart';

// ── MODÈLES ───────────────────────────────────────────────────

class WeeklyReportData {
  final double totalRevenue;
  final int totalSales;
  final double avgBasket;
  final List<TopProduct> topProducts;
  final Map<int, double> revenueByHour; // heure → CA
  final List<LowStockAlert> lowStockAlerts;
  final double revenueVsLastWeek; // % de variation vs semaine précédente
  final String shopName;
  final String period; // "12-18 mai 2025"

  const WeeklyReportData({
    required this.totalRevenue,
    required this.totalSales,
    required this.avgBasket,
    required this.topProducts,
    required this.revenueByHour,
    required this.lowStockAlerts,
    required this.revenueVsLastWeek,
    required this.shopName,
    required this.period,
  });
}

class TopProduct {
  final String name;
  final int qtySold;
  final double revenue;
  const TopProduct({
    required this.name,
    required this.qtySold,
    required this.revenue,
  });
}

class LowStockAlert {
  final String productName;
  final int currentStock;
  final int? daysUntilStockout;
  const LowStockAlert({
    required this.productName,
    required this.currentStock,
    this.daysUntilStockout,
  });
}

// ── SERVICE ──────────────────────────────────────────────────

class AiReportService {
  final PosDatabase _db;

  // Clé API Claude — à stocker dans les settings chiffrés
  // Ne jamais hardcoder en production
  static const _claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const _claudeModel = 'claude-sonnet-4-20250514';

  Timer? _weeklyTimer;

  AiReportService(this._db);

  // ── DÉMARRAGE DU TIMER HEBDOMADAIRE ──────────────────────

  void startWeeklyScheduler({required String ownerPhone}) {
    _weeklyTimer?.cancel();
    // Vérifier toutes les heures si c'est le moment d'envoyer
    _weeklyTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkAndSendReport(ownerPhone: ownerPhone),
    );
    // Vérification immédiate au démarrage
    _checkAndSendReport(ownerPhone: ownerPhone);
  }

  Future<void> _checkAndSendReport({required String ownerPhone}) async {
    final now = DateTime.now();
    // Envoyer le lundi matin entre 7h et 8h
    if (now.weekday != DateTime.monday) {
      return;
    }
    if (now.hour != 7) {
      return;
    }

    // Vérifier qu'on n'a pas déjà envoyé cette semaine
    final lastSent = await _db.getSetting('last_weekly_report');
    if (lastSent != null) {
      final lastDate = DateTime.tryParse(lastSent);
      if (lastDate != null && now.difference(lastDate).inHours < 24) return;
    }

    await sendWeeklyReport(ownerPhone: ownerPhone);
    await _db.setSetting('last_weekly_report', now.toIso8601String());
  }

  // ── GÉNÉRATION ET ENVOI DU RAPPORT ───────────────────────

  Future<bool> sendWeeklyReport({
    required String ownerPhone,
    String? claudeApiKey,
    bool useAi = true,
  }) async {
    try {
      // 1. Collecter les données de la semaine
      final data = await _collectWeeklyData();

      // 2. Générer le texte du rapport
      String reportText;
      if (useAi && claudeApiKey != null && claudeApiKey.isNotEmpty) {
        reportText = await _generateWithClaude(
          data: data,
          apiKey: claudeApiKey,
        );
      } else {
        reportText = _generateFallback(data);
      }

      // 3. Envoyer sur WhatsApp
      return await _sendWhatsApp(phone: ownerPhone, message: reportText);
    } catch (e) {
      debugPrint('AiReportService error: $e');
      return false;
    }
  }

  // ── COLLECTE DES DONNÉES ─────────────────────────────────

  Future<WeeklyReportData> _collectWeeklyData() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + 7));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));

    // Ventes de cette semaine
    final sales = await _db.getSalesInPeriod(from: weekStart, to: weekEnd);

    // Ventes semaine précédente (pour comparaison)
    final prevSales = await _db.getSalesInPeriod(
      from: prevWeekStart,
      to: weekStart,
    );

    final totalRevenue = sales.fold(0.0, (sum, s) => sum + s.totalTtc);
    final prevRevenue = prevSales.fold(0.0, (sum, s) => sum + s.totalTtc);

    final revenueChange = prevRevenue > 0
        ? ((totalRevenue - prevRevenue) / prevRevenue) * 100
        : 0.0;

    // Top produits
    final saleItems = await _db.getSaleItemsForSales(
      sales.map((s) => s.id).toList(),
    );
    final productMap = <int, _ProductAccum>{};
    for (final item in saleItems) {
      productMap.putIfAbsent(item.productId, () => _ProductAccum());
      productMap[item.productId]!.qty += item.quantity.toInt();
      productMap[item.productId]!.revenue += item.lineTotal.toDouble();
      productMap[item.productId]!.name = item.productName;
    }

    final topProducts =
        productMap.entries
            .map(
              (e) => TopProduct(
                name: e.value.name,
                qtySold: e.value.qty,
                revenue: e.value.revenue,
              ),
            )
            .toList()
          ..sort((a, b) => b.qtySold.compareTo(a.qtySold));

    // Répartition par heure
    final revenueByHour = <int, double>{};
    for (final sale in sales) {
      final hour = sale.createdAt.hour;
      revenueByHour[hour] = (revenueByHour[hour] ?? 0) + sale.totalTtc;
    }

    // Alertes stock
    final lowStock = await _db.getLowStockProducts();
    final alerts = lowStock
        .take(5)
        .map(
          (p) => LowStockAlert(productName: p.name, currentStock: p.stockQty),
        )
        .toList();

    // Période formatée
    final months = [
      '',
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'juin',
      'juil',
      'août',
      'sep',
      'oct',
      'nov',
      'déc',
    ];
    final period = '${weekStart.day}-${weekEnd.day} ${months[weekStart.month]}';

    final shopName = await _db.getSetting('shop_name') ?? 'Mon Magasin';

    return WeeklyReportData(
      totalRevenue: totalRevenue,
      totalSales: sales.length,
      avgBasket: sales.isEmpty ? 0 : totalRevenue / sales.length,
      topProducts: topProducts.take(5).toList(),
      revenueByHour: revenueByHour,
      lowStockAlerts: alerts,
      revenueVsLastWeek: revenueChange,
      shopName: shopName,
      period: period,
    );
  }

  // ── GÉNÉRATION IA (Claude API) ───────────────────────────

  Future<String> _generateWithClaude({
    required WeeklyReportData data,
    required String apiKey,
  }) async {
    final prompt = _buildClaudePrompt(data);

    final response = await http
        .post(
          Uri.parse(_claudeApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': _claudeModel,
            'max_tokens': 500,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'system': '''Tu es l'assistant de GPOS, un logiciel de caisse 
pour petits commerçants en Afrique de l'Ouest. Tu génères des rapports 
hebdomadaires courts et utiles en français, envoyés sur WhatsApp. 
Ton ton est direct, pratique et encourageant. 
Utilise des émojis pertinents. Maximum 5 points, 200 mots.
Termine toujours par un conseil actionnable concret.''',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'] as List;
      final text = content
          .where((c) => c['type'] == 'text')
          .map((c) => c['text'] as String)
          .join('');
      return text;
    } else {
      debugPrint('Claude API error: ${response.statusCode}');
      return _generateFallback(data);
    }
  }

  String _buildClaudePrompt(WeeklyReportData data) {
    final top3 = data.topProducts
        .take(3)
        .map(
          (p) => '${p.name} (${p.qtySold} vendus, ${p.revenue.toInt()} FCFA)',
        )
        .join(', ');

    final peakHour = data.revenueByHour.isEmpty
        ? 'inconnue'
        : '${data.revenueByHour.entries.reduce((a, b) => a.value > b.value ? a : b).key}h';

    final stockAlerts = data.lowStockAlerts.isEmpty
        ? 'aucune'
        : data.lowStockAlerts
              .map((a) => '${a.productName} (${a.currentStock} restants)')
              .join(', ');

    final trend = data.revenueVsLastWeek >= 0
        ? '+${data.revenueVsLastWeek.toStringAsFixed(1)}%'
        : '${data.revenueVsLastWeek.toStringAsFixed(1)}%';

    return '''Génère le rapport hebdomadaire WhatsApp de ${data.shopName} pour la semaine du $data.period.

Données :
- CA total : ${data.totalRevenue.toInt()} FCFA ($trend vs semaine dernière)
- Nombre de ventes : ${data.totalSales}
- Panier moyen : ${data.avgBasket.toInt()} FCFA
- Top 3 produits : $top3
- Heure de pointe : $peakHour
- Alertes stock : $stockAlerts

Génère un rapport en 5 points avec émojis, en commençant par "📊 *Rapport GPOS — ${data.period}*"''';
  }

  // ── FALLBACK (sans API) ──────────────────────────────────

  String _generateFallback(WeeklyReportData data) {
    final trend = data.revenueVsLastWeek >= 0
        ? '📈 +${data.revenueVsLastWeek.toStringAsFixed(1)}%'
        : '📉 ${data.revenueVsLastWeek.toStringAsFixed(1)}%';

    final top1 = data.topProducts.isNotEmpty
        ? data.topProducts.first.name
        : 'N/A';

    final peakHour = data.revenueByHour.isEmpty
        ? '?'
        : '${data.revenueByHour.entries.reduce((a, b) => a.value > b.value ? a : b).key}h';

    final stockSection = data.lowStockAlerts.isEmpty
        ? '✅ Tous les stocks sont au niveau'
        : '⚠️ ${data.lowStockAlerts.length} produit(s) à réapprovisionner : '
              '${data.lowStockAlerts.map((a) => a.productName).join(', ')}';

    final advice = _generateAdvice(data);

    return '''📊 *Rapport GPOS — ${data.period}*
_${data.shopName}_

💰 *CA semaine :* ${_fmt(data.totalRevenue)} FCFA ($trend)
🧾 *Ventes :* ${data.totalSales} transactions
🛒 *Panier moyen :* ${_fmt(data.avgBasket)} FCFA

🏆 *Meilleur produit :* $top1
⏰ *Heure de pointe :* $peakHour

$stockSection

💡 *Conseil :* $advice

_Rapport automatique GPOS_''';
  }

  String _generateAdvice(WeeklyReportData data) {
    if (data.lowStockAlerts.isNotEmpty) {
      final product = data.lowStockAlerts.first.productName;
      return 'Commandez *$product* aujourd\'hui — stock critique.';
    }
    if (data.revenueVsLastWeek < -10) {
      return 'CA en baisse. Proposez une promo flash cette semaine.';
    }
    if (data.revenueByHour.isNotEmpty) {
      final peakHour = data.revenueByHour.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      return 'Assurez-vous d\'avoir assez de caissiers à ${peakHour}h.';
    }
    if (data.topProducts.isNotEmpty) {
      return 'Mettez *${data.topProducts.first.name}* en avant à l\'entrée du magasin.';
    }
    return 'Continuez comme ça — bonne semaine en vue !';
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  // ── ENVOI WHATSAPP ───────────────────────────────────────

  Future<bool> _sendWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
    }
    return false;
  }

  void dispose() {
    _weeklyTimer?.cancel();
  }
}

class _ProductAccum {
  String name = '';
  int qty = 0;
  double revenue = 0;
}

// L'extension AiReportDbExtension a été déplacée vers pos_database.dart
