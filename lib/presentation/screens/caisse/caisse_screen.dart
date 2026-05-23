import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:audioplayers/audioplayers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../blocs/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../widgets/admin_override_dialog.dart';
import '../../blocs/cart_bloc.dart';
import '../../widgets/shared_widgets.dart';
import '../products/stock_check_screen.dart';
import '../../widgets/app_background.dart';
import 'payment_dialog.dart';

/// Centralise le mapping des icônes pour les catégories.
/// On utilise soit l'identifiant technique (slug) soit le nom affiché.
IconData _getCategoryIcon(String? identifier) {
  switch (identifier) {
    case 'Alimentation':
    case 'food':
    case 'groceries':
      return Icons.restaurant;
    case 'Boissons':
    case 'drink':
    case 'beverages':
      return Icons.local_drink;
    case 'Hygiène':
    case 'health':
    case 'cleaning':
      return Icons.clean_hands;
    case 'Électronique':
    case 'electronics':
    case 'digital':
      return Icons.devices;
    case 'clothing':
      return Icons.checkroom;
    case 'home':
      return Icons.home;
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
    case 'business_center':
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
    case 'handyman':
      return Icons.handyman;
    case 'baby':
    case 'child_care':
      return Icons.child_care;
    case 'travel':
      return Icons.card_travel;
    case 'gifts':
      return Icons.card_giftcard;
    case 'services':
      return Icons.room_service;
    case 'art':
      return Icons.palette;
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
    case 'alcohol':
      return Icons.wine_bar;
    case 'tobacco':
      return Icons.smoking_rooms;
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
    case 'account_balance':
      return Icons.account_balance;
    case 'insurance':
    case 'security':
      return Icons.security;
    case 'legal':
    case 'gavel':
      return Icons.gavel;
    case 'marketing':
    case 'campaign':
      return Icons.campaign;
    case 'advertising':
      return Icons.ad_units;
    case 'printing':
      return Icons.print;
    case 'logistics':
    case 'transportation':
      return Icons.local_shipping;
    case 'construction':
      return Icons.construction;
    case 'manufacturing':
    case 'factory':
      return Icons.factory;
    case 'agriculture':
      return Icons.agriculture;
    case 'energy':
      return Icons.lightbulb;
    case 'utilities':
    case 'water_drop':
      return Icons.water_drop;
    case 'Autre':
    default:
      return Icons.category;
  }
}

class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen>
    with SingleTickerProviderStateMixin {
  final _db = getIt<PosDatabase>();
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _selectedCategoryId;
  // État interne pour basculer le panneau latéral
  bool _isPaymentViewActive = false;
  // On utilise des instances statiques pour éviter de multiplier les canaux
  // d'événements sur Windows, ce qui réduit les erreurs de threading.
  static final AudioPlayer _successPlayer = AudioPlayer();
  static final AudioPlayer _errorPlayer = AudioPlayer();
  static bool _audioInitialized = false;

  // Animation pour l'effet de "Pulse" du panier
  late AnimationController _cartPulseController;
  late Animation<double> _cartPulseAnimation;

  // FocusNode pour capter les scans même sans champ texte focusé
  final _scannerFocus = FocusNode();
  String _barcodeBuffer = '';

  // Variables pour le contrôle de la vitesse de scan
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  // Mode scan continu
  bool _continuousScan = false;

  @override
  void initState() {
    super.initState();

    if (!_audioInitialized) {
      // Configuration unique pour les instances statiques
      if (!Platform.isWindows) {
        _successPlayer.setPlayerMode(PlayerMode.lowLatency);
        _errorPlayer.setPlayerMode(PlayerMode.lowLatency);
      }

      _successPlayer.setReleaseMode(ReleaseMode.stop);
      _errorPlayer.setReleaseMode(ReleaseMode.stop);

      // Pré-chargement des sons
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _successPlayer.setSource(AssetSource('sounds/BEEP.mp3'));
          await _errorPlayer.setSource(AssetSource('sounds/ERROR.mp3'));
          _audioInitialized = true;
        } catch (e) {
          debugPrint('Erreur initialisation audio: $e');
        }
      });
    }

    // Initialisation de l'animation
    _cartPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _cartPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticIn)),
        weight: 50,
      ),
    ]).animate(_cartPulseController);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scannerFocus.dispose();
    // Note: On ne dispose pas les instances statiques ici car elles sont
    // réutilisées par l'application pour la durée de la session.
    _cartPulseController.dispose(); // Libère les ressources de l'animation
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    // Sécurité : On ignore le scan si l'utilisateur est déjà en train de taper dans un champ (ex: recherche)
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return;
    }

    // On n'écoute que les pressions de touches (pas les relâchements)
    if (event is KeyDownEvent) {
      // Touche F2 : Ouvre instantanément le vérificateur de stock sur PC
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        _openStockCheck();
        return;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.isNotEmpty) {
          _processBarcode(_barcodeBuffer);
          _barcodeBuffer = '';
        }
      } else {
        // Ajout du caractère au tampon s'il est imprimable
        final char = event.character;
        if (char != null) _barcodeBuffer += char;
      }
    }
  }

  Future<void> _processBarcode(String code) async {
    final now = DateTime.now();

    // --- LOGIQUE DE PRÉVENTION DES DOUBLONS ---
    // Si c'est le même code que le précédent et que le délai est < 2 secondes, on ignore.
    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 2)) {
      return;
    }

    _lastScannedCode = code;
    _lastScanTime = now;

    // Récupération de la préférence utilisateur
    final soundEnabled =
        (await _db.getSetting('scanner_sound_enabled') ?? '1') == '1';

    final product = await _db.getProductByBarcode(code);
    if (product != null && mounted) {
      if (soundEnabled) {
        _successPlayer.seek(Duration.zero);
        _successPlayer.resume();
      }
      HapticFeedback.lightImpact(); // Petit retour tactile

      // Déclencher l'animation visuelle
      _cartPulseController.forward(from: 0.0);

      context.read<CartBloc>().add(AddToCart(product));

      // Nettoie les messages précédents pour un retour instantané lors de scans rapides
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_shopping_cart_rounded,
                color: AppColors.success, // Ligne 182
                size: 18,
              ),
              const SizedBox(width: 12),
              Flexible(
                // Ligne 179
                child: Text(
                  '${product.name} (${product.barcode ?? 'N/A'}) ajouté',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          width:
              320, // Légèrement plus large pour accommoder le bouton d'annulation
          behavior: SnackBarBehavior.floating, // Ligne 203
          duration: // Ligne 203
          const Duration(
            seconds: 2,
          ), // Un peu plus de temps pour cliquer
          backgroundColor: AppColors.textPrimary.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          action: SnackBarAction(
            label: 'ANNULER',
            textColor: AppColors.primaryLight,
            onPressed: () {
              final cart = context.read<CartBloc>().state;
              final existingIdx = cart.items.indexWhere(
                (i) => i.productId == product.id,
              );
              if (existingIdx != -1) {
                final currentQty = cart.items[existingIdx].quantity;
                // Décrémente la quantité (si elle tombe à 0, le bloc gère la suppression)
                context.read<CartBloc>().add(
                  UpdateQuantity(product.id, currentQty - 1),
                );
              }
            },
          ),
        ),
      );
    } else if (mounted) {
      if (soundEnabled) {
        _errorPlayer.seek(Duration.zero);
        _errorPlayer.resume();
      }
      HapticFeedback.heavyImpact(); // Retour tactile plus marqué

      // Produit non trouvé -> Dialogue d'ajout rapide
      final newProduct = await showDialog<Product>(
        context: context,
        barrierDismissible: false, // Ligne 233
        builder: (_) => _QuickAddProductDialog(barcode: code),
      );

      if (newProduct != null && mounted) {
        context.read<CartBloc>().add(AddToCart(newProduct));

        // On ajoute ici la même notification de confirmation avec le code-barres
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '${newProduct.name} (${newProduct.barcode ?? 'N/A'}) créé et ajouté',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            width: 320,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.textPrimary.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            action: SnackBarAction(
              label: 'ANNULER',
              textColor: AppColors.primaryLight,
              onPressed: () {
                // En cas d'annulation, on retire l'article du panier
                context.read<CartBloc>().add(RemoveFromCart(newProduct.id));
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _scannerFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cart) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // On utilise la largeur réelle disponible (plus précis que MediaQuery)
              final bool isWide = constraints.maxWidth > 850;

              return Scaffold(
                backgroundColor: Colors.transparent,
                body: AppBackground(
                  child: Row(
                    children: [
                      // --- SECTION PRODUITS (À GAUCHE) ---
                      Expanded(
                        child: Column(
                          children: [
                            _buildTopSearch(),
                            _buildCategorySelector(),
                            Expanded(child: _buildProductGrid(isWide, cart)),
                          ],
                        ),
                      ),

                      // --- PANNEAU LATÉRAL (SPLIT VIEW) ---
                      if (isWide)
                        Container(
                          width: 420,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                            border: Border(
                              left: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: ScaleTransition(
                            scale: _cartPulseAnimation,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    final slide =
                                        Tween<Offset>(
                                          begin: const Offset(0.15, 0.0),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        );

                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: slide,
                                        child: child,
                                      ),
                                    );
                                  },
                              child: _isPaymentViewActive
                                  ? PaymentDialog(
                                      key: const ValueKey('internal_pay'),
                                      cart: cart,
                                      db: _db,
                                      isEmbedded: true,
                                      onCancel: () => setState(
                                        () => _isPaymentViewActive = false,
                                      ),
                                    )
                                  : _CartPanel(
                                      key: const ValueKey('cart_panel'),
                                      pulseAnimation:
                                          null, // Géré maintenant par le parent
                                      onPay: () => setState(
                                        () => _isPaymentViewActive = true,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Mobile : Bouton d'accès au panier si non vide
                floatingActionButton: isWide
                    ? null
                    : cart.isEmpty
                    ? null
                    : ScaleTransition(
                        scale: _cartPulseAnimation,
                        child: FloatingActionButton.extended(
                          onPressed: () => _openMobileCart(context, cart),
                          backgroundColor: AppColors.primary,
                          elevation: 8,
                          icon: const Icon(Icons.shopping_basket_rounded),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${cart.itemCount} articles • ${Fmt.currency(cart.totalTtc)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, // Ligne 320
                              ),
                            ),
                          ), // Ligne 320
                        ),
                      ), // Suppression du point-virgule ici
              ); // Ce point-virgule termine l'instruction 'return Scaffold(...);'
            },
          );
        },
      ),
    );
  }

  void _openStockCheck() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StockCheckScreen()),
    );
  }

  void _openCameraScanner() {
    // On restreint les formats pour augmenter la vitesse de décodage
    final flashNotifier = ValueNotifier<bool>(false);
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.ean13, BarcodeFormat.qrCode],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                title: const Text(
                  'Scanner un article',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: controller,
                    builder: (context, state, child) {
                      final bool isTorchOn = state.torchState == TorchState.on;
                      return IconButton(
                        icon: Icon(
                          isTorchOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: isTorchOn
                              ? Colors.yellowAccent
                              : Colors.white54,
                        ),
                        onPressed: () => controller.toggleTorch(),
                        tooltip: 'Lampe torche',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      children: [
                        const Text(
                          'Continu',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Switch(
                          value: _continuousScan,
                          onChanged: (v) {
                            setModalState(() => _continuousScan = v);
                            setState(() => _continuousScan = v);
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null) {
                          // Retour immédiat (Vibration + Flash vert)
                          HapticFeedback.lightImpact();
                          flashNotifier.value = true;
                          Future.delayed(
                            const Duration(milliseconds: 100),
                            () => flashNotifier.value = false,
                          );

                          // Si le mode continu est désactivé, on ferme le scanner
                          if (!_continuousScan) {
                            Navigator.pop(ctx);
                          }
                          _processBarcode(code);
                        }
                      }
                    },
                  ),
                  // ─── VISEUR (Ligne rouge et cadre) ───
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            height: 1.5,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            color: Colors.red.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Overlay de confirmation visuelle (Flash vert)
                  ValueListenableBuilder<bool>(
                    valueListenable: flashNotifier,
                    builder: (context, show, _) {
                      if (!show) return const SizedBox.shrink();
                      return Container(
                        color: Colors.green.withValues(alpha: 0.3),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      controller.dispose();
      flashNotifier.dispose();
    });
  }

  void _openPayment(CartState cart) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentDialog(cart: cart, db: _db),
    );
  }

  Widget _buildTopSearch() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: PosSearchBar(
              controller: _searchCtrl,
              hint: 'Chercher un article ou scanner...',
              onChanged: (v) => setState(() => _query = v), // Ligne 362
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: _openStockCheck,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(12),
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              foregroundColor: AppColors.success,
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Vérifier prix/stock (F2)',
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: _openCameraScanner,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(12),
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              foregroundColor: AppColors.success,
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: StreamBuilder<List<Category>>(
        stream: _db.select(_db.categories).watch(),
        builder: (context, snapshot) {
          final cats = snapshot.data ?? [];
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: cats.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final cat = isAll ? null : cats[index - 1];
              final isSelected = isAll
                  ? _selectedCategoryId == null
                  : _selectedCategoryId == cat?.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  label: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAll
                              ? Icons.all_inclusive
                              : _getCategoryIcon(cat?.icon ?? cat?.name),
                          size: 20,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAll ? 'Tous' : cat!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(
                    () => _selectedCategoryId = isAll ? null : cat?.id,
                  ),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  showCheckmark: false,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(bool isWide, CartState cart) {
    return StreamBuilder<List<Product>>(
      stream: _db.watchProducts(query: _query, categoryId: _selectedCategoryId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data!; // Ligne 435

        if (products.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Aucun produit',
            subtitle: 'Aucun article ne correspond à votre recherche.',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide
                ? 4
                : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
            childAspectRatio: 0.78,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return _ProductCard(
              product: p,
              isInCart: cart.items.any((i) => i.productId == p.id),
              onTap: () {
                context.read<CartBloc>().add(AddToCart(p));
              },
            );
          },
        );
      },
    );
  }

  void _openMobileCart(BuildContext context, CartState cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _CartPanel(
          onPay: () {
            _openPayment(cart);
          },
        ),
      ),
    );
  }
}

/// Dialogue d'ajout rapide pour un produit inconnu détecté par scan
class _QuickAddProductDialog extends StatefulWidget {
  final String barcode;
  const _QuickAddProductDialog({required this.barcode});

  @override
  State<_QuickAddProductDialog> createState() => _QuickAddProductDialogState();
}

class _QuickAddProductDialogState extends State<_QuickAddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _db = getIt<PosDatabase>();
  int? _selectedCategoryId;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final shopId = await _db.getSetting('shop_id') ?? '';

      // Use the default constructor with Value() instead of .insert()
      // to avoid strict required parameter checks from the old .g.dart file.
      final product = await _db.upsertProduct(
        ProductsCompanion(
          shopId: Value(shopId),
          name: Value(_nameCtrl.text.trim()),
          priceHt: Value(double.parse(_priceCtrl.text)),
          barcode: Value(widget.barcode),
          categoryId: Value(_selectedCategoryId),
          stockQty: const Value(100),
        ),
      );
      if (mounted) Navigator.pop(context, product);
    } catch (e) {
      setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 440, // Un peu plus large sur tablette
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouveau produit scanné',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code-barres : ${widget.barcode}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtrl,
                    autofocus: true,
                    style: TextStyle(
                      // Ligne 542
                      color: Theme.of(context).colorScheme.onSurface,
                    ), // Ligne 542
                    decoration: const InputDecoration(
                      labelText: 'Nom du produit',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Veuillez saisir un nom' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceCtrl,
                    style: TextStyle(
                      // Ligne 552
                      color: Theme.of(context).colorScheme.onSurface,
                    ), // Ligne 552
                    decoration: const InputDecoration(
                      labelText: 'Prix de vente TTC',
                      prefixIcon: Icon(Icons.payments_outlined),
                      suffixText: 'FCFA',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? 'Prix invalide'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Category>>(
                    stream: _db.select(_db.categories).watch(),
                    builder: (context, snapshot) {
                      final cats = snapshot.data ?? [];
                      return DropdownButtonFormField<int?>(
                        initialValue:
                            cats.any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sans catégorie'),
                          ),
                          ...cats.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(c.icon ?? c.name),
                                    size: 18,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : AppColors.textSecondary,
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
                        onChanged: (v) =>
                            setState(() => _selectedCategoryId = v),
                      );
                    },
                  ),
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
                          onPressed: _loading ? null : _save,
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
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final bool isInCart;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    this.isInCart = false,
    required this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.94, // L'échelle descendra à 94% lors du clic (tap)
      upperBound: 1.03, // L'échelle montera à 103% lors du survol (hover)
    )..value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.product.stockQty <= 0) return;

    // Animation de rebond : rétrécit puis revient à la taille normale (pour le tap)
    _controller
        .animateTo(0.94, duration: const Duration(milliseconds: 50))
        .then((_) {
          _controller.animateTo(
            1.0,
            duration: const Duration(milliseconds: 50),
          );
        });

    // Appelle le callback original pour ajouter au panier
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLowStock =
        widget.product.stockQty <= widget.product.stockAlert &&
        widget.product.stockQty > 0;

    // Calcul de la proximité de péremption
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = widget.product.expiryDate != null
        ? DateTime(
            widget.product.expiryDate!.year,
            widget.product.expiryDate!.month,
            widget.product.expiryDate!.day,
          )
        : null;
    final daysUntilExpiry = expiryDate?.difference(today).inDays;
    final bool isNearExpiry =
        daysUntilExpiry != null && daysUntilExpiry >= 0 && daysUntilExpiry <= 7;

    return ScaleTransition(
      // Ligne 653
      scale: _controller,
      child: InkWell(
        onTap: widget.product.stockQty > 0 ? _handleTap : null,
        onHover: (isHovering) {
          if (widget.product.stockQty > 0) {
            if (isHovering) {
              // Ligne 653
              _controller.animateTo(1.03); // Agrandit légèrement au survol
            } else {
              _controller.animateTo(1.0); // Revient à la taille normale
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          // Ligne 671
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isInCart ? AppColors.primary : AppColors.border,
              width: widget.isInCart ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (widget.isInCart)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
            ], // Ligne 690
          ), // Ligne 690
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ProductImage(
                        imagePath: widget.product.imagePath,
                        borderRadius: 12,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isLowStock
                                      ? AppColors
                                            .warning // Ligne 512
                                      : Theme.of(context).colorScheme.surface)
                                  .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6), // Ligne 711
                          border: Border.all(
                            color: isLowStock
                                ? AppColors.warning
                                : Theme.of(context).dividerColor,
                            width: 0.5,
                          ),
                        ), // Ligne 626
                        child: Text(
                          // Ligne 720
                          '${widget.product.stockQty}',
                          style: TextStyle(
                            // Ligne 720
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isLowStock
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    if (isNearExpiry)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                daysUntilExpiry == 0
                                    ? 'AUJOURD\'HUI'
                                    : 'J-$daysUntilExpiry',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.product.stockQty <= 0)
                      Container(
                        decoration: BoxDecoration(
                          color: // Ligne 735
                              Theme.of(context) // Ligne 735
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: StatusBadge(
                            label: 'ÉPUISÉ',
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600, // Ligne 753
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Fmt.currency(widget.product.priceHt),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  final VoidCallback onPay;
  final Animation<double>? pulseAnimation;
  const _CartPanel({super.key, required this.onPay, this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cart) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Panier',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!cart.isEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          context.read<CartBloc>().add(ClearCart()),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text(
                        'Vider',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        backgroundColor: AppColors.danger.withValues(
                          alpha: 0.1,
                        ),
                        side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? const EmptyState(
                      icon: Icons.add_shopping_cart_rounded,
                      title: 'Votre panier est vide',
                      subtitle: 'Sélectionnez des articles pour commencer.',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 16,
                      ), // Ligne 703
                      itemBuilder: (context, index) {
                        // Ligne 703
                        final item = cart.items[index];
                        return _CartItemTile(item: item);
                      },
                    ),
            ),
            if (pulseAnimation != null)
              ScaleTransition(
                scale: pulseAnimation!,
                child: _buildSummary(context, cart),
              )
            else
              _buildSummary(context, cart),
          ],
        );
      },
    );
  }

  void _showCouponDialog(BuildContext context, CartState initialCart) {
    final controller = TextEditingController(text: initialCart.couponCode);
    showDialog(
      context: context,
      builder: (dialogCtx) => BlocConsumer<CartBloc, CartState>(
        listenWhen: (prev, curr) =>
            prev.couponCode != curr.couponCode && curr.error == null,
        listener: (context, state) => Navigator.pop(dialogCtx),
        builder: (context, state) {
          return AlertDialog(
            scrollable: true,
            title: const Text('Appliquer un coupon'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Ligne 738
                  // Ligne 738
                  return newValue.copyWith(text: newValue.text.toUpperCase());
                }),
              ],
              decoration: InputDecoration(
                hintText: 'Code promo (ex: SOLDES2024)',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                counterText: '',
                errorText: state.error,
              ),
              onChanged: (v) {
                // On efface l'erreur dès que l'utilisateur recommence à saisir
                if (state.error != null) {
                  context.read<CartBloc>().add(ClearCartError());
                }
              },
            ),
            actions: [
              if (state.couponCode != null)
                TextButton(
                  onPressed: () =>
                      context.read<CartBloc>().add(SetCoupon(null)),
                  child: const Text(
                    'SUPPRIMER',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              TextButton(
                onPressed: () {
                  context.read<CartBloc>().add(ClearCartError());
                  Navigator.pop(dialogCtx);
                },
                child: const Text('ANNULER'),
              ),
              ElevatedButton(
                onPressed: () {
                  final code = controller.text.trim();
                  context.read<CartBloc>().add(
                    SetCoupon(code.isEmpty ? null : code),
                  );
                  // Note: On ne pop pas ici, le listener s'en chargera en cas de succès
                },
                child: const Text('APPLIQUER'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartState cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Section Coupon
          InkWell(
            onTap: () => _showCouponDialog(context, cart),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cart.couponCode != null
                    ? AppColors.success.withValues(alpha: 0.05)
                    : AppColors.bg,
                borderRadius: BorderRadius.circular(8), // Ligne 674
                border: Border.all(
                  color: cart.couponCode != null
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: cart.couponCode != null
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cart.couponCode ?? 'Ajouter un coupon',
                    style: TextStyle(
                      fontSize: 13,
                      color: cart.couponCode != null
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  // Ligne 800
                  // Ligne 800
                  'TOTAL À PAYER',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Fmt.currency(cart.totalTtc),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: cart.isEmpty ? null : onPay,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'RÉGLER LA VENTE',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final db = getIt<PosDatabase>();
    return InkWell(
      onTap: () => _showDiscountDialog(context, db),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name, // Ligne 851
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        Fmt.currency(item.product.priceHt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.discountPct > 0 || item.discountAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '-${item.discountPct > 0 ? "${item.discountPct}%" : Fmt.currency(item.discountAmount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            QuantityStepper(
              // Utilise le nouveau widget
              value: item.quantity,
              onChanged: (v) {
                if (v == 0) {
                  context.read<CartBloc>().add(RemoveFromCart(item.product.id));
                } else {
                  context.read<CartBloc>().add(
                    UpdateQuantity(item.product.id, v),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, PosDatabase db) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(
          text: item.discountPct > 0
              ? item.discountPct.toStringAsFixed(0)
              : item.discountAmount > 0
              ? item.discountAmount.toStringAsFixed(0)
              : '',
        );
        bool isPercentage =
            item.discountPct > 0 ||
            (item.discountPct == 0 && item.discountAmount == 0);

        return StatefulBuilder(
          builder: (context, setModalState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Remise : ${item.product.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sélecteur de type de remise stylisé (Shopify POS style)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _buildToggleOption(
                          context,
                          label: 'Pourcentage (%)',
                          selected: isPercentage,
                          onTap: () => setModalState(() => isPercentage = true),
                        ),
                        _buildToggleOption(
                          context,
                          label: 'Montant Fixe',
                          selected: !isPercentage,
                          onTap: () =>
                              setModalState(() => isPercentage = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: isPercentage ? '%' : 'FCFA',
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      filled: true,
                      fillColor: AppColors.bg.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            context.read<CartBloc>().add(
                              SetItemDiscount(item.product.id, 0),
                            );
                            context.read<CartBloc>().add(
                              SetItemDiscountAmount(item.product.id, 0),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'SUPPRIMER',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(0, 50),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final val = double.tryParse(ctrl.text) ?? 0;

                            // 1. Vérification des droits pour les remises importantes
                            final authState = context.read<AuthBloc>().state;
                            final isAdmin =
                                authState.user?.role == 'admin' ||
                                authState.user?.role == 'owner';

                            // Définition des seuils (peuvent être mis en paramètres plus tard)
                            const double maxPctNonAdmin = 15.0;
                            const double maxAmountNonAdmin = 5000.0;

                            if (!isAdmin) {
                              final bool exceedsLimit =
                                  (isPercentage && val > maxPctNonAdmin) ||
                                  (!isPercentage && val > maxAmountNonAdmin);

                              if (exceedsLimit) {
                                final String reason =
                                    "Remise de ${isPercentage ? "$val%" : Fmt.currency(val)} dépasse la limite autorisée.";
                                final User? authorizedAdmin =
                                    await showDialog<User>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) =>
                                          AdminOverrideDialog(reason: reason),
                                    );

                                if (authorizedAdmin == null ||
                                    !context.mounted) {
                                  return;
                                }

                                // Enregistrement automatique du log d'audit
                                await db.addAuditLog(
                                  actorId: authorizedAdmin.id,
                                  action: 'discount_override',
                                  targetEntityType: 'product',
                                  targetEntityId: item.product.id,
                                  details: jsonEncode({
                                    'cashier_name':
                                        authState.user?.name ?? 'Inconnu',
                                    'discount_value': isPercentage
                                        ? '$val%'
                                        : Fmt.currency(val),
                                    'product_name': item.product.name,
                                  }),
                                );
                              }
                            }
                            if (!context.mounted) {
                              return;
                            }

                            // 2. Application de la remise
                            if (isPercentage) {
                              context.read<CartBloc>().add(
                                SetItemDiscount(item.product.id, val),
                              );
                              context.read<CartBloc>().add(
                                SetItemDiscountAmount(item.product.id, 0),
                              );
                            } else {
                              context.read<CartBloc>().add(
                                SetItemDiscount(item.product.id, 0),
                              );
                              context.read<CartBloc>().add(
                                SetItemDiscountAmount(item.product.id, val),
                              );
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('APPLIQUER'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
