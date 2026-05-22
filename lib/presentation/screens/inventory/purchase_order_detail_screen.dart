import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

import '../../../../data/database/pos_database.dart';
import '../../../../data/services/printer_service.dart';
import '../../../../core/di/injection.dart';

class PurchaseOrderDetailScreen extends StatelessWidget {
  final PurchaseOrder po;
  final Supplier supplier;

  const PurchaseOrderDetailScreen({
    super.key,
    required this.po,
    required this.supplier,
  });

  Future<void> _exportPdf(
    BuildContext context,
    List<PurchaseOrderItemWithProduct> items,
  ) async {
    final db = context.read<PosDatabase>();
    final shopName = await db.getSetting('shop_name') ?? 'Mon Magasin';
    final printerService = getIt<PrinterService>();

    final introText = PrinterService.buildPurchaseOrderReport(
      po: po,
      supplier: supplier,
      items: items,
      shopName: shopName,
    );

    await printerService.sharePdfReport(
      fileName: 'Commande_${po.ref}',
      introText: introText,
      shareMessage:
          'Veuillez trouver ci-joint notre bon de commande ${po.ref}.',
      subject: 'Bon de Commande - $shopName',
      tableHeaders: ['Désignation', 'Qté', 'P.U. HT', 'Total'],
      tableData: items
          .map(
            (i) => [
              i.product.name,
              i.item.quantity.toString(),
              Fmt.currency(i.item.unitCost),
              Fmt.currency(i.item.lineTotal),
            ],
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<PosDatabase>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Commande ${po.ref}'),
        actions: [
          FutureBuilder<List<PurchaseOrderItemWithProduct>>(
            future: db.getPurchaseOrderItemsWithProducts(po.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () => _exportPdf(context, snapshot.data!),
                tooltip: 'Télécharger / Partager PDF',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<PurchaseOrderItemWithProduct>>(
        future: db.getPurchaseOrderItemsWithProducts(po.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];

          return Column(
            children: [
              _buildHeaderCard(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildItemTile(items[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FOURNISSEUR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  po.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            supplier.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          if (supplier.phone != null)
            Text(
              'Tél: ${supplier.phone}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MONTANT TOTAL ESTIMÉ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                Fmt.currency(po.totalAmount),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(PurchaseOrderItemWithProduct item) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(
        item.product.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text('Quantité: ${item.item.quantity} ${item.product.unit}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Fmt.currency(item.item.lineTotal),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'P.U. ${Fmt.currency(item.item.unitCost)}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
