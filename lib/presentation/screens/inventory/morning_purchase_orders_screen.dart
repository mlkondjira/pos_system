import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/services/printer_service.dart';
import '../../widgets/shared_widgets.dart';

class MorningPurchaseOrdersScreen extends StatefulWidget {
  const MorningPurchaseOrdersScreen({super.key});

  @override
  State<MorningPurchaseOrdersScreen> createState() =>
      _MorningPurchaseOrdersScreenState();
}

class _MorningPurchaseOrdersScreenState
    extends State<MorningPurchaseOrdersScreen> {
  final _db = getIt<PosDatabase>();
  final _printerService = getIt<PrinterService>();
  bool _isLoading = true;
  List<PurchaseOrderWithSupplier> _morningOrders = [];

  @override
  void initState() {
    super.initState();
    _loadMorningOrders();
  }

  Future<void> _loadMorningOrders() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final morningStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final morningEnd = DateTime(now.year, now.month, now.day, 12, 0, 0);

    final shopId = await _db.getSetting('shop_id');
    final orders = await _db.getPurchaseOrdersForPeriod(
      morningStart,
      morningEnd,
      shopId: shopId,
    );

    if (mounted) {
      setState(() {
        _morningOrders = orders;
        _isLoading = false;
      });
    }
  }

  Future<void> _printAll() async {
    if (_morningOrders.isEmpty) return;
    final shopName = await _db.getSetting('shop_name') ?? 'Mon Magasin';
    await _printerService.shareBulkPurchaseOrdersPdf(
      fileName:
          'Rapport_Matinal_BC_${Fmt.date(DateTime.now()).replaceAll('/', '_')}',
      orders: _morningOrders,
      db: _db,
      shopName: shopName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bons de Commande du Matin'),
        actions: [
          if (_morningOrders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: _printAll,
              tooltip: 'Exporter tout en PDF',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _morningOrders.isEmpty
          ? const EmptyState(
              icon: Icons.wb_twilight_rounded,
              title: 'Aucun bon ce matin',
              subtitle:
                  'Les bons générés entre 00:00 et 12:00 apparaîtront ici.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _morningOrders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = _morningOrders[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      order.supplier.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${order.purchaseOrder.ref} • ${Fmt.time(order.purchaseOrder.createdAt)}',
                    ),
                    trailing: Text(
                      Fmt.currency(order.purchaseOrder.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
