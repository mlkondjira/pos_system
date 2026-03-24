import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/pos_database.dart';

class CreateTransferScreen extends StatefulWidget {
  const CreateTransferScreen({super.key});

  @override
  State<CreateTransferScreen> createState() => _CreateTransferScreenState();
}

class _CreateTransferScreenState extends State<CreateTransferScreen> {
  final _db = getIt<PosDatabase>();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();

  String? _sourceShopId;
  String? _targetShopId;
  List<Shop> _otherShops = [];
  final List<StockTransferItemWithProduct> _itemsToTransfer = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final myShopId = await _db.getSetting('shop_id');
    if (myShopId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Magasin actuel non configuré.'), backgroundColor: AppColors.danger));
        Navigator.pop(context);
      }
      return;
    }
    final shops = await _db.getOtherShops(myShopId);
    setState(() {
      _sourceShopId = myShopId;
      _otherShops = shops;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addProduct(Product product) {
    if (product.stockQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock insuffisant pour ce produit.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    final existingIndex = _itemsToTransfer.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      _updateQuantity(product.id, 1);
    } else {
      setState(() {
        _itemsToTransfer.add(
          StockTransferItemWithProduct(
            item: StockTransferItem(
              id: -1, // Dummy ID, not used
              productId: product.id,
              quantitySent: 1,
              transferId: -1, // ID factice, non utilisé
            ),
            product: product,
          ),
        );
      });
      // Animation d'insertion
      _listKey.currentState?.insertItem(_itemsToTransfer.length - 1);
    }
  }

  void _updateQuantity(int productId, int delta) {
    final index = _itemsToTransfer.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      final item = _itemsToTransfer[index];
      final newQty = item.item.quantitySent + delta;

      // Vérification du stock disponible
      if (delta > 0 && newQty > item.product.stockQty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantité insuffisante en stock (Max: ${item.product.stockQty})'), backgroundColor: AppColors.warning),
        );
        return;
      }

      if (newQty > 0) {
        setState(() {
          _itemsToTransfer[index] = StockTransferItemWithProduct(
            item: item.item.copyWith(quantitySent: newQty),
            product: item.product,
          );
        });
      } else {
        // Suppression avec animation
        final removedItem = _itemsToTransfer[index];
        _itemsToTransfer.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _buildItemTile(removedItem, animation: animation),
        );
        setState(() {}); // Pour mettre à jour l'état vide si nécessaire
      }
    }
  }

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itemsToTransfer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez ajouter au moins un produit.'), backgroundColor: AppColors.warning));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final itemsPayload = _itemsToTransfer.map((item) {
        return {'productId': item.product.id, 'qty': item.item.quantitySent};
      }).toList();

      await _db.createStockTransfer(
        sourceShopId: _sourceShopId!,
        targetShopId: _targetShopId!,
        items: itemsPayload,
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfert créé avec succès.'), backgroundColor: AppColors.success));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Transfert'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _targetShopId,
                            decoration: const InputDecoration(
                              labelText: 'Magasin de destination',
                              prefixIcon: Icon(Icons.store_mall_directory_outlined),
                            ),
                            items: _otherShops.map((shop) {
                              return DropdownMenuItem(
                                value: shop.id,
                                child: Text(shop.name),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _targetShopId = value),
                            validator: (v) => v == null ? 'Veuillez choisir une destination' : null,
                          ),
                          const SizedBox(height: 24),
                          Text('Produits à transférer', style: Theme.of(context).textTheme.titleMedium),
                          const Divider(height: 20),
                          if (_itemsToTransfer.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32.0),
                                child: Text('Aucun produit ajouté.', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverAnimatedList(
                      key: _listKey,
                      initialItemCount: _itemsToTransfer.length,
                      itemBuilder: (context, index, animation) {
                        if (index >= _itemsToTransfer.length) return const SizedBox.shrink();
                        return _buildItemTile(_itemsToTransfer[index], animation: animation);
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showProductSearch,
                                  icon: const Icon(Icons.search),
                                  label: const Text('Rechercher'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _scanBarcode,
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Scanner'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _notesCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optionnel)',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _submitTransfer,
        label: const Text('Valider le transfert'),
        icon: const Icon(Icons.check_circle_outline),
        backgroundColor: _isLoading ? Colors.grey : AppColors.primary,
      ),
    );
  }

  Widget _buildItemTile(StockTransferItemWithProduct item, {Animation<double>? animation}) {
    Widget child = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Image / Icône Produit
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.product.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(item.product.imagePath!), fit: BoxFit.cover),
                  )
                : const Icon(Icons.inventory_2_outlined, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'En stock : ${item.product.stockQty}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          // Contrôle Quantité Pill
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _qtyBtn(Icons.remove, () => _updateQuantity(item.product.id, -1)),
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.item.quantitySent}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _qtyBtn(Icons.add, () => _updateQuantity(item.product.id, 1)),
              ],
            ),
          ),
        ],
      ),
    );

    if (animation != null) {
      return SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(opacity: animation, child: child),
      );
    }

    return child;
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Scanner un produit')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
        ),
      ),
    );

    if (barcode == null) return;

    final product = await _db.getProductByBarcode(barcode);

    if (!mounted) return;

    if (product != null) {
      _addProduct(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ajouté : ${product.name}'), backgroundColor: AppColors.success, duration: const Duration(milliseconds: 1500)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit inconnu.'), backgroundColor: AppColors.warning),
      );
    }
  }

  void _showProductSearch() async {
    final Product? selectedProduct = await showDialog(
      context: context,
      builder: (_) => const _ProductSearchDialog(),
    );

    if (selectedProduct != null) {
      _addProduct(selectedProduct);
    }
  }
}

class _ProductSearchDialog extends StatefulWidget {
  const _ProductSearchDialog();

  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
  final _db = getIt<PosDatabase>();
  final _searchCtrl = TextEditingController();
  List<Product> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (_searchCtrl.text.length > 1) {
        _performSearch();
      } else {
        setState(() => _results = []);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    final results = await _db.searchProducts(_searchCtrl.text);
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechercher un produit'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nom ou code-barres',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_results.isEmpty && _searchCtrl.text.isNotEmpty)
              const Text('Aucun produit trouvé.')
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final product = _results[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('Stock: ${product.stockQty}'),
                      onTap: () {
                        Navigator.pop(context, product);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
      ],
    );
  }
}