// lib/presentation/screens/produits/product_form.dart
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/pos_database.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final PosDatabase db;

  const ProductForm({super.key, this.product, required this.db});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _alertCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _unit = 'pce';
  double _taxRate = 0.0;
  int? _categoryId;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  List<Category> _categories = [];
  bool _saving = false;

  static const _units = [
    'pce', 'kg', 'g', 'l', 'ml', 'm', 'cm',
    'sac', 'btl', 'pck', 'bte', 'doz',
  ];

  static const _taxRates = [
    (0.0, '0% — Exonéré'),
    (0.05, '5%'),
    (0.10, '10%'),
    (0.18, '18% — TVA standard'),
    (0.20, '20%'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p.name;
      _barcodeCtrl.text = p.barcode ?? '';
      _priceCtrl.text = p.priceHt.toStringAsFixed(0);
      _costCtrl.text = p.costPrice.toStringAsFixed(0);
      _stockCtrl.text = p.stockQty.toString();
      _alertCtrl.text = p.stockAlert.toString();
      _descCtrl.text = p.description;
      _unit = p.unit;
      _taxRate = p.taxRate;
      _categoryId = p.categoryId;
      _imagePath = p.imagePath;
    } else {
      _stockCtrl.text = '0';
      _alertCtrl.text = '5';
    }
  }

  Future<void> _loadCategories() async {
    final cats = await widget.db.select(widget.db.categories).get();
    setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _alertCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scanner un code-barres'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull?.rawValue;
                if (barcode != null) {
                  Navigator.pop(ctx, barcode);
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );

    if (code != null) {
      setState(() => _barcodeCtrl.text = code);
    }
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Erreur lors de la suppression du fichier: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 800);
      if (image != null) {
        final String? previousPath = _imagePath;

        // 1. Obtenir le dossier permanent des documents de l'application
        final directory = await getApplicationDocumentsDirectory();
        final String path = p.join(directory.path, 'product_images');
        
        // 2. Créer le dossier s'il n'existe pas encore
        final Directory dir = Directory(path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        // 3. Préparer le nouveau nom de fichier unique (img_timestamp.extension)
        final String extension = p.extension(image.path);
        final String fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}$extension';
        final String localPath = p.join(path, fileName);

        // 4. Copier le fichier du cache vers le dossier permanent
        final File savedImage = await File(image.path).copy(localPath);

        // Nettoyage : si on avait déjà choisi une image durant cette session, on la supprime
        if (previousPath != null && previousPath != widget.product?.imagePath) {
          await _deleteFile(previousPath);
        }

        setState(() => _imagePath = savedImage.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la capture : $e')),
        );
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Appareil photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.danger),
                title: const Text('Supprimer la photo', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _imagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Form(
          key: _formKey,
          child: ListView(controller: ctrl, children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              widget.product == null
                  ? 'Nouveau produit'
                  : 'Modifier — ${widget.product!.name}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // ── Photo du produit ─────────────
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                          )
                        : const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted, size: 32),
                  ),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: IconButton(
                      onPressed: _showImageSourceActionSheet,
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Nom ──────────────────────────
            _label('Nom du produit *'),
            _field(_nameCtrl, 'Ex: Riz parfumé 5kg',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ requis' : null),
            const SizedBox(height: 14),

            // ── Code-barres ──────────────────
            _label('Code-barres'),
            TextFormField(
              controller: _barcodeCtrl,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'EAN-13, QR, code interne...',
                hintStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner,
                      size: 18, color: AppColors.primaryLight),
                  onPressed: _openScanner,
                  tooltip: 'Scanner un code-barres',
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Prix ─────────────────────────
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Prix de vente HT *'),
                  _field(_priceCtrl, '0',
                      keyboard: TextInputType.number,
                      validator: (v) =>
                          double.tryParse(v ?? '') == null
                              ? 'Nombre requis'
                              : null),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label("Prix d'achat"),
                  _field(_costCtrl, '0',
                      keyboard: TextInputType.number),
                ],
              )),
            ]),
            const SizedBox(height: 14),

            // ── Taxe ─────────────────────────
            _label('Taux de taxe (TVA)'),
            DropdownButtonFormField<double>(
              initialValue: _taxRate,
              dropdownColor: AppColors.card,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(),
              items: _taxRates
                  .map((t) => DropdownMenuItem(
                      value: t.$1,
                      child: Text(t.$2,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _taxRate = v ?? 0),
            ),
            const SizedBox(height: 14),

            // ── Stock ─────────────────────────
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Stock initial'),
                  _field(_stockCtrl, '0',
                      keyboard: TextInputType.number),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label("Seuil d'alerte"),
                  _field(_alertCtrl, '5',
                      keyboard: TextInputType.number),
                ],
              )),
            ]),
            const SizedBox(height: 14),

            // ── Unité ─────────────────────────
            _label('Unité de mesure'),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              dropdownColor: AppColors.card,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(),
              items: _units
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => setState(() => _unit = v ?? 'pce'),
            ),
            const SizedBox(height: 14),

            // ── Catégorie ─────────────────────
            _label('Catégorie'),
            DropdownButtonFormField<int?>(
              initialValue: _categoryId,
              dropdownColor: AppColors.card,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(),
              items: [
                const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sans catégorie')),
                ..._categories.map((c) => DropdownMenuItem<int?>(
                    value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 14),

            // ── Description ───────────────────
            _label('Description (optionnel)'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Notes sur le produit...',
                hintStyle: TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),

            // ── Boutons ───────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            )),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final String? originalPath = widget.product?.imagePath;

    try {
      final companion = ProductsCompanion(
        id: widget.product != null
            ? Value(widget.product!.id)
            : const Value.absent(),
        name: Value(_nameCtrl.text.trim()),
        barcode: Value(_barcodeCtrl.text.isEmpty
            ? null
            : _barcodeCtrl.text.trim()),
        priceHt: Value(double.parse(_priceCtrl.text)),
        costPrice: Value(double.tryParse(_costCtrl.text) ?? 0),
        taxRate: Value(_taxRate),
        stockQty: Value(int.tryParse(_stockCtrl.text) ?? 0),
        stockAlert: Value(int.tryParse(_alertCtrl.text) ?? 5),
        unit: Value(_unit),
        categoryId: Value(_categoryId),
        imagePath: Value(_imagePath),
        description: Value(_descCtrl.text.trim()),
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      );

      await widget.db
          .into(widget.db.products)
          .insertOnConflictUpdate(companion);

      // Si le chemin a changé, on supprime l'ancien fichier d'origine
      if (originalPath != null && originalPath != _imagePath) {
        await _deleteFile(originalPath);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }
}
