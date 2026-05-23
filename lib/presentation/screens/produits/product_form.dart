// lib/presentation/screens/produits/product_form.dart
import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
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
  DateTime? _expiryDate;
  final ImagePicker _picker = ImagePicker();
  List<Category> _categories = [];
  bool _saving = false;

  static const _units = [
    'pce',
    'kg',
    'g',
    'l',
    'ml',
    'm',
    'cm',
    'sac',
    'btl',
    'pck',
    'bte',
    'doz',
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
      _costCtrl.text = p.costPrice.toString();
      _alertCtrl.text = p.stockAlert.toString();
      _descCtrl.text = p.description ?? '';
      _unit = p.unit;
      _categoryId = p.categoryId;
      _imagePath = p.imagePath;
      _taxRate = p.taxRate ?? 0.0;
      _expiryDate = p.expiryDate;
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

  // Helper pour mapper le nom de l'icône à un IconData (identique à CaisseScreen)
  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'Alimentation':
        return Icons.restaurant;
      case 'Boissons':
        return Icons.local_drink;
      case 'Hygiène':
        return Icons.clean_hands;
      case 'Électronique':
        return Icons.devices;
      case 'Autre':
        return Icons.more_horiz;
      case 'food':
        return Icons.fastfood;
      case 'drink':
        return Icons.local_bar;
      case 'clothing':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices_other;
      case 'home':
        return Icons.home;
      case 'health':
        return Icons.medical_services;
      case 'beauty':
        return Icons.spa;
      case 'books':
        return Icons.book;
      case 'sports':
        return Icons.sports_baseball;
      case 'toys':
        return Icons.toys;
      case 'automotive':
        return Icons.directions_car;
      case 'garden':
        return Icons.local_florist;
      case 'pets':
        return Icons.pets;
      case 'office':
        return Icons.business_center;
      case 'jewelry':
        return Icons.diamond;
      case 'music':
        return Icons.music_note;
      case 'movies':
        return Icons.movie;
      case 'games':
        return Icons.gamepad;
      case 'tools':
        return Icons.handyman;
      case 'baby':
        return Icons.child_care;
      case 'travel':
        return Icons.card_travel;
      case 'gifts':
        return Icons.card_giftcard;
      case 'services':
        return Icons.room_service;
      case 'digital':
        return Icons.laptop_mac;
      case 'art':
        return Icons.palette;
      case 'crafts':
        return Icons.brush;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'bakery':
        return Icons.bakery_dining;
      case 'dairy':
        return Icons.egg;
      case 'meat':
        return Icons.lunch_dining;
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'seafood':
        return Icons.set_meal;
      case 'frozen':
        return Icons.icecream;
      case 'snacks':
        return Icons.cookie;
      case 'beverages':
        return Icons.local_cafe;
      case 'alcohol':
        return Icons.wine_bar;
      case 'tobacco':
        return Icons.smoking_rooms;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'personal_care':
        return Icons.face;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'stationery':
        return Icons.sticky_note_2;
      case 'furniture':
        return Icons.chair;
      case 'appliances':
        return Icons.microwave;
      case 'hardware':
        return Icons.hardware;
      case 'software':
        return Icons.computer;
      case 'photography':
        return Icons.camera_alt;
      case 'camping':
        return Icons.terrain;
      case 'fishing':
        return Icons.phishing;
      case 'hunting':
        return Icons.forest;
      case 'bicycles':
        return Icons.pedal_bike;
      case 'motorcycles':
        return Icons.two_wheeler;
      case 'boats':
        return Icons.directions_boat;
      case 'aircraft':
        return Icons.flight;
      case 'real_estate':
        return Icons.home_work;
      case 'education':
        return Icons.school;
      case 'finance':
        return Icons.account_balance;
      case 'insurance':
        return Icons.security;
      case 'legal':
        return Icons.gavel;
      case 'consulting':
        return Icons.support_agent;
      case 'marketing':
        return Icons.campaign;
      case 'advertising':
        return Icons.ad_units;
      case 'printing':
        return Icons.print;
      case 'packaging':
        return Icons.all_inbox;
      case 'logistics':
        return Icons.local_shipping;
      case 'construction':
        return Icons.construction;
      case 'manufacturing':
        return Icons.factory;
      case 'agriculture':
        return Icons.agriculture;
      case 'mining':
        return Icons.engineering;
      case 'energy':
        return Icons.lightbulb;
      case 'utilities':
        return Icons.water_drop;
      case 'waste_management':
        return Icons.delete;
      case 'security_services':
        return Icons.security_sharp;
      case 'child_care':
        return Icons.child_friendly;
      case 'elderly_care':
        return Icons.elderly;
      case 'funeral_services':
        return Icons.church;
      case 'religious_services':
        return Icons.church;
      case 'charity':
        return Icons.volunteer_activism;
      case 'government':
        return Icons.gavel;
      case 'military':
        return Icons.military_tech;
      case 'public_safety':
        return Icons.local_police;
      case 'media':
        return Icons.tv;
      case 'publishing':
        return Icons.menu_book;
      case 'broadcasting':
        return Icons.radio;
      case 'telecommunications':
        return Icons.phone;
      case 'internet':
        return Icons.wifi;
      case 'hosting':
        return Icons.dns;
      case 'software_development':
        return Icons.code;
      case 'data_processing':
        return Icons.data_usage;
      case 'research':
        return Icons.science;
      case 'engineering':
        return Icons.engineering;
      case 'architecture':
        return Icons.architecture;
      case 'design':
        return Icons.design_services;
      case 'photography_services':
        return Icons.camera_roll;
      case 'event_planning':
        return Icons.event;
      case 'catering':
        return Icons.restaurant_menu;
      case 'hospitality':
        return Icons.hotel;
      case 'tourism':
        return Icons.flight_takeoff;
      case 'transportation':
        return Icons.commute;
      case 'warehousing':
        return Icons.warehouse;
      case 'repair':
        return Icons.build;
      case 'maintenance':
        return Icons.handyman;
      case 'installation':
        return Icons.install_desktop;
      case 'rentals':
        return Icons.receipt_long;
      case 'leasing':
        return Icons.receipt_long;
      case 'wholesale':
        return Icons.store;
      case 'retail':
        return Icons.shopping_bag;
      case 'e_commerce':
        return Icons.web;
      case 'direct_sales':
        return Icons.person_add;
      case 'vending':
        return Icons.local_atm;
      case 'franchising':
        return Icons.storefront;
      case 'licensing':
        return Icons.gavel;
      case 'royalties':
        return Icons.money;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'advertising_services':
        return Icons.campaign;
      case 'public_relations':
        return Icons.public;
      case 'fundraising':
        return Icons.volunteer_activism;
      case 'investments':
        return Icons.trending_up;
      case 'banking':
        return Icons.account_balance_wallet;
      case 'credit':
        return Icons.credit_card;
      case 'loans':
        return Icons.money_off;
      case 'mortgages':
        return Icons.home_work;
      case 'brokerage':
        return Icons.bar_chart;
      case 'asset_management':
        return Icons.account_tree;
      case 'financial_planning':
        return Icons.savings;
      case 'accounting':
        return Icons.calculate;
      case 'auditing':
        return Icons.fact_check;
      case 'tax_services':
        return Icons.receipt_long;
      case 'payroll':
        return Icons.payments;
      case 'human_resources':
        return Icons.people_alt;
      case 'recruitment':
        return Icons.person_add_alt_1;
      case 'training':
        return Icons.school;
      case 'coaching':
        return Icons.psychology;
      case 'consulting_services':
        return Icons.support_agent;
      default:
        return Icons.category;
    }
  }

  Future<void> _openScanner() async {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.ean13, BarcodeFormat.qrCode],
    );

    final String? code =
        await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Scanner un code-barres'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        final barcode = capture.barcodes.firstOrNull?.rawValue;
                        if (barcode != null) {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx, barcode);
                        }
                      },
                    ),
                    // ─── VISEUR (Ligne rouge centrée) ───
                    IgnorePointer(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 1,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              color: Colors.red.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
        ).then((val) {
          controller.dispose();
          return val;
        });

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
      debugPrint('Erreur lors de la suppression du fichier: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Optimisation pour le forfait gratuit Supabase :
      // Redimensionnement et compression à la source.
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        imageQuality: 70,
      );
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
        final String fileName =
            'prod_${DateTime.now().millisecondsSinceEpoch}$extension';
        final String localPath = p.join(path, fileName);

        // --- TRAITEMENT ET COMPRESSION ---
        final bytes = await image.readAsBytes();
        img.Image? decoded = img.decodeImage(bytes);

        if (decoded != null) {
          // Redimensionnement manuel pour garantir la taille sur Desktop
          if (decoded.width > 600) {
            decoded = img.copyResize(decoded, width: 600);
          }
          // Enregistrement compressé (JPG 70% est idéal pour un catalogue POS)
          await File(
            localPath,
          ).writeAsBytes(img.encodeJpg(decoded, quality: 70));
        } else {
          await File(image.path).copy(localPath);
        }

        if (previousPath != null && previousPath != widget.product?.imagePath) {
          await _deleteFile(previousPath);
        }
        setState(() => _imagePath = localPath);
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
                title: const Text(
                  'Supprimer la photo',
                  style: TextStyle(color: AppColors.danger),
                ),
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
      builder: (_, ctrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: ctrl,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.textMuted,
                                      size: 32,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Logo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        Positioned(
                          bottom: -5,
                          right: -5,
                          child: IconButton(
                            onPressed: _showImageSourceActionSheet,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Nom ──────────────────────────
                  _label('Nom du produit *'),
                  _field(
                    _nameCtrl,
                    'Ex: Riz parfumé 5kg',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Code-barres ──────────────────
                  _label('Code-barres'),
                  TextFormField(
                    controller: _barcodeCtrl,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'EAN-13, QR, code interne...',
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          size: 18,
                          color: AppColors.primaryLight,
                        ),
                        onPressed: _openScanner,
                        tooltip: 'Scanner un code-barres',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Prix ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Prix de vente HT *'),
                            _field(
                              _priceCtrl,
                              '0',
                              keyboard: TextInputType.number,
                              validator: (v) => double.tryParse(v ?? '') == null
                                  ? 'Nombre requis'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label("Prix d'achat"),
                            _field(
                              _costCtrl,
                              '0',
                              keyboard: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Taxe ─────────────────────────
                  _label('Taux de taxe (TVA)'),
                  DropdownButtonFormField<double>(
                    initialValue: _taxRate,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(),
                    items: _taxRates
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.$1,
                            child: Text(
                              t.$2,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _taxRate = v ?? 0),
                  ),
                  const SizedBox(height: 14),

                  // ── Stock ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Stock initial'),
                            _field(
                              _stockCtrl,
                              '0',
                              keyboard: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label("Seuil d'alerte"),
                            _field(
                              _alertCtrl,
                              '5',
                              keyboard: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Unité ─────────────────────────
                  _label('Unité de mesure'),
                  DropdownButtonFormField<String>(
                    initialValue: _unit,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(),
                    items: _units
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              u,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v ?? 'pce'),
                  ),
                  const SizedBox(height: 14),

                  // ── Date d'expiration ─────────────
                  _label("Date d'expiration (optionnel)"),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _expiryDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date != null) setState(() => _expiryDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Text(
                        _expiryDate != null
                            ? Fmt.date(_expiryDate!)
                            : 'Non définie',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Catégorie ─────────────────────
                  _label('Catégorie'),
                  DropdownButtonFormField<int?>(
                    initialValue: _categories.any((c) => c.id == _categoryId)
                        ? _categoryId
                        : null,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Sans catégorie',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      ..._categories.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(c.icon ?? c.name),
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                c.name,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 14),

                  // ── Description ───────────────────
                  _label('Description (optionnel)'),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Notes sur le produit...',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Boutons ───────────────────────
                  Row(
                    children: [
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
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            _saving ? 'Enregistrement...' : 'Enregistrer',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    validator: validator,
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 14,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final String? originalPath = widget.product?.imagePath;

    try {
      final barcodeValue = _barcodeCtrl.text.trim();

      // Vérification de l'unicité du code-barres parmi les produits actifs
      if (barcodeValue.isNotEmpty) {
        final existing = await widget.db.getProductByBarcode(barcodeValue);
        if (existing != null &&
            (widget.product == null || existing.id != widget.product!.id)) {
          setState(() => _saving = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erreur : Le code-barres "$barcodeValue" est déjà utilisé par le produit "${existing.name}".',
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }
      }

      final companion = ProductsCompanion(
        id: widget.product != null
            ? Value(widget.product!.id)
            : const Value.absent(),
        name: Value(_nameCtrl.text.trim()),
        barcode: Value(barcodeValue.isEmpty ? null : barcodeValue),
        priceHt: Value(double.parse(_priceCtrl.text)),
        costPrice: Value(double.tryParse(_costCtrl.text) ?? 0),
        taxRate: Value(_taxRate),
        stockQty: Value(int.tryParse(_stockCtrl.text) ?? 0),
        stockAlert: Value(int.tryParse(_alertCtrl.text) ?? 5),
        unit: Value(_unit),
        categoryId: Value(_categoryId),
        imagePath: Value(_imagePath),
        description: Value(_descCtrl.text.trim()),
        expiryDate: Value(_expiryDate),
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      );

      // Utilisation de la méthode centralisée pour garantir la synchro Cloud
      await widget.db.upsertProduct(companion);

      // Si le chemin a changé, on supprime l'ancien fichier d'origine
      if (originalPath != null && originalPath != _imagePath) {
        await _deleteFile(originalPath);
      }

      if (mounted) {
        // Confirmation visuelle des chiffres enregistrés
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produit "${companion.name.value}" (${companion.barcode.value ?? "Sans code"}) enregistré',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
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
