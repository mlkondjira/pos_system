import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/stock_predictor.dart';
import '../../../data/services/printer_service.dart';
import '../../../data/database/pos_database.dart';

class StockPredictionPanel extends StatefulWidget {
  const StockPredictionPanel({super.key});

  @override
  State<StockPredictionPanel> createState() => _StockPredictionPanelState();
}

class _StockPredictionPanelState extends State<StockPredictionPanel> {
  late Future<List<StockPrediction>> _predictionsFuture;
  bool _onlyAtRisk = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _predictionsFuture = getIt<StockPredictor>().analyzeAll(
        onlyAtRisk: _onlyAtRisk,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                'PRÉVISIONS DE STOCK (IA LOCALE)',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text('Risques uniquement', style: theme.textTheme.bodySmall),
              Switch.adaptive(
                value: _onlyAtRisk,
                activeTrackColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _onlyAtRisk = v);
                  _refresh();
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _refresh,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<StockPrediction>>(
          future: _predictionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Erreur d\'analyse : ${snapshot.error}'),
              );
            }

            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'Aucun risque de rupture détecté pour le moment.',
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 350,
                mainAxisExtent: 180,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) =>
                  _PredictionCard(prediction: list[index]),
            );
          },
        ),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final StockPrediction prediction;

  const _PredictionCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prediction.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  prediction.levelLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stock: ${prediction.currentStock} / ${prediction.stockAlert}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.share, size: 18),
                onPressed: () => _shareToSupplier(context),
              ),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                onPressed: () => _generatePO(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor() {
    switch (prediction.level) {
      case PredictionLevel.outOfStock:
        return AppColors.danger;
      case PredictionLevel.critical:
        return Colors.deepOrange;
      case PredictionLevel.warning:
        return AppColors.warning;
      case PredictionLevel.alert:
        return Colors.amber;
      case PredictionLevel.ok:
        return AppColors.success;
    }
  }

  Future<void> _generatePO(BuildContext context) async {
    final db = getIt<PosDatabase>();
    final supplierId = prediction.preferredSupplierId;

    if (supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun fournisseur préféré défini pour ce produit.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final qty = prediction.suggestedOrderQty;
    if (qty <= 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Générer Bon de Commande'),
        content: Text(
          'Voulez-vous créer une commande de $qty ${prediction.unit} pour "${prediction.productName}" ?',
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

    try {
      final terminalId = await db.getSetting('terminal_id') ?? '';
      final shopId = prediction.shopId ?? await db.getSetting('shop_id') ?? '';

      await db.createPurchaseOrder(
        supplierId: supplierId,
        shopId: shopId,
        terminalId: terminalId,
        items: [
          {
            'productId': prediction.productId,
            'qty': qty,
            'unitCost': prediction.costPrice,
          },
        ],
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bon de commande généré avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _shareToSupplier(BuildContext context) async {
    final db = getIt<PosDatabase>();
    final supplierId = prediction.preferredSupplierId;

    if (supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun fournisseur préféré défini pour ce produit.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final supplier = await db.getSupplierById(supplierId);
    if (!context.mounted) return;
    if (supplier == null || supplier.phone == null || supplier.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le fournisseur n\'a pas de numéro de téléphone enregistré.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Demander le format à l'utilisateur
    if (!context.mounted) return;
    final String? format = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_outlined, color: Colors.green),
              title: const Text('Envoyer un message WhatsApp'),
              onTap: () => Navigator.pop(ctx, 'text'),
            ),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
                color: Colors.red,
              ),
              title: const Text('Envoyer un document PDF'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (format == null) return;

    if (!context.mounted) return;
    final shopName = await db.getSetting('shop_name') ?? 'Mon Magasin';
    final qty = prediction.suggestedOrderQty;
    final contactPerson = supplier.contactName ?? supplier.name;

    final signatureText =
        'Signature:\n\n____________________\nL\'équipe $shopName';

    try {
      if (format == 'text') {
        final message =
            ' *DEMANDE DE RÉAPPROVISIONNEMENT*\n'
            'Magasin : *$shopName*\n'
            'Date : ${Fmt.dateTime(DateTime.now())}\n\n'
            'Bonjour $contactPerson,\n\n'
            'Suite à notre analyse automatique des stocks, nous souhaiterions passer commande pour l\'article suivant :\n\n'
            '📦 *Produit :* ${prediction.productName}\n'
            '🔢 *Quantité souhaitée :* $qty ${prediction.unit}\n'
            '📉 *État du stock actuel :* ${prediction.currentStock} ${prediction.unit}\n\n'
            'Pourriez-vous nous confirmer la disponibilité de cet article ainsi que votre meilleur délai de livraison ?\n\n'
            'Dans l\'attente de votre retour.\n'
            'Cordialement,\n'
            'L\'équipe $shopName';

        final cleanPhone = supplier.phone!.replaceAll(RegExp(r'[^\d+]'), '');
        final uri = Uri.parse(
          'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
        );

        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Impossible d\'ouvrir WhatsApp';
        }
      } else {
        if (!context.mounted) return;
        // Version PDF via PrinterService
        await getIt<PrinterService>().sharePdfReport(
          fileName: 'Commande_${prediction.productName}',
          introText:
              'DEMANDE DE RÉAPPROVISIONNEMENT\nMagasin : $shopName\nDate : ${Fmt.dateTime(DateTime.now())}\n\nFournisseur : ${supplier.name}',
          shareMessage:
              'Bonjour, veuillez trouver ci-joint notre demande de réapprovisionnement pour ${prediction.productName}. Cordialement.',
          subject: 'Demande de réapprovisionnement - $shopName',
          tableHeaders: ['Désignation', 'Quantité', 'Unité'],
          tableData: [
            [prediction.productName, qty.toString(), prediction.unit],
          ],
          signatureText: signatureText,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
