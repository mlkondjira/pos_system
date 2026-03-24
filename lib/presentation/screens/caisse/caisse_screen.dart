// lib/presentation/screens/caisse/caisse_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import '../../blocs/cart_bloc.dart';
import '../../blocs/auth_bloc.dart';
import '../reports/owner_dashboard_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/users_screen.dart';
import 'payment_dialog.dart';

class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});
  @override State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen> {
  final _db = getIt<PosDatabase>();
  final _searchCtrl = TextEditingController();
  List<Product> _searchResults = [];
  bool _showScanner = false;
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String q) async {
    if (q.isEmpty) { setState(() => _searchResults = []); return; }
    setState(() => _searching = true);
    final results = await _db.searchProducts(q);
    setState(() { _searchResults = results; _searching = false; });
  }

  Future<void> _onBarcodeDetected(String barcode) async {
    setState(() => _showScanner = false);
    final product = await _db.getProductByBarcode(barcode);
    if (product != null && mounted) {
      context.read<CartBloc>().add(AddToCart(product));
      _showSnack('${product.name} ajouté ✓', AppColors.success);
    } else {
      _showSnack('Produit introuvable: $barcode', AppColors.danger);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return _buildMobileLayout(context);
        }
        return _buildDesktopLayout(context);
      },
    );
  }

  // ── DESKTOP LAYOUT (Votre design original) ─────────────
  Widget _buildDesktopLayout(BuildContext ctx) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(children: [
        // ── Panneau gauche : recherche + scan ────────────
        Expanded(
          flex: 5,
          child: Column(children: [
            _buildTopBar(ctx),
            if (_showScanner) _buildScanner(),
            _buildSearchBar(),
            Expanded(child: _buildProductGrid()),
          ]),
        ),
        // ── Panneau droit : panier ────────────────────────
        Container(
          width: 340,
          decoration: const BoxDecoration(
            color: Colors.transparent, // Le fond glass est géré par _buildCartPanel
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: _buildCartPanel(ctx),
        ),
      ]),
    );
  }

  // ── MOBILE LAYOUT (Nouveau design) ─────────────────────
  Widget _buildMobileLayout(BuildContext ctx) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(ctx),
      appBar: AppBar(
        // CORRECTION : Bouton burger personnalisé style "Glass"
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Caisse', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_showScanner ? Icons.close : Icons.qr_code_scanner),
            onPressed: () => setState(() => _showScanner = !_showScanner),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Vider le panier',
            onPressed: () => ctx.read<CartBloc>().add(ClearCart()),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showScanner) _buildScanner(),
          _buildSearchBar(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
      floatingActionButton: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.itemCount == 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showMobileCart(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              '${state.itemCount} art. • ${Fmt.currency(state.totalTtc)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    // Récupération sécurisée de l'utilisateur (peut être null si AuthBloc n'est pas prêt)
    final user = context.watch<AuthBloc>().state.user;
    final isOwner = user?.role == 'owner';
    final isAdmin = user?.role == 'admin' || isOwner;

    return Drawer(
      backgroundColor: const Color(0xE61A1A2E), // Fond très sombre et peu transparent
      elevation: 0,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.transparent),
            accountName: Text(user?.name ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            accountEmail: Text(user?.role.toUpperCase() ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text((user?.name ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale, color: Colors.white),
            title: const Text('Caisse', style: TextStyle(color: Colors.white)),
            selected: true,
            selectedTileColor: Colors.white.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: () => Navigator.pop(context), // Ferme le menu
          ),
          if (isOwner)
            ListTile(
              leading: Icon(Icons.cloud_outlined, color: Colors.white.withValues(alpha: 0.7)),
              title: Text('Dashboard Cloud', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()));
              },
            ),
          if (isOwner || isAdmin)
            ListTile(
              leading: Icon(Icons.bar_chart_rounded, color: Colors.white.withValues(alpha: 0.7)),
              title: Text('Statistiques & Ventes', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(title: const Text('Statistiques locales')),
                  body: const ReportsScreen(),
                )));
              },
            ),
          if (isAdmin)
            ListTile(
              leading: Icon(Icons.people_outline, color: Colors.white.withValues(alpha: 0.7)),
              title: Text('Utilisateurs', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
              },
            ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Colors.white.withValues(alpha: 0.7)),
            title: Text('Paramètres', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Déconnexion', style: TextStyle(color: AppColors.danger)),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
        ],
      ),
    );
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFE0E7FF), // Fond clair légèrement teinté pour le sheet
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _buildCartPanel(ctx), // Réutilisation de votre panneau panier
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext ctx) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: const BoxDecoration(
      color: AppColors.surfaceCard, // Glass effect
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('CAISSE', style: TextStyle(
          color: Colors.white, fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1.2,
        )),
      ),
      const SizedBox(width: 12),
      Text(Fmt.dateTime(DateTime.now()),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const Spacer(),
      // Bouton scan
      _topBtn(Icons.qr_code_scanner_rounded, 'Scanner',
          () => setState(() => _showScanner = !_showScanner),
          active: _showScanner),
      const SizedBox(width: 8),
      // Bouton nouvelle vente
      _topBtn(Icons.add_circle_outline_rounded, 'Nouveau',
          () => ctx.read<CartBloc>().add(ClearCart())),
    ]),
  );

  Widget _topBtn(IconData icon, String label, VoidCallback onTap, {bool active = false}) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.accentSoft : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? AppColors.accent : AppColors.border),
            ),
            child: Row(children: [
              Icon(icon, size: 18, color: active ? AppColors.accentDark : AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: active ? AppColors.accentDark : AppColors.textPrimary,
              )),
            ]),
          ),
        ),
      );

  Widget _buildScanner() => Container(
    height: 200,
    margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.accent, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: MobileScanner(
      onDetect: (capture) {
        final barcode = capture.barcodes.firstOrNull?.rawValue;
        if (barcode != null) _onBarcodeDetected(barcode);
      },
    ),
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: TextField(
      controller: _searchCtrl,
      onChanged: _onSearch,
      // Gestion de la touche "Entrée" (envoyée par la douchette USB)
      onSubmitted: (value) async {
        if (value.isEmpty) return;
        final product = await _db.getProductByBarcode(value);
        if (product != null && mounted) {
          context.read<CartBloc>().add(AddToCart(product));
          _searchCtrl.clear();
          _onSearch(''); // Réinitialise la grille
          _showSnack('${product.name} ajouté ✓', AppColors.success);
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.2),
        hintText: 'Rechercher un produit...',
        prefixIcon: _searching
            ? const Padding(padding: EdgeInsets.all(12),
                child: SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : const Icon(Icons.search_rounded, color: AppColors.textMuted),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear, size: 18),
                onPressed: () { _searchCtrl.clear(); setState(() => _searchResults = []); })
            : null,
      ),
    ),
  );

  Widget _buildProductGrid() {
    if (_searchResults.isEmpty && _searchCtrl.text.isEmpty) {
      return StreamBuilder<List<Product>>(
        stream: _db.watchActiveProducts(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return _productGrid(ctx, snap.data!);
        },
      );
    }
    return Builder(builder: (ctx) => _productGrid(ctx, _searchResults));
  }

  Widget _productGrid(BuildContext ctx, List<Product> products) {
    if (products.isEmpty) {
      return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
        SizedBox(height: 12),
        Text('Aucun produit trouvé',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
      ]),
    );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(
        product: products[i],
        onTap: () {
          ctx.read<CartBloc>().add(AddToCart(products[i]));
          _showSnack('${products[i].name} ajouté', AppColors.success);
        },
      ),
    );
  }

  Widget _buildCartPanel(BuildContext ctx) =>
      BlocBuilder<CartBloc, CartState>(builder: (ctx, cart) => Column(children: [
        // Header panier
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            const Text('Panier', style: TextStyle(
              fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.w700,
            )),
            const Spacer(),
            if (cart.itemCount > 0) Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${cart.itemCount}', style: const TextStyle(
                color: AppColors.accentDark, fontWeight: FontWeight.w700, fontSize: 13,
              )),
            ),
          ]),
        ),

        // Liste articles
        Expanded(child: cart.isEmpty
            ? _emptyCart()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: cart.items.length,
                itemBuilder: (_, i) => _CartItemTile(
                  item: cart.items[i],
                  onRemove: () => ctx.read<CartBloc>().add(RemoveFromCart(cart.items[i].productId)),
                  onQtyChanged: (q) => ctx.read<CartBloc>().add(UpdateQuantity(cart.items[i].productId, q)),
                ),
              )),

        // Totaux + paiement
        if (!cart.isEmpty) _buildCartFooter(ctx, cart),
      ]));

  Widget _emptyCart() => const Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.textMuted),
      SizedBox(height: 12),
      Text('Panier vide', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
      SizedBox(height: 6),
      Text('Scannez ou sélectionnez un article',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          textAlign: TextAlign.center),
    ],
  ));

  Widget _buildCartFooter(BuildContext ctx, CartState cart) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      border: const Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Column(children: [
      _totalRow('Sous-total', Fmt.currency(cart.subtotalTtc), muted: true),
      if (cart.globalDiscount > 0)
        _totalRow('Remise', '-${Fmt.currency(cart.globalDiscount)}',
            color: AppColors.danger, muted: true),
      const SizedBox(height: 6),
      _totalRow('TOTAL', Fmt.currency(cart.totalTtc),
          bold: true, large: true),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.payment_rounded),
          label: Text('Encaisser  ${Fmt.currency(cart.totalTtc)}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => _showPaymentDialog(ctx, cart),
        ),
      ),
    ]),
  );

  Widget _totalRow(String label, String value, {
    bool bold = false, bool large = false, bool muted = false, Color? color,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text(label, style: TextStyle(
        fontSize: large ? 15 : 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: muted ? AppColors.textSecondary : AppColors.textPrimary,
        fontFamily: bold ? 'SpaceGrotesk' : null,
      )),
      const Spacer(),
      Text(value, style: TextStyle(
        fontSize: large ? 18 : 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: color ?? (bold ? AppColors.primary : AppColors.textSecondary),
        fontFamily: bold ? 'SpaceGrotesk' : null,
      )),
    ]),
  );

  Future<void> _showPaymentDialog(BuildContext ctx, CartState cart) async {
    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => PaymentDialog(cart: cart, db: _db),
    );
    if (!ctx.mounted) return;
    ctx.read<CartBloc>().add(ClearCart());
  }
}

// ── Carte produit ──────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});
  @override State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final priceTtc = p.priceHt * (1 + p.taxRate);
    final outOfStock = p.stockQty <= 0;
    final isLowStock = !outOfStock && p.stockQty <= p.stockAlert;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); if (!outOfStock) widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: outOfStock ? Colors.white.withValues(alpha: 0.3) : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: outOfStock ? AppColors.border : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1, // Équilibrage de l'espace (50% image)
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.3),
                      child: (p.imagePath?.isNotEmpty == true)
                          ? Image.file(
                              File(p.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  Expanded(
                    flex: 1, // Équilibrage de l'espace (50% texte) pour éviter l'overflow
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Padding réduit
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible( // Permet au texte de se réduire si nécessaire
                            child: Text(p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: outOfStock ? AppColors.textMuted : AppColors.textPrimary,
                                  height: 1.1,
                                )),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Fmt.currency(priceTtc),
                                  style: const TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  )),
                              const SizedBox(height: 2),
                              if (outOfStock)
                                const Text('Épuisé', style: TextStyle(
                                  color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w600
                                ))
                              else
                                Text('${p.stockQty} ${p.unit}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isLowStock ? AppColors.warning : AppColors.textMuted,
                                      fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                    )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!outOfStock)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Center(
        child: Icon(Icons.inventory_2_outlined,
            color: AppColors.primary.withValues(alpha: 0.2), size: 32),
      );
}

// ── Ligne du panier ────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChanged;
  const _CartItemTile({required this.item, required this.onRemove, required this.onQtyChanged});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
    ),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
          ), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(Fmt.currency(item.priceTtc),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ),
      
      _QtyControl(qty: item.quantity, onChanged: onQtyChanged),
      
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(Fmt.currency(item.lineTotalTtc),
          style: const TextStyle(fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
      ]),
      const SizedBox(width: 2),
      Material(
        type: MaterialType.transparency,
        child: IconButton(
          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
          onPressed: onRemove,
          splashRadius: 20,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ),
    ]),
  );
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  const _QtyControl({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _btn(Icons.remove_rounded, () => onChanged(qty - 1)),
      Container(
        constraints: const BoxConstraints(minWidth: 28),
        alignment: Alignment.center,
        child: Text('$qty', style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13,
        )),
      ),
      _btn(Icons.add_rounded, () => onChanged(qty + 1)),
    ]),
  );

  Widget _btn(IconData icon, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: double.infinity,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    ),
  );
}
