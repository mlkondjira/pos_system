import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/database/pos_database.dart';

class PurchaseOrderForm extends StatefulWidget {
  const PurchaseOrderForm({super.key});

  @override
  State<PurchaseOrderForm> createState() => _PurchaseOrderFormState();
}

class _PurchaseOrderFormState extends State<PurchaseOrderForm> {
  Supplier? _selectedSupplier;
  final List<Map<String, dynamic>> _items =
      []; // {product: Product, qty: int, unitCost: double}
  bool _isSaving = false;

  double get _totalAmount =>
      _items.fold(0, (sum, item) => sum + (item['qty'] * item['unitCost']));

  void _addProduct(Product product) {
    setState(() {
      final index = _items.indexWhere(
        (i) => (i['product'] as Product).id == product.id,
      );
      if (index >= 0) {
        _items[index]['qty']++;
      } else {
        _items.add({
          'product': product,
          'qty': 1,
          'unitCost': product.costPrice ?? 0.0,
        });
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedSupplier == null || _items.isEmpty) return;

    setState(() => _isSaving = true);
    final db = context.read<PosDatabase>();
    final shopId = await db.getSetting('shop_id') ?? '';
    final terminalId = await db.getSetting('terminal_id') ?? ''; // ADDED

    try {
      await db.createPurchaseOrder(
        supplierId: _selectedSupplier!.id,
        shopId: shopId,
        terminalId: terminalId, // ADDED
        items: _items
            .map(
              (i) => {
                'productId': (i['product'] as Product).id,
                'qty': i['qty'] as int,
                'unitCost': i['unitCost'] as double,
              },
            )
            .toList(),
      );
      if (mounted) Navigator.pop(context, true);
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<PosDatabase>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Nouvelle Commande Fournisseur',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Section Fournisseur
          _buildSupplierSelector(db),
          const Divider(height: 1),

          // Barre de recherche de produits
          _buildProductSearch(db),

          // Liste des articles
          Expanded(
            child: _items.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildItemTile(index),
                  ),
          ),

          // Résumé bas de page
          if (_items.isNotEmpty) _buildSummaryBar(),
        ],
      ),
    );
  }

  Widget _buildSupplierSelector(PosDatabase db) {
    return FutureBuilder<String?>(
      future: db.getSetting('shop_id'),
      builder: (context, shopSnap) {
        return FutureBuilder<List<Supplier>>(
          future: db.getSuppliers(shopSnap.data ?? ''),
          builder: (context, snapshot) {
            final suppliers = snapshot.data ?? [];
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<Supplier>(
                initialValue: _selectedSupplier,
                decoration: const InputDecoration(
                  labelText: 'Sélectionner un fournisseur',
                  prefixIcon: Icon(Icons.business),
                ),
                items: suppliers
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedSupplier = val),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductSearch(PosDatabase db) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchAnchor(
        builder: (context, controller) => SearchBar(
          controller: controller,
          hintText: 'Ajouter un produit à la commande...',
          leading: const Icon(
            Icons.add_circle_outline,
            color: AppColors.primary,
          ),
          onTap: () => controller.openView(),
        ),
        suggestionsBuilder: (context, controller) async {
          final products = await db.searchProducts(controller.text);
          return products.map(
            (p) => ListTile(
              title: Text(p.name),
              subtitle: Text('Stock actuel: ${p.stockQty} ${p.unit}'),
              trailing: Text(Fmt.currency(p.priceHt)),
              onTap: () {
                _addProduct(p);
                controller.closeView(null);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemTile(int index) {
    final item = _items[index];
    final product = item['product'] as Product;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'P.U. Achat: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: item['unitCost'].toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        onChanged: (v) => setState(
                          () => _items[index]['unitCost'] =
                              double.tryParse(v) ?? 0.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(() {
                  if (_items[index]['qty'] > 1) _items[index]['qty']--;
                }),
              ),
              Text(
                '${item['qty']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _items[index]['qty']++),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => setState(() => _items.removeAt(index)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL DE LA COMMANDE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                Fmt.currency(_totalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Text(
            '${_items.length} articles',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_checkout_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun produit dans la commande',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
