import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/database/pos_database.dart';
import 'purchase_order_form.dart';
import 'purchase_order_detail_screen.dart';
import '../../../../data/services/printer_service.dart';
import '../../../../core/di/injection.dart';
import '../../blocs/auth_bloc.dart';
import '../settings/glass_alert_dialog.dart';
import 'morning_purchase_orders_screen.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  String? _statusFilter = 'pending'; // 'pending', 'received', null (tous)

  @override
  Widget build(BuildContext context) {
    final db = context.read<PosDatabase>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MorningPurchaseOrdersScreen(),
              ),
            ),
            tooltip: 'Rapport matinal',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterBar(),
        ),
      ),
      body: StreamBuilder<List<PurchaseOrderWithSupplier>>(
        stream: db.watchPurchaseOrders(status: _statusFilter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = orders[index];
              return _OrderCard(orderWithSupplier: item);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PurchaseOrderForm()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text(
          'Commander',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('En attente', 'pending'),
          const SizedBox(width: 8),
          _filterChip('Reçues', 'received'),
          const SizedBox(width: 8),
          _filterChip('Toutes', null),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? status) {
    final isSelected = _statusFilter == status;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      selected: isSelected,
      onSelected: (val) => setState(() => _statusFilter = status),
      selectedColor: AppColors.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).dividerColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _statusFilter == 'pending'
                ? 'Aucune commande en attente'
                : 'Historique vide',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PurchaseOrderWithSupplier orderWithSupplier;
  const _OrderCard({required this.orderWithSupplier});

  Future<void> _quickExport(BuildContext context) async {
    final db = context.read<PosDatabase>();
    final po = orderWithSupplier.purchaseOrder;
    final supplier = orderWithSupplier.supplier;
    final items = await db.getPurchaseOrderItemsWithProducts(po.id);
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
      subject: 'Bon de Commande',
    );
  }

  Future<void> _quickReceive(BuildContext context) async {
    final db = context.read<PosDatabase>();
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    final po = orderWithSupplier.purchaseOrder;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Réception rapide'),
        content: Text(
          'Voulez-vous marquer la commande ${po.ref} comme entièrement reçue ?\n\nLe stock sera mis à jour automatiquement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer la réception'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await db.validatePurchaseOrderReception(
          purchaseOrderId: po.id,
          userId: user.id,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande réceptionnée et stock mis à jour'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final po = orderWithSupplier.purchaseOrder;
    final supplier = orderWithSupplier.supplier;
    final isReceived = po.status == 'received';

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PurchaseOrderDetailScreen(po: po, supplier: supplier),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    po.ref,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    Fmt.date(po.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                supplier.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isReceived
                                      ? AppColors.success
                                      : AppColors.warning)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          po.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isReceived
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Fmt.currency(po.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (!isReceived)
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          onPressed: () => _quickReceive(context),
                          tooltip: 'Réceptionner tout',
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => _quickExport(context),
                        tooltip: 'Export rapide PDF',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
