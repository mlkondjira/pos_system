// lib/presentation/screens/produits/produits_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import '../../blocs/auth_bloc.dart';
import '../../widgets/shared_widgets.dart';
import 'product_form.dart';
import 'label_printing_screen.dart';
import '../../widgets/app_background.dart';
import '../../widgets/product_widgets.dart';

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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            _buildHeader(),
            _buildKpiRow(),
            TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Catalogue complet'),
                Tab(text: 'Alertes & Ruptures'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
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
                    isDesktop: isDesktop,
                  ),
                  _LowStockTab(db: _db, onRestock: _adjustStock),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildKpiRow() {
    return StreamBuilder<List<Product>>(
      stream: _db.select(_db.products).watch(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final low = all
            .where((p) => p.stockQty <= p.stockAlert && p.stockQty > 0)
            .length;
        final out = all.where((p) => p.stockQty <= 0).length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _kpiCard('Total', '${all.length}', AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Alertes', '$low', AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Ruptures', '$out', AppColors.danger)),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(12), // Ligne 76
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _importCsv, // Appel de la nouvelle méthode
            icon: const Icon(Icons.upload_file_rounded, color: AppColors.info),
            tooltip: 'Importer des produits (CSV)',
            style: IconButton.styleFrom(
              // Ligne 200
              backgroundColor: AppColors.info.withValues(
                alpha: 0.1,
              ), // Ligne 200
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LabelPrintingScreen()),
            ),
            icon: const Icon(
              Icons.label_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Imprimer des étiquettes', // Ligne 219
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(
                alpha: 0.1,
              ), // Ligne 219
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
        ],
      ),
    );
  }

  Future<void> _importCsv() async {
    final shopId = await _db.getSetting('shop_id');
    if (shopId == null || shopId.isEmpty) {
      _showSnack(
        'Veuillez configurer le magasin avant d\'importer.',
        AppColors.danger,
      );
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) {
      _showSnack('Aucun fichier sélectionné.', AppColors.info);
      return;
    }

    final String? filePath = result.files.single.path;
    if (filePath == null) return;

    try {
      // Lecture des bytes pour gérer l'encodage plus souplement
      final bytes = await File(filePath).readAsBytes();
      // Tentative de décodage UTF-8, sinon repli sur Latin1 (Excel Windows)
      String csvString;
      try {
        csvString = utf8.decode(bytes);
      } catch (_) {
        csvString = latin1.decode(bytes);
      }

      // Détection automatique du séparateur (virgule ou point-virgule)
      final firstLine = csvString.split('\n').first;
      final separator = firstLine.contains(';') ? ';' : ',';

      final fields = CsvDecoder(
        fieldDelimiter: separator,
        dynamicTyping: false,
      ).convert(csvString);

      if (fields.isEmpty || fields.first.isEmpty) {
        _showSnack('Le fichier CSV est vide ou mal formaté.', AppColors.danger);
        return;
      }

      // Nettoyage des en-têtes (minuscules et sans espaces)
      final headers = fields.first
          .map((e) => e.toString().trim().toLowerCase())
          .toList();
      final dataRows = fields.sublist(1);

      final List<ProductsCompanion> productsToUpsert = [];
      int importedCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      for (final row in dataRows) {
        try {
          final Map<String, dynamic> rowMap = {};
          for (int i = 0; i < headers.length; i++) {
            if (i < row.length) {
              rowMap[headers[i]] = row[i]?.toString().trim();
            }
          }

          final name = rowMap['name'] ?? rowMap['nom'];
          final barcode = rowMap['barcode'] ?? rowMap['code_barres'];

          // Nettoyage des nombres (remplacement virgule par point pour le parseur)
          final priceStr = (rowMap['priceht'] ?? rowMap['prix_ht'] ?? '')
              .replaceAll(',', '.');
          final priceHt = double.tryParse(priceStr);

          final stockQty = int.tryParse(
            rowMap['stockqty'] ?? rowMap['stock'] ?? '',
          );
          final stockAlert = int.tryParse(rowMap['stockalert'] ?? '5');
          final unit = rowMap['unit'] ?? rowMap['unite'] ?? 'pce';
          final categoryName = rowMap['categoryname'] ?? rowMap['categorie'];

          if (name == null || name.isEmpty || priceHt == null) {
            errors.add('Ligne invalide (nom ou prix manquant): $row');
            errorCount++;
            continue;
          }

          int? categoryId;
          if (categoryName != null && categoryName.isNotEmpty) {
            categoryId = await _db.findOrCreateCategoryByName(
              categoryName,
              shopId,
            );
          }

          productsToUpsert.add(
            ProductsCompanion.insert(
              name: name,
              barcode: Value(barcode),
              priceHt: priceHt,
              stockQty: Value(stockQty ?? 0),
              stockAlert: Value(stockAlert ?? 5),
              unit: Value(unit),
              categoryId: Value<int?>(categoryId),
              shopId: Value(shopId),
            ),
          );
          importedCount++;
        } catch (e) {
          errors.add('Erreur à la ligne $row: $e');
          errorCount++;
        }
      }

      if (productsToUpsert.isNotEmpty) {
        await _db.batchUpsertProducts(productsToUpsert);
      }

      if (mounted) {
        if (errorCount == 0) {
          _showSnack(
            '$importedCount produits importés avec succès !',
            AppColors.success,
          );
        } else {
          _showSnack(
            '$importedCount produits importés, $errorCount erreurs. Voir les logs.',
            AppColors.warning,
          );
          for (var err in errors) {
            debugPrint('Erreur CSV: $err');
          }
        }
      }
    } catch (e) {
      _showSnack('Erreur lors de la lecture du fichier : $e', AppColors.danger);
    }
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
        content: Text(
          'Supprimer "${product.name}" ? ' // Ligne 174
          'Il sera masqué du catalogue mais ses ventes seront conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
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
          title: Text('Stock — ${product.name}'), // Ligne 211
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stock actuel',
                        style: TextStyle(color: AppColors.info, fontSize: 13),
                      ), // Ligne 224
                      Text(
                        '${product.stockQty} ${product.unit}',
                        style: const TextStyle(
                          color: AppColors.info, // Ligne 227
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _typeBtn(
                        'Entrée',
                        true,
                        isEntry,
                        () => setDlg(() => isEntry = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _typeBtn(
                        'Sortie',
                        false,
                        !isEntry,
                        () => setDlg(() => isEntry = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    hintText: '0',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonCtrl, // Ligne 265
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Motif (optionnel)',
                    hintText: 'Livraison fournisseur, casse...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = ctx.read<AuthBloc>().state.user;
                if (user == null) return;

                final qty = int.tryParse(ctrl.text) ?? 0;
                if (qty <= 0) return;
                final delta = isEntry ? qty : -qty;
                final newQty = product.stockQty + delta;
                await _db.updateStock(product.id, newQty < 0 ? 0 : newQty);
                await _db
                    .into(_db.stockMovements)
                    .insert(
                      StockMovementsCompanion(
                        productId: Value(product.id),
                        userId: Value(user.id),
                        type: Value(isEntry ? 'purchase' : 'adjustment'),
                        qtyDelta: Value(delta),
                        qtyAfter: Value(newQty < 0 ? 0 : newQty),
                        reason: Value(
                          reasonCtrl.text.isNotEmpty
                              ? reasonCtrl.text
                              : (isEntry ? 'Entrée stock' : 'Ajustement stock'),
                        ),
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

  Widget _typeBtn(String label, bool isIn, bool selected, VoidCallback onTap) {
    final color = isIn ? AppColors.success : AppColors.danger;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10), // Ligne 310
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.bg,
          borderRadius: BorderRadius.circular(8), // Ligne 310
          border: Border.all(
            color: selected ? color : AppColors.border.withValues(alpha: 0.8),
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
              size: 16,
              color: selected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
  final bool isDesktop;

  const _CatalogTab({
    required this.db,
    required this.search,
    required this.categoryId,
    required this.categories,
    required this.onCategoryChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjustStock,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: Center(
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                children: [
                  _CatChip(
                    label: 'Tout',
                    selected: categoryId == null,
                    onTap: () => onCategoryChanged(null),
                  ),
                  ...categories.map(
                    (c) => _CatChip(
                      label: c.name,
                      selected: categoryId == c.id,
                      color: _parseColor(c.color),
                      onTap: () => onCategoryChanged(c.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: db.watchProducts(query: search, categoryId: categoryId),
            builder: (ctx, snap) {
              final products = snap.data ?? [];
              if (products.isEmpty) {
                return const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun produit',
                  subtitle: 'Ajustez votre recherche ou ajoutez un article.',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop
                      ? 4
                      : (MediaQuery.of(ctx).size.width > 600 ? 3 : 2),
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) {
                  return _ProductCard(
                        product: products[i],
                        onEdit: () => onEdit(products[i]),
                        onDelete: () => onDelete(products[i]),
                        onAdjust: () => onAdjustStock(products[i]),
                      )
                      .animate(delay: (40 * i).ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        curve: Curves.easeOutBack,
                      );
                },
              );
            },
          ),
        ),
      ],
    );
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
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppColors.success,
                ),
                SizedBox(height: 12),
                Text(
                  'Tous les stocks sont au beau fixe !',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (_, i) => _LowStockTile(
            product: products[i],
            onRestock: () => onRestock(products[i]),
          ),
        );
      },
    );
  }
}

// ── PRODUCT CARD ──────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAdjust;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: product.isOutOfStock
              ? AppColors.danger.withValues(alpha: 0.3)
              : product.isLowStock
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ProductImage(
                    imagePath: product.imagePath,
                    borderRadius: 16,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: StockBadge(product: product),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Ligne 423
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                ProductPriceText(
                  product: product,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _iconBtn(Icons.tune_rounded, onAdjust, AppColors.warning),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.edit_outlined, onEdit, AppColors.info),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.delete_outline, onDelete, AppColors.danger),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, Color color) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12), // Plus large pour le tactile mobile
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color.withValues(alpha: 0.8)),
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
    final color = product.isOutOfStock ? AppColors.danger : AppColors.warning;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Ligne 501
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  product.isOutOfStock
                      ? Icons.remove_shopping_cart_rounded
                      : Icons.warning_amber_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.isOutOfStock
                          ? 'Rupture immédiate'
                          : 'Stock critique: ${product.stockQty} ${product.unit}',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onRestock,
                icon: const Icon(Icons.add_business_rounded, size: 14),
                label: const Text('Réapprovisionner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                  foregroundColor: AppColors.success,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? c.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c : Colors.white.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
