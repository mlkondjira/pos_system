import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../blocs/auth_bloc.dart';
import '../../widgets/shared_widgets.dart';

class CreatePurchaseOrderScreen extends StatefulWidget {
  /// ID du fournisseur à pré-sélectionner à l'ouverture de l'écran
  final int? initialSupplierId;

  const CreatePurchaseOrderScreen({super.key, this.initialSupplierId});

  @override
  State<CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState extends State<CreatePurchaseOrderScreen> {
  final _db = getIt<PosDatabase>();
  int? _selectedSupplierId;
  List<Supplier> _suppliers = [];
  final List<PurchaseOrderItemWithProduct> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedSupplierId = widget.initialSupplierId;
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final shopId = await _db.getSetting('shop_id') ?? '';
    final list = await _db.getSuppliers(shopId);
    setState(() {
      _suppliers = list;
      _isLoading = false;
    });
  }

  void _addProduct(Product product) {
    // AUTO-SÉLECTION : Si aucun fournisseur n'est sélectionné, on prend le fournisseur préférentiel du produit
    if (_selectedSupplierId == null && product.preferredSupplierId != null) {
      setState(() {
        _selectedSupplierId = product.preferredSupplierId;
      });
    }

    final existingIndex = _items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex != -1) {
      setState(() {
        final current = _items[existingIndex];
        _items[existingIndex] = PurchaseOrderItemWithProduct(
          product: product,
          item: current.item.copyWith(quantity: current.item.quantity + 1),
        );
      });
    } else {
      setState(() {
        _items.add(
          PurchaseOrderItemWithProduct(
            product: product,
            item: PurchaseOrderItem(
              id: -1,
              purchaseOrderId: -1,
              productId: product.id,
              quantity: 1,
              unitCost: product.costPrice ?? 0.0,
              lineTotal: product.costPrice ?? 0.0,
            ),
          ),
        );
      });
    }
  }

  void _editPrice(int index) async {
    final item = _items[index];
    final controller = TextEditingController(
      text: item.item.unitCost.toString(),
    );

    final double? newPrice = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier le prix : ${item.product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Prix d\'achat unitaire',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (newPrice != null && newPrice >= 0) {
      if (!mounted) return;
      setState(() {
        _items[index] = PurchaseOrderItemWithProduct(
          product: item.product,
          item: item.item.copyWith(unitCost: newPrice),
        );
      });
    }
  }

  void _editSellingPrice(int index) async {
    final item = _items[index];
    final product = item.product;
    final controller = TextEditingController(text: product.priceHt.toString());

    final double? newPrice = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Prix de vente : ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nouveau prix de vente (HT)',
            suffixText: 'FCFA',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );

    if (newPrice != null && newPrice >= 0) {
      if (!mounted) return;
      final user = context.read<AuthBloc>().state.user;
      if (user == null) return;

      try {
        // 1. Mise à jour locale du produit
        await (_db.update(
          _db.products,
        )..where((p) => p.id.equals(product.id))).write(
          ProductsCompanion(
            priceHt: Value(newPrice),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // 2. Audit & Sync
        final updatedProduct = await (_db.select(
          _db.products,
        )..where((p) => p.id.equals(product.id))).getSingle();
        await _db.enqueue(
          entityType: 'product',
          entityId: product.id,
          payload: updatedProduct.toJson(),
        );

        // 3. Mise à jour de l'état UI pour recalculer la marge immédiatement
        if (!mounted) return;
        setState(() {
          _items[index] = PurchaseOrderItemWithProduct(
            product: updatedProduct,
            item: item.item,
          );
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  double get _total =>
      _items.fold(0, (sum, i) => sum + (i.item.quantity * i.item.unitCost));
  double get _totalMargin => _items.fold(
    0,
    (sum, i) => sum + ((i.product.priceHt - i.item.unitCost) * i.item.quantity),
  );

  Future<void> _submit() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez un fournisseur')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ajoutez des produits')));
      return;
    }

    final shopId = await _db.getSetting('shop_id') ?? '';
    final terminalId = await _db.getSetting('terminal_id') ?? '';
    if (!mounted) return;

    await _db.createPurchaseOrder(
      supplierId: _selectedSupplierId!,
      shopId: shopId,
      terminalId: terminalId,
      items: _items
          .map(
            (i) => {
              'productId': i.product.id,
              'qty': i.item.quantity,
              'unitCost': i.item.unitCost,
            },
          )
          .toList(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commande créée'),
        backgroundColor: AppColors.success,
      ),
    );

    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commander')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Fournisseur',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: _suppliers
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSupplierId = val),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _items.isEmpty
                      ? const EmptyState(
                          icon: Icons.add_business,
                          title: 'Aucun produit dans la commande',
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final sellingPrice = item.product.priceHt;
                            final purchasePrice = item.item.unitCost;
                            final margin = sellingPrice - purchasePrice;
                            final marginPct = sellingPrice > 0
                                ? (margin / sellingPrice) * 100
                                : 0;
                            final marginColor = margin >= 0
                                ? AppColors.success
                                : AppColors.danger;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => _editPrice(index),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2.0,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Achat : ${Fmt.currency(purchasePrice)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.edit,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _editSellingPrice(index),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2.0,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Vente : ${Fmt.currency(sellingPrice)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.edit,
                                                  size: 10,
                                                  color: AppColors.textMuted,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: marginColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'Marge : ${marginPct.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: marginColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (item.item.quantity > 1) {
                                            _items[index] =
                                                PurchaseOrderItemWithProduct(
                                                  product: item.product,
                                                  item: item.item.copyWith(
                                                    quantity:
                                                        item.item.quantity - 1,
                                                  ),
                                                );
                                          } else {
                                            _items.removeAt(index);
                                          }
                                        });
                                      },
                                      color: AppColors.textMuted,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        '${item.item.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _items[index] =
                                              PurchaseOrderItemWithProduct(
                                                product: item.product,
                                                item: item.item.copyWith(
                                                  quantity:
                                                      item.item.quantity + 1,
                                                ),
                                              );
                                        });
                                      },
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                _buildBottomActions(),
              ],
            ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VALEUR COMMANDE',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                Fmt.currency(_total),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MARGE BRUTE EST.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                Fmt.currency(_totalMargin),
                style: TextStyle(
                  color: _totalMargin >= 0
                      ? AppColors.primary
                      : AppColors.danger,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showProductPicker,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('AJOUTER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bg,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text(
                    'CONFIRMER LA COMMANDE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProductPicker() async {
    final Product? selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choisir un produit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _db.watchActiveProducts(),
                builder: (context, snap) {
                  final products = snap.data ?? [];
                  if (products.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Catalogue vide',
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: AppColors.border.withValues(alpha: 0.5)),
                    itemBuilder: (ctx, i) => ListTile(
                      leading: ProductImage(
                        imagePath: products[i].imagePath,
                        size: 40,
                      ),
                      title: Text(
                        products[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        Fmt.currency(products[i].priceHt),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                      onTap: () => Navigator.pop(ctx, products[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) _addProduct(selected);
  }
}
