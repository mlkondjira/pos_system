// lib/presentation/screens/produits/produits_screen.dart
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import '../../blocs/auth_bloc.dart';
import 'product_form.dart';

class ProduitsScreen extends StatefulWidget {
  const ProduitsScreen({super.key});

  @override
  State<ProduitsScreen> createState() => _ProduitsScreenState();
}

class _ProduitsScreenState extends State<ProduitsScreen>
    with SingleTickerProviderStateMixin {
  final _db = getIt<PosDatabase>();
  final _searchCtrl = TextEditingController();
  late TabController _tab;
  String _search = '';
  int? _categoryId;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await _db.select(_db.categories).get();
    setState(() => _categories = cats);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildHeader(),
      TabBar(
        controller: _tab,
        tabs: const [
          Tab(text: 'Catalogue'),
          Tab(text: 'Alertes stock'),
        ],
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primaryLight,
        indicatorWeight: 2,
      ),
      Expanded(
        child: TabBarView(
          controller: _tab,
          children: [
            _CatalogTab(
              db: _db,
              search: _search,
              categoryId: _categoryId,
              categories: _categories,
              onCategoryChanged: (id) => setState(() => _categoryId = id),
              onEdit: _openForm,
              onDelete: _confirmDelete,
              onAdjustStock: _adjustStock,
            ),
            _LowStockTab(db: _db, onRestock: _adjustStock),
          ],
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      color: AppColors.surface,
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 18),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: 16, color: AppColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      })
                  : null,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => _openForm(null),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nouveau'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
      ]),
    );
  }

  void _openForm(Product? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductForm(product: product, db: _db),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Supprimer "${product.name}" ? '
            'Il sera masqué du catalogue mais ses ventes seront conservées.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await (_db.update(_db.products)
                    ..where((p) => p.id.equals(product.id)))
                  .write(const ProductsCompanion(isActive: Value(false)));
              if (mounted) Navigator.pop(context);
            },
            onLongPress: () async {
              if (product.imagePath != null) {
                final file = File(product.imagePath!);
                if (await file.exists()) await file.delete();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _adjustStock(Product product) {
    final ctrl = TextEditingController(text: '0');
    bool isEntry = true;
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Stock — ${product.name}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Stock actuel',
                      style: TextStyle(color: AppColors.info, fontSize: 13)),
                  Text('${product.stockQty} ${product.unit}',
                      style: const TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _typeBtn('Entrée', true, isEntry,
                    () => setDlg(() => isEntry = true)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _typeBtn('Sortie', false, !isEntry,
                    () => setDlg(() => isEntry = false)),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                  labelText: 'Quantité', hintText: '0'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                  labelText: 'Motif (optionnel)',
                  hintText: 'Livraison fournisseur, casse...'),
            ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final user = ctx.read<AuthBloc>().state.user;
                if (user == null) return;

                final qty = int.tryParse(ctrl.text) ?? 0;
                if (qty <= 0) return;
                final delta = isEntry ? qty : -qty;
                final newQty = product.stockQty + delta;
                await _db.updateStock(
                    product.id, newQty < 0 ? 0 : newQty);
                await _db.into(_db.stockMovements).insert(
                      StockMovementsCompanion(
                        productId: Value(product.id),
                        userId: Value(user.id),
                        type: Value(isEntry ? 'purchase' : 'adjustment'),
                        qtyDelta: Value(delta),
                        qtyAfter: Value(newQty < 0 ? 0 : newQty),
                        reason: Value(reasonCtrl.text.isNotEmpty
                            ? reasonCtrl.text
                            : (isEntry ? 'Entrée stock' : 'Ajustement stock')),
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(
      String label, bool isIn, bool selected, VoidCallback onTap) {
    final color = isIn ? AppColors.success : AppColors.danger;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
              isIn
                  ? Icons.add_circle_outline
                  : Icons.remove_circle_outline,
              size: 16,
              color: selected ? color : AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                color: selected ? color : AppColors.textMuted,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              )),
        ]),
      ),
    );
  }
}

// ── ONGLET CATALOGUE ──────────────────────────────────────────
class _CatalogTab extends StatelessWidget {
  final PosDatabase db;
  final String search;
  final int? categoryId;
  final List<Category> categories;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;
  final ValueChanged<Product> onAdjustStock;

  const _CatalogTab({
    required this.db,
    required this.search,
    required this.categoryId,
    required this.categories,
    required this.onCategoryChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (categories.isNotEmpty)
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _CatChip(
                label: 'Tout',
                selected: categoryId == null,
                onTap: () => onCategoryChanged(null),
              ),
              ...categories.map((c) => _CatChip(
                    label: c.name,
                    selected: categoryId == c.id,
                    color: _parseColor(c.color),
                    onTap: () => onCategoryChanged(c.id),
                  )),
            ],
          ),
        ),
      Expanded(
        child: StreamBuilder<List<Product>>(
          // CORRECTION : watchProducts(query:, categoryId:) au lieu de
          // watchActiveProducts(query:, categoryId:)
          stream: db.watchProducts(
            query: search,
            categoryId: categoryId,
          ),
          builder: (ctx, snap) {
            final products = snap.data ?? [];
            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      search.isNotEmpty
                          ? 'Aucun résultat pour "$search"'
                          : 'Aucun produit dans le catalogue',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) => _ProductTile(
                product: products[i],
                onEdit: () => onEdit(products[i]),
                onDelete: () => onDelete(products[i]),
                onAdjust: () => onAdjustStock(products[i]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primaryLight;
    }
  }
}

// ── ONGLET ALERTES STOCK ──────────────────────────────────────
class _LowStockTab extends StatelessWidget {
  final PosDatabase db;
  final ValueChanged<Product> onRestock;

  const _LowStockTab({required this.db, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: db.watchLowStockProducts(),
      builder: (ctx, snap) {
        final products = snap.data ?? [];
        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 48, color: AppColors.success),
                SizedBox(height: 12),
                Text('Tous les stocks sont au beau fixe !',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) => _LowStockTile(
            product: products[i],
            onRestock: () => onRestock(products[i]),
          ),
        );
      },
    );
  }
}

// ── PRODUCT TILE ──────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAdjust;

  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final priceTtc = product.priceHt * (1 + product.taxRate);
    final isLow = product.stockQty <= product.stockAlert;
    final isOut = product.stockQty <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOut
              ? AppColors.danger.withValues(alpha: 0.35)
              : isLow
                  ? AppColors.warning.withValues(alpha: 0.35)
                  : AppColors.border,
        ),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: (product.imagePath != null && product.imagePath!.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(product.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image_outlined,
                          color: AppColors.textMuted, size: 22);
                    },
                  ),
                )
              : const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [
                    if (product.barcode != null) product.barcode!,
                    Fmt.currency(priceTtc),
                  ].join(' · '),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _StockBadge(
              qty: product.stockQty,
              unit: product.unit,
              alert: product.stockAlert),
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _iconBtn(Icons.tune_rounded, onAdjust, AppColors.warning),
            _iconBtn(Icons.edit_outlined, onEdit, AppColors.info),
            _iconBtn(Icons.delete_outline, onDelete, AppColors.danger),
          ]),
        ]),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, Color color) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
        ),
      );
}

// ── LOW STOCK TILE ────────────────────────────────────────────
class _LowStockTile extends StatelessWidget {
  final Product product;
  final VoidCallback onRestock;

  const _LowStockTile({required this.product, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    final isOut = product.stockQty <= 0;
    final color = isOut ? AppColors.danger : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isOut
                ? Icons.remove_shopping_cart_outlined
                : Icons.warning_amber_outlined,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Text(
                  isOut
                      ? 'En rupture de stock'
                      : 'Stock: ${product.stockQty} ${product.unit} '
                          '(seuil: ${product.stockAlert})',
                  style: TextStyle(color: color, fontSize: 11),
                ),
              ]),
        ),
        OutlinedButton.icon(
          onPressed: onRestock,
          icon: const Icon(Icons.add_rounded, size: 14),
          label: const Text('Réappro'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.success,
            side: const BorderSide(color: AppColors.success, width: 0.8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ]),
    );
  }
}

// ── STOCK BADGE ───────────────────────────────────────────────
class _StockBadge extends StatelessWidget {
  final int qty;
  final String unit;
  final int alert;

  const _StockBadge(
      {required this.qty, required this.unit, required this.alert});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (qty <= 0) {
      color = AppColors.danger;
    } else if (qty <= alert) {
      color = AppColors.warning;
    } else {
      color = AppColors.success;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        qty <= 0 ? 'Rupture' : '$qty $unit',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── CATEGORY CHIP ─────────────────────────────────────────────
class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryLight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.18) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? c : AppColors.textSecondary,
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}