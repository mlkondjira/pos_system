import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart'; // Added for firstWhereOrNull
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import 'package:pos_system/presentation/blocs/auth_bloc.dart'; // Corrected import

class DiscountFormDialog extends StatefulWidget {
  final Discount? discount; // Null for new, object for edit
  const DiscountFormDialog({super.key, this.discount});

  @override
  State<DiscountFormDialog> createState() => _DiscountFormDialogState();
}

class _DiscountFormDialogState extends State<DiscountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _db = getIt<PosDatabase>();
  bool _loading = false;

  // Form fields
  late TextEditingController _nameCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _minAmountCtrl;
  String _type = 'percentage'; // 'percentage' or 'fixed'
  bool _isActive = true;
  bool _isArchived = false;
  bool _isStackable = false;
  bool _limitPerCustomer = false;
  int? _usageLimit;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _priority;

  // Rule-specific fields (parsed from JSON)
  Map<String, dynamic> _rules = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.discount?.name ?? '');
    _valueCtrl = TextEditingController(
      text: widget.discount?.value.toStringAsFixed(2) ?? '0.00',
    );
    _minAmountCtrl = TextEditingController(
      text: widget.discount?.minAmount.toStringAsFixed(2) ?? '0.00',
    );
    _type = widget.discount?.type ?? 'percentage';
    _isActive = widget.discount?.isActive ?? true;
    _isArchived = widget.discount?.isArchived ?? false;
    _isStackable = widget.discount?.isStackable ?? false;
    _limitPerCustomer = widget.discount?.limitPerCustomer ?? false;
    _usageLimit = widget.discount?.usageLimit;
    _startDate = widget.discount?.startDate;
    _endDate = widget.discount?.endDate;
    _priority = widget.discount?.priority;

    if (widget.discount?.rules != null) {
      try {
        _rules = jsonDecode(widget.discount!.rules!);
      } catch (e) {
        debugPrint('Error parsing discount rules JSON: $e');
        _rules = {};
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _minAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDiscount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final authBloc = context.read<AuthBloc>();
    try {
      final shopId = await _db.getSetting('shop_id') ?? '';
      final actorId = authBloc.state.user?.id;

      if (actorId == null) {
        throw Exception('Utilisateur non authentifié.');
      }

      final companion = DiscountsCompanion(
        id: widget.discount != null
            ? Value(widget.discount!.id)
            : const Value.absent(),
        shopId: Value(shopId),
        name: Value(_nameCtrl.text.trim()),
        type: Value(_type),
        value: Value(double.parse(_valueCtrl.text)),
        minAmount: Value(double.parse(_minAmountCtrl.text)),
        isActive: Value(_isActive),
        isArchived: Value(_isArchived),
        isStackable: Value(_isStackable),
        limitPerCustomer: Value(_limitPerCustomer),
        usageLimit: Value(_usageLimit),
        startDate: Value(_startDate),
        endDate: Value(_endDate),
        priority: Value(_priority ?? 0),
        rules: Value(
          jsonEncode(_rules.isEmpty ? null : _rules),
        ), // Save rules as JSON string
      );

      await _db.upsertDiscount(companion);

      if (mounted) {
        Navigator.pop(context, true); // Indicate success
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildRuleSpecificFields() {
    switch (_rules['type']) {
      case 'bxgy':
        return Column(
          children: [
            TextFormField(
              initialValue: (_rules['buy_qty'] ?? '').toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Achetez X quantités',
              ),
              onChanged: (v) => _rules['buy_qty'] = int.tryParse(v),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Quantité invalide'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: (_rules['get_qty'] ?? '').toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Obtenez Y quantités gratuites',
              ),
              onChanged: (v) => _rules['get_qty'] = int.tryParse(v),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Quantité invalide'
                  : null,
            ),
            const SizedBox(height: 16),
            // Optionnel: cibler un produit spécifique pour BXGY
            _buildProductSelector(
              label: 'Produit ciblé (optionnel)',
              initialProductId: _rules['product_id'] as int?,
              onProductSelected: (p) => _rules['product_id'] = p?.id,
            ),
          ],
        );
      case 'happy_hour':
        return Column(
          children: [
            TextFormField(
              initialValue: (_rules['start_hour'] ?? '').toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Heure de début (0-23)',
              ),
              onChanged: (v) => _rules['start_hour'] = int.tryParse(v),
              validator: (v) {
                final hour = int.tryParse(v ?? '');
                return hour == null || hour < 0 || hour > 23
                    ? 'Heure invalide'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: (_rules['end_hour'] ?? '').toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Heure de fin (0-23)',
              ),
              onChanged: (v) => _rules['end_hour'] = int.tryParse(v),
              validator: (v) {
                final hour = int.tryParse(v ?? '');
                return hour == null || hour < 0 || hour > 23
                    ? 'Heure invalide'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: (_rules['pct'] ?? '').toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pourcentage de remise (%)',
              ),
              onChanged: (v) => _rules['pct'] = double.tryParse(v),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Pourcentage invalide'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildCategorySelector(
              label: 'Catégorie ciblée (optionnel)',
              initialCategoryId: _rules['category_id'] as int?,
              onCategorySelected: (c) => _rules['category_id'] = c?.id,
            ),
          ],
        );
      case 'expiry_near':
        return Column(
          children: [
            TextFormField(
              initialValue: (_rules['days'] ?? '7').toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Appliquer si expire dans (jours)',
              ),
              onChanged: (v) => _rules['days'] = int.tryParse(v),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Nombre de jours invalide'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: (_rules['pct'] ?? '').toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pourcentage de remise (%)',
              ),
              onChanged: (v) => _rules['pct'] = double.tryParse(v),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Pourcentage invalide'
                  : null,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCategorySelector({
    required String label,
    int? initialCategoryId,
    required Function(Category?) onCategorySelected,
  }) {
    return StreamBuilder<List<Category>>(
      stream: _db.select(_db.categories).watch(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        return DropdownButtonFormField<int?>(
          initialValue: initialCategoryId,
          decoration: InputDecoration(labelText: label),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Toutes les catégories'),
            ),
            ...categories.map(
              (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
            ),
          ],
          onChanged: (val) {
            onCategorySelected(categories.firstWhereOrNull((c) => c.id == val));
          },
        );
      },
    );
  }

  Widget _buildProductSelector({
    required String label,
    int? initialProductId,
    required Function(Product?) onProductSelected,
  }) {
    // Pour un sélecteur de produit, on pourrait utiliser un Autocomplete ou un dialogue de recherche
    // Pour simplifier, on va juste afficher le nom du produit si un ID est déjà sélectionné
    // et fournir un bouton pour ouvrir un dialogue de sélection de produit.
    return FutureBuilder<Product?>(
      future: initialProductId != null
          ? (_db.select(
              _db.products,
            )..where((p) => p.id.equals(initialProductId))).getSingleOrNull()
          : Future.value(null),
      builder: (context, snapshot) {
        final selectedProduct = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedProduct?.name ?? 'Aucun produit sélectionné',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      final Product? product = await showDialog<Product>(
                        context: context,
                        builder: (ctx) => _ProductSelectionDialog(),
                      );
                      if (product != null) {
                        setState(() {
                          onProductSelected(product);
                        });
                      }
                    },
                  ),
                  if (selectedProduct != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          onProductSelected(null);
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, // Ligne 244
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ), // Ligne 244
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.discount == null
                        ? 'Nouvelle Promotion'
                        : 'Modifier Promotion',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la promotion',
                    ),
                    validator: (v) => v!.isEmpty ? 'Le nom est requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Type de remise',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Pourcentage (%)'),
                      ),
                      DropdownMenuItem(
                        value: 'fixed',
                        child: Text('Montant fixe'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Valeur de la remise',
                      suffixText: _type == 'percentage' ? '%' : 'FCFA',
                    ),
                    validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                        ? 'Valeur invalide'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant minimum du panier',
                      suffixText: 'FCFA',
                    ),
                    validator: (v) => (double.tryParse(v ?? '') ?? 0) < 0
                        ? 'Montant invalide'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Date de début',
                          value: _startDate,
                          onChanged: (date) =>
                              setState(() => _startDate = date),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Date de fin',
                          value: _endDate,
                          onChanged: (date) => setState(() => _endDate = date),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Promotion active'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Archivée (non visible)'),
                    value: _isArchived,
                    onChanged: (v) => setState(() => _isArchived = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Cumulable avec d\'autres promotions'),
                    value: _isStackable,
                    onChanged: (v) => setState(() => _isStackable = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Limitée à une utilisation par client'),
                    value: _limitPerCustomer,
                    onChanged: (v) => setState(() => _limitPerCustomer = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _usageLimit?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Limite d\'utilisation totale (optionnel)',
                    ),
                    onChanged: (v) => _usageLimit = int.tryParse(v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _priority?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Priorité (0 = faible, 100 = élevée)',
                    ),
                    onChanged: (v) => _priority = int.tryParse(v),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Règles avancées (JSON)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _rules['type'] as String?,
                    decoration: const InputDecoration(
                      labelText: 'Type de règle avancée',
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Aucune règle avancée'),
                      ),
                      DropdownMenuItem(
                        value: 'bxgy',
                        child: Text('Achetez X, Obtenez Y'),
                      ),
                      DropdownMenuItem(
                        value: 'happy_hour',
                        child: Text('Happy Hour'),
                      ),
                      DropdownMenuItem(
                        value: 'expiry_near',
                        child: Text('Proche Expiration'),
                      ),
                      // Ajoutez d'autres types de règles ici
                    ],
                    onChanged: (v) {
                      setState(() {
                        _rules = v == null ? {} : {'type': v};
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildRuleSpecificFields(), // Dynamic fields based on rule type
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _saveDiscount,
                          child: _loading
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date != null) onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value != null ? Fmt.date(value) : 'Choisir une date'),
      ),
    );
  }
}

// Simple Product Selection Dialog (Placeholder for a more complex search)
class _ProductSelectionDialog extends StatefulWidget {
  @override
  State<_ProductSelectionDialog> createState() =>
      _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  final _db = getIt<PosDatabase>();
  final _searchCtrl = TextEditingController();
  int? _selectedCategoryId; // Nouveau: pour le filtre par catégorie

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner un produit'),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nom ou code-barres',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (v) =>
                    setState(() {}), // Rebuild pour mettre à jour le stream
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: StreamBuilder<List<Category>>(
                stream: _db.select(_db.categories).watch(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  return DropdownButtonFormField<int?>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Filtrer par catégorie',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Toutes les catégories'),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _db.watchProducts(
                  query: _searchCtrl.text,
                  categoryId: _selectedCategoryId,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final products = snapshot.data!;
                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun produit trouvé pour cette recherche et catégorie.',
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: product.imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(product.imagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                        ),
                        title: Text(product.name),
                        subtitle: Text(Fmt.currency(product.priceTtc)),
                        onTap: () => Navigator.pop(context, product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
