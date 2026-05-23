import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/services/printer_service.dart';

class LabelPrintingScreen extends StatefulWidget {
  const LabelPrintingScreen({super.key});

  @override
  State<LabelPrintingScreen> createState() => _LabelPrintingScreenState();
}

class _LabelPrintingScreenState extends State<LabelPrintingScreen> {
  final _db = getIt<PosDatabase>();
  final Map<int, int> _selectedItems = {}; // Map<ProductId, Copies>
  String _search = '';

  void _toggleSelection(Product p) {
    setState(() {
      if (_selectedItems.containsKey(p.id)) {
        _selectedItems.remove(p.id);
      } else {
        _selectedItems[p.id] = 1;
      }
    });
  }

  Future<void> _loadRecentPriceChanges(int days) async {
    // Récupérer les produits dont le prix a changé au cours de la période sélectionnée
    final since = DateTime.now().subtract(Duration(days: days));
    final changedProducts = await _db.getProductsWithRecentPriceChanges(since);
    final periodStr = days == 1 ? '24h' : '$days jours';

    if (changedProducts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aucun changement de prix récent ($periodStr)'),
            backgroundColor: AppColors.info,
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedItems.clear();
      for (var p in changedProducts) {
        _selectedItems[p.id] = 1;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${changedProducts.length} produit(s) ($periodStr) chargés.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _showPreview(Product p) async {
    final shopName = await _db.getSetting('shop_name') ?? 'Mon Magasin';
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aperçu de l\'étiquette'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LabelPreviewCard(
              shopName: shopName,
              name: p.name,
              price: p.priceHt * (1 + (p.taxRate ?? 0.0)),
              barcode: p.barcode,
            ),
            const SizedBox(height: 16),
            const Text(
              'Format standard: 60mm x 38mm',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _print() async {
    if (_selectedItems.isEmpty) return;

    final products = await _db.select(_db.products).get();
    final labelsData = _selectedItems.entries.map((e) {
      final p = products.firstWhere((prod) => prod.id == e.key);
      return {
        'name': p.name,
        'price': p.priceHt * (1 + (p.taxRate ?? 0.0)),
        'barcode': p.barcode ?? '',
        'copies': e.value,
      };
    }).toList();

    final success = await getIt<PrinterService>().printPriceLabels(labelsData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Impression lancée'
                : 'Erreur impression (vérifiez l\'imprimante)',
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Création d\'étiquettes'),
        actions: [
          if (_selectedItems.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _selectedItems.clear()),
              icon: const Icon(Icons.clear_all, color: AppColors.danger),
              label: const Text(
                'Vider',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          const SizedBox(width: 8),
          PopupMenuButton<int>(
            onSelected: _loadRecentPriceChanges,
            tooltip: 'Charger les changements de prix',
            offset: const Offset(0, 40),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Prix récents',
                    style: TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 1, child: Text('Dernières 24h')),
              const PopupMenuItem(value: 7, child: Text('Derniers 7 jours')),
              const PopupMenuItem(value: 30, child: Text('Derniers 30 jours')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _db.watchProducts(query: _search),
              builder: (context, snap) {
                final products = snap.data ?? [];
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    final isSelected = _selectedItems.containsKey(p.id);
                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(p),
                        activeColor: AppColors.primary,
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        Fmt.currency(p.priceHt * (1 + (p.taxRate ?? 0.0))),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_red_eye_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            onPressed: () => _showPreview(p),
                            tooltip: 'Aperçu',
                          ),
                          if (isSelected)
                            _buildQtyControl(p.id)
                          else
                            const Icon(
                              Icons.label_outline_rounded,
                              color: AppColors.textMuted,
                            ),
                        ],
                      ),
                      onTap: () => _toggleSelection(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _print,
                  icon: const Icon(Icons.print_rounded),
                  label: Text(
                    'Imprimer ${_selectedItems.length} type(s) d\'étiquettes',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildQtyControl(int productId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () {
              setState(() {
                if (_selectedItems[productId]! > 1) {
                  _selectedItems[productId] = _selectedItems[productId]! - 1;
                }
              });
            },
          ),
          Text(
            '${_selectedItems[productId]}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () {
              setState(() {
                _selectedItems[productId] = _selectedItems[productId]! + 1;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _LabelPreviewCard extends StatelessWidget {
  final String shopName;
  final String name;
  final double price;
  final String? barcode;

  const _LabelPreviewCard({
    required this.shopName,
    required this.name,
    required this.price,
    this.barcode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240, // Proportionnel à 60mm
      height: 152, // Proportionnel à 38mm
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            shopName.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            Fmt.currency(price),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          if (barcode != null && barcode!.isNotEmpty)
            Container(
              height: 30,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: const Center(
                child: Icon(Icons.reorder, color: Colors.black54),
              ),
            )
          else
            const SizedBox(height: 30),
        ],
      ),
    );
  }
}
