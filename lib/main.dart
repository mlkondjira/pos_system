// ============================================================
//  main.dart — Point d'entrée POS System
//  Flutter multiplateforme : Android · iOS · Windows · macOS · Linux
// ============================================================
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Nécessaire pour GlobalMaterialLocalizations, etc.
import 'package:pos_system/core/l10n/app_localizations.dart'; // Chemin corrigé
import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'data/database/pos_database.dart';
import 'core/di/injection.dart';
import 'core/utils/notification_service.dart';
import 'core/utils/formatters.dart';
import 'core/constants/supabase_config.dart';
import 'data/services/sync_service.dart';
import 'core/services/license_service.dart';
import 'presentation/widgets/license_gate.dart';
import 'presentation/blocs/auth_bloc.dart' hide AppStarted;
import 'presentation/widgets/app_background.dart';
import 'presentation/blocs/cash_session_bloc.dart';
import 'presentation/blocs/cart_bloc.dart';
import 'presentation/blocs/theme_bloc.dart';
import 'login_screen.dart';
import 'presentation/screens/cash_drawer/open_cash_drawer_screen.dart';
import 'presentation/screens/cash_drawer/close_cash_drawer_screen.dart';
import 'presentation/screens/caisse/caisse_screen.dart';
import 'presentation/screens/produits/produits_screen.dart';
import 'presentation/screens/inventaire/inventaire_screen.dart';
import 'presentation/screens/inventory/purchase_order_list_screen.dart';
import 'presentation/screens/inventory/stock_transfer_screen.dart';
import 'presentation/screens/sales/sale_history_screen.dart';
import 'presentation/screens/customers/customers_screen.dart';
import 'presentation/screens/customers/debtors_screen.dart';
import 'presentation/screens/settings/sync_error_screen.dart';
import 'presentation/screens/suppliers/suppliers_screen.dart';
import 'presentation/screens/expenses/expenses_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'shop_setup_screen.dart';
import 'presentation/screens/reports/owner_dashboard_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// FONCTION GLOBALE : Point d'entrée pour les actions de notification en arrière-plan
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.actionId == 'action_mark_received') {
    // Le payload est 'transfer:123'
    final parts = response.payload?.split(':');
    if (parts != null && parts.length == 2 && parts[0] == 'transfer') {
      final transferId = int.tryParse(parts[1]);
      if (transferId != null) {
        // Initialisation minimale pour l'arrière-plan
        final db = PosDatabase();
        final lastUserId =
            int.tryParse(await db.getSetting('last_logged_user_id') ?? '0') ??
            0;

        if (lastUserId != 0) {
          await db.validateStockTransferReception(
            transferId: transferId,
            userId: lastUserId,
          );
        }
        await db.close();
      }
    }
  }
}

/// Initialise l'icône dans la barre système pour Windows
Future<void> _initSystemTray() async {
  if (!Platform.isWindows) return;

  // Définit l'icône (utilise le logo existant)
  await trayManager.setIcon(
    Platform.isWindows ? 'assets/logo.png' : 'assets/logo.png',
  );

  // Crée un menu contextuel simple
  final menu = Menu(
    items: [
      MenuItem(key: 'show_window', label: 'Ouvrir Gpos'),
      MenuItem.separator(),
      MenuItem(key: 'exit_app', label: 'Quitter l\'application'),
    ],
  );
  await trayManager.setContextMenu(menu);
}

void main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeDateFormatting('fr_FR', null);

  // Augmentation du cache image pour supporter un catalogue large (ex: 250 MB)
  // Cela évite le scintillement des images lors du scroll rapide.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 250 * 1024 * 1024;

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    // CORRECTION : désactive le flux PKCE qui nécessite asyncStorage
    // sur Windows/desktop. Implicit flow est sécurisé pour les apps natives.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  await setupDependencies();

  // Initialisation du service de licence SaaS
  await getIt<LicenseService>().initialize();

  // Initialisation et demande de permissions pour les notifications
  final notificationService = getIt<NotificationService>();
  await notificationService.initialize(
    notificationTapBackground,
  ); // On passe le handler ici
  await notificationService.requestPermissions();

  try {
    await getIt<SyncService>().initialize();
  } on PlatformException catch (e) {
    debugPrint('Failed to initialize connectivity listener: $e');
  }

  // Initialisation de la barre système sur Desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await _initSystemTray();
  }

  // Optimisation visuelle pour Mobile (Android/iOS)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PosDatabase>(create: (_) => getIt<PosDatabase>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CartBloc()),
          BlocProvider(create: (_) => AuthBloc(getIt<PosDatabase>())),
          BlocProvider(
            create: (_) =>
                CashSessionBloc(getIt<PosDatabase>(), getIt<SyncService>())
                  ..add(AppStarted()),
          ),
          BlocProvider(create: (_) => getIt<ThemeBloc>()..add(LoadTheme())),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'POS System',
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('fr'),
                Locale('en'),
                Locale('ar'),
              ],
              debugShowCheckedModeBanner: false,
              themeMode: themeState.themeMode,
              theme: AppTheme.light.copyWith(
                textTheme: AppTheme.light.textTheme.copyWith(
                  titleLarge: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900, // Plus gras pour le premium
                    fontSize: 24,
                    letterSpacing: -0.8,
                    color: AppColors.textPrimary,
                  ),
                  titleMedium: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16, // Ligne 122
                    fontWeight: FontWeight.w600,
                  ),
                ),
                inputDecorationTheme: AppTheme.light.inputDecorationTheme
                    .copyWith(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
              ),
              darkTheme: AppTheme.dark.copyWith(
                textTheme: AppTheme.dark.textTheme.copyWith(
                  titleLarge: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.8,
                    color: Colors.white,
                  ),
                  titleMedium: GoogleFonts.inter(
                    color: Colors.white70, // Ligne 122
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              home: _FadeInWrapper(
                child: BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    // Si l'utilisateur vient de se connecter, on rafraîchit l'état de la session
                    // pour rediriger automatiquement vers l'accueil si une session est déjà ouverte.
                    if (state.isAuthenticated) {
                      context.read<CashSessionBloc>().add(AppStarted());
                    }

                    if (state.isBeingForceLoggedOut) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Compte désactivé, déconnexion en cours...',
                          ),
                          backgroundColor: AppColors.danger,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      if (!authState.isAuthenticated) {
                        return const LoginScreen();
                      }

                      // NOUVEAU : Vérifier si un magasin est configuré sur cet appareil
                      return FutureBuilder<String?>(
                        future: context.read<PosDatabase>().getSetting(
                          'shop_id',
                        ),
                        builder: (context, shopSnap) {
                          if (shopSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final hasShop =
                              shopSnap.data != null &&
                              shopSnap.data!.isNotEmpty;
                          if (!hasShop) return const ShopSetupScreen();

                          return BlocBuilder<CashSessionBloc, CashSessionState>(
                            builder: (context, sessionState) {
                              if (sessionState is CashSessionLoading ||
                                  sessionState is CashSessionInitial) {
                                return const Scaffold(
                                  body: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (sessionState is NoCashSession) {
                                return const OpenCashDrawerScreen();
                              }
                              return const AppShell();
                            },
                          );
                        }, // Ferme le builder du FutureBuilder
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── DESTINATIONS DE NAVIGATION ───────────────────────────────
class _NavDest {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDest(this.icon, this.activeIcon, this.label);
}

// ── WRAPPER D'ANIMATION DE DÉMARRAGE ─────────────────────────
class _FadeInWrapper extends StatefulWidget {
  final Widget child;
  const _FadeInWrapper({required this.child});

  @override
  State<_FadeInWrapper> createState() => _FadeInWrapperState();
}

class _FadeInWrapperState extends State<_FadeInWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Durée du fondu
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // On lance l'animation et on retire le splash screen natif simultanément
    _controller.forward();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

// ── SHELL PRINCIPAL ──────────────────────────────────────────
class AppShell extends StatefulWidget with TrayListener {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TrayListener {
  int _idx = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    final ns = getIt<NotificationService>();

    // 1. Gérer les clics alors que l'app est déjà ouverte (background/foreground)
    _notificationSub = ns.selectNotificationStream.listen((response) {
      _handleNotificationResponse(response);
    });

    // 2. Gérer le clic qui a lancé l'application totalement fermée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ns.initialResponse != null) {
        _handleNotificationResponse(ns.initialResponse!);
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    // Action lors d'un clic gauche sur l'icône de la barre système
    // Vous pourriez vouloir restaurer la fenêtre ici
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'exit_app') {
      exit(0);
    } else if (menuItem.key == 'show_window') {
      // Logique pour ramener la fenêtre au premier plan
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (payload == 'open_transfers') {
      _navigateToTransfers();
      return;
    }

    if (payload == 'open_sync_errors') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SyncErrorScreen()),
      );
      return;
    }

    if (response.actionId == 'action_sync_now') {
      getIt<SyncService>().syncPending();
      return;
    }

    // Payload format: 'transfer:ID'
    if (payload.startsWith('transfer:')) {
      final transferId = int.tryParse(payload.split(':')[1]);
      if (transferId != null) {
        if (response.actionId == 'action_mark_received') {
          _showReceiveQuantityDialog(transferId);
        } else {
          _navigateToTransfers();
        }
      }
    }
  }

  void _showMobileMenu(
    List<
      ({
        bool adminOnly,
        _NavDest dest,
        String? feature,
        Widget screen,
        String title,
      })
    >
    pages,
  ) {
    final hiddenPages = pages.skip(3).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => _MobileMoreMenu(
        pages: hiddenPages,
        currentIndex: _idx,
        onSelect: (indexInMenu) {
          // On cherche l'index global de la page sélectionnée dans la liste originale
          final selectedDest = hiddenPages[indexInMenu].dest;
          final globalIdx = pages.indexWhere((p) => p.dest == selectedDest);
          if (globalIdx != -1) {
            setState(() => _idx = globalIdx);
          }
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showReceiveQuantityDialog(int transferId) async {
    final db = context.read<PosDatabase>();
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    final itemsWithProducts = await db.getStockTransferItemsWithProducts(
      transferId,
    );
    if (itemsWithProducts.isEmpty) return;

    final Map<int, int> actualQuantities = {
      for (var item in itemsWithProducts) item.item.id: item.item.quantitySent,
    };

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Réception de stock',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vérifiez les quantités reçues :',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: itemsWithProducts.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: AppColors.border.withValues(alpha: 0.5)),
                    itemBuilder: (context, index) {
                      final item = itemsWithProducts[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Quantité envoyée : ${item.item.quantitySent}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: item.item.quantitySent.toString(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: AppColors.bg.withValues(alpha: 0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) => actualQuantities[item.item.id] =
                                int.tryParse(v) ?? 0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await db.validateStockTransferReception(
                          transferId: transferId,
                          userId: user.id,
                          actualQuantities: actualQuantities,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Réception validée'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Valider la réception'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTransfers() {
    // Nous devons trouver l'index de la page 'Transferts' dans les pages accessibles
    final user = context.read<AuthBloc>().state.user;
    final isAdmin = user?.role == 'admin' || user?.role == 'owner';

    final allPages = [
      (label: 'Caisse', adminOnly: false),
      (label: 'Produits', adminOnly: false),
      (label: 'Inventaire', adminOnly: false),
      (label: 'Réception', adminOnly: false),
      (label: 'Transferts', adminOnly: false),
      (label: 'Ventes', adminOnly: false),
      (label: 'Clients', adminOnly: false),
      (label: 'Fournisseurs', adminOnly: false),
      (label: 'Dépenses', adminOnly: true), // Souvent restreint aux admins
      (label: 'Rapports', adminOnly: true),
      (label: 'Multi-Shop', adminOnly: true),
      (label: 'Paramètres', adminOnly: true),
    ];

    final accessiblePages = allPages
        .where((p) => !p.adminOnly || isAdmin)
        .toList();
    final targetIdx = accessiblePages.indexWhere(
      (p) => p.label == 'Transferts',
    );

    if (targetIdx != -1) {
      setState(() => _idx = targetIdx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final isAdmin = user?.role == 'admin' || user?.role == 'owner';
    final license = getIt<LicenseService>();

    final allPages = [
      (
        dest: const _NavDest(
          Icons.point_of_sale_outlined,
          Icons.point_of_sale,
          'Caisse',
        ),
        screen: const CaisseScreen(),
        title: 'Caisse',
        adminOnly: false,
        feature: null,
      ),
      (
        dest: const _NavDest(
          Icons.inventory_2_outlined,
          Icons.inventory_2,
          'Produits',
        ),
        screen: const ProduitsScreen(),
        title: 'Catalogue produits',
        adminOnly: false,
        feature: null,
      ),
      (
        dest: const _NavDest(
          Icons.checklist_rtl_outlined,
          Icons.checklist_rtl,
          'Inventaire',
        ),
        screen: const InventaireScreen(),
        title: 'Inventaire',
        adminOnly: false,
        feature: null,
      ),
      (
        dest: const _NavDest(
          Icons.assignment_returned_outlined,
          Icons.assignment_returned,
          'Réception',
        ),
        screen: const PurchaseOrderListScreen(),
        title: 'Réception fournisseur',
        adminOnly: false,
        feature: null,
      ),
      (
        dest: const _NavDest(
          Icons.local_shipping_outlined,
          Icons.local_shipping,
          'Transferts',
        ),
        screen: const StockTransferScreen(),
        title: 'Transferts de stock',
        adminOnly: false,
        feature: null,
      ),
      (
        dest: const _NavDest(
          Icons.receipt_long_outlined,
          Icons.receipt_long,
          'Ventes',
        ),
        screen: const SaleHistoryScreen(),
        title: 'Historique des ventes',
        adminOnly: false,
        feature: null,
      ),
      (
        dest: const _NavDest(Icons.people_outline, Icons.people, 'Clients'),
        screen: const CustomersScreen(),
        title: 'Clients',
        adminOnly: false,
        feature: null,
      ),
      (
        dest: const _NavDest(
          Icons.person_remove_outlined,
          Icons.person_remove,
          'Dettes',
        ),
        screen: const DebtorsScreen(),
        title: 'Portefeuille Dettes',
        adminOnly: false,
        feature: null,
      ),
      (
        dest: const _NavDest(
          Icons.local_shipping_outlined,
          Icons.local_shipping,
          'Fournisseurs',
        ),
        screen: const SuppliersScreen(),
        title: 'Fournisseurs',
        adminOnly: false,
        feature: null,
      ),
      (
        dest: const _NavDest(
          Icons.money_off_csred_outlined,
          Icons.money_off,
          'Dépenses',
        ),
        screen: const ExpensesScreen(),
        title: 'Dépenses',
        adminOnly: true,
        feature: null,
      ),
      (
        dest: const _NavDest(
          Icons.bar_chart_outlined,
          Icons.bar_chart,
          'Rapports',
        ),
        screen: const ReportsScreen(),
        title: 'Rapports',
        adminOnly: true,
        feature: 'reports',
      ),
      (
        dest: const _NavDest(
          Icons.cloud_circle_outlined,
          Icons.cloud_circle,
          'Multi-Shop',
        ),
        screen: const OwnerDashboardScreen(),
        title: 'Dashboard Cloud',
        adminOnly: true,
        feature: 'multi_store',
      ),
      (
        dest: const _NavDest(
          Icons.settings_outlined,
          Icons.settings,
          'Paramètres',
        ),
        screen: const SettingsScreen(),
        title: 'Paramètres',
        adminOnly: true,
        feature: null,
      ),
    ];

    final accessiblePages = allPages
        .where((p) => !p.adminOnly || isAdmin)
        .toList();
    if (_idx >= accessiblePages.length) _idx = 0;

    final destinations = accessiblePages.map((p) => p.dest).toList();
    final titles = accessiblePages.map((p) => p.title).toList();
    final isWide = MediaQuery.of(context).size.width >= 720;

    final screens = accessiblePages.map((p) {
      if (p.feature != null && !license.canAccess(p.feature!)) {
        return LicenseGate(feature: p.feature!, child: p.screen);
      }
      return p.screen;
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isWide ? _buildDrawer(accessiblePages) : null,
      body: AppBackground(
        child: isWide
            ? _wideLayout(destinations, screens, titles)
            : _narrowLayout(destinations, screens, titles, accessiblePages),
      ),
    );
  }

  Widget _buildDrawer(
    List<
      ({
        bool adminOnly,
        _NavDest dest,
        String? feature,
        Widget screen,
        String title,
      })
    >
    pages,
  ) {
    final user = context.read<AuthBloc>().state.user;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: AppColors.gradientMain(context),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', height: 60),
                  const SizedBox(height: 10),
                  Text(
                    user?.name ?? 'Utilisateur',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    user?.role.toUpperCase() ?? '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: pages.length,
              itemBuilder: (context, i) {
                final p = pages[i];
                return ListTile(
                  leading: _NavIconWithBadge(
                    destination: p.dest,
                    selected: _idx == i,
                    isRail: false,
                  ),
                  title: Text(
                    p.dest.label,
                    style: TextStyle(
                      color: _idx == i
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: _idx == i
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: _idx == i,
                  onTap: () {
                    setState(() => _idx = i);
                    Navigator.pop(context); // Ferme le menu
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideLayout(
    List<_NavDest> destinations,
    List<Widget> screens,
    List<String> titles,
  ) {
    return Row(
      children: [
        _SideRail(
          selectedIndex: _idx,
          destinations: destinations,
          onSelect: (i) => setState(() => _idx = i),
        ),
        Expanded(
          child: Column(
            children: [
              _TopBar(title: titles[_idx], showCartBadge: _idx == 0),
              _GlobalSyncProgressBar(),
              Expanded(
                child: IndexedStack(index: _idx, children: screens),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout(
    List<_NavDest> destinations,
    List<Widget> screens,
    List<String> titles,
    List<
      ({
        bool adminOnly,
        _NavDest dest,
        String? feature,
        Widget screen,
        String title,
      })
    >
    accessiblePages,
  ) {
    return Column(
      children: [
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 6,
                left: 16,
                right: 16, // Ligne 433
                bottom: 10,
              ), // Use withValues
              decoration: const BoxDecoration(
                color:
                    Colors.transparent, // Laisse passer le flou et le dégradé
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    tooltip: 'Menu principal',
                  ),
                  const SizedBox(width: 10),
                  Text(
                    titles[_idx],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Toggle Thème Mobile
                  BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, state) {
                      final isDark = state.themeMode == ThemeMode.dark;
                      return IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 20,
                          color: isDark
                              ? Colors.amber
                              : AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            context.read<ThemeBloc>().add(ToggleTheme()),
                      );
                    },
                  ),
                  if (_idx == 0) const _SessionTotalDisplay(mobile: true),
                  if (_idx == 0)
                    IconButton(
                      icon: const Icon(Icons.lock_outline, size: 22),
                      tooltip: 'Fermer la session de caisse',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CloseCashDrawerScreen(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        _GlobalSyncProgressBar(),
        Expanded(
          child: IndexedStack(index: _idx, children: screens),
        ),
        _BottomNav(
          selectedIndex: _idx,
          destinations: destinations.take(3).toList(),
          hiddenDestinations: destinations.skip(3).toList(),
          onSelect: (i) => setState(() => _idx = i),
          onMenuPressed: () => _showMobileMenu(accessiblePages),
        ),
      ],
    );
  }
}

// ── RAIL LATÉRAL ─────────────────────────────────────────────
class _SideRail extends StatelessWidget {
  final int selectedIndex;
  final List<_NavDest> destinations;
  final ValueChanged<int> onSelect;

  const _SideRail({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72, // Largeur standard Shopify POS
      decoration: const BoxDecoration(
        color: Color(0xFF202223), // Shopify Ink (fond sombre solide)
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Logo épuré sans conteneur coloré
          Image.asset('assets/logo.png', height: 32),

          const SizedBox(height: 32),

          Expanded(
            child: Column(
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: destinations.asMap().entries.map((e) {
                        final i = e.key;
                        final d = e.value;
                        final selected = selectedIndex == i;
                        return Material(
                          color: Colors.transparent,
                          child: Tooltip(
                            message: d.label,
                            preferBelow: false,
                            child: InkWell(
                              onTap: () => onSelect(i),
                              hoverColor: Colors.white.withValues(alpha: 0.05),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Indicateur vertical Shopify Green
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 200),
                                    left: 0,
                                    width: selected ? 3 : 0,
                                    height: selected ? 40 : 0,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.horizontal(
                                          right: Radius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Item de navigation
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.transparent,
                                    ),
                                    child: _NavIconWithBadge(
                                      destination: d,
                                      selected: selected,
                                      isRail: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Bas du rail
                _SyncStatusDot(),
                const SizedBox(height: 16),
                Tooltip(
                  message: 'Déconnexion',
                  child: InkWell(
                    onTap: () =>
                        context.read<AuthBloc>().add(LogoutRequested()),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 22,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── BARRE DE PROGRESSION GLOBALE ──────────────────────────────
class _GlobalSyncProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncProgress>(
      stream: getIt<SyncService>().statusStream,
      initialData: getIt<SyncService>().currentProgress,
      builder: (context, snapshot) {
        final progress = snapshot.data;

        // On affiche la barre si on synchronise OU si le résultat est partiel
        final bool isSyncing = progress?.status == SyncStatus.syncing;
        final bool isPartial = progress?.status == SyncStatus.partialError;

        if (progress == null || (!isSyncing && !isPartial)) {
          return const SizedBox(height: 0);
        }

        // Couleur : Bleue par défaut, Orange (warning) si la synchronisation est partielle
        final color = isPartial ? AppColors.warning : AppColors.primary;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            // Ligne 599
            LinearProgressIndicator(
              // Use withValues
              value: isPartial ? 1.0 : progress.value,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: isPartial ? 3.0 : 2.5,
            ),
            if (isPartial)
              Positioned(
                right: 16,
                top:
                    -10, // Fait flotter l'icône juste au-dessus de la ligne orange
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SyncErrorScreen(),
                    ), // Ligne 613
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.priority_high_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── BARRE DU HAUT ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final bool showCartBadge;

  const _TopBar({required this.title, this.showCartBadge = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56, // Hauteur standard Shopify Admin
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          FutureBuilder<String?>(
            future: context.read<PosDatabase>().getSetting('terminal_name'),
            builder: (context, snap) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  snap.data?.toUpperCase() ?? 'CAISSE',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          // --- NOUVEAU : Toggle Thème (Jour/Nuit) ---
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              final isDark = state.themeMode == ThemeMode.dark;
              return IconButton(
                tooltip: isDark
                    ? 'Passer au mode clair'
                    : 'Passer au mode sombre',
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: isDark ? Colors.amber : AppColors.textSecondary,
                ),
                onPressed: () => context.read<ThemeBloc>().add(ToggleTheme()),
              );
            },
          ),
          const SizedBox(width: 8),
          _SyncStatusIcon(),
          if (showCartBadge)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: _SessionTotalDisplay(),
            ),
          if (showCartBadge)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Fermer la caisse',
                icon: const Icon(Icons.lock_outline, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CloseCashDrawerScreen(),
                  ),
                ),
              ),
            ),
          if (showCartBadge)
            BlocBuilder<CartBloc, CartState>(
              builder: (_, cart) => cart.isEmpty
                  ? const SizedBox.shrink()
                  : _AnimatedCartBadge(cart: cart),
            ),
        ],
      ),
    );
  }
}

class _AnimatedCartBadge extends StatefulWidget {
  final CartState cart;
  const _AnimatedCartBadge({required this.cart});

  @override
  State<_AnimatedCartBadge> createState() => _AnimatedCartBadgeState();
}

class _AnimatedCartBadgeState extends State<_AnimatedCartBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_AnimatedCartBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // On déclenche l'animation si le nombre total d'articles a augmenté
    if (widget.cart.itemCount > oldWidget.cart.itemCount) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          // Ligne 710
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.accentDark],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 6, // Ligne 714
              offset: const Offset(0, 3),
            ),
          ],
        ), // Use withValues
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ligne 717
            const Icon(Icons.shopping_cart, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${widget.cart.itemCount} · ${Fmt.currency(widget.cart.totalTtc)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TOTAL SESSION ─────────────────────────────────────────────
class _SessionTotalDisplay extends StatelessWidget {
  final bool mobile;
  const _SessionTotalDisplay({this.mobile = false});

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<CashSessionBloc>().state;
    if (sessionState is! CashSessionOpen) return const SizedBox.shrink();

    return StreamBuilder<List<Sale>>(
      stream: context.read<PosDatabase>().salesDao.watchSessionSales(
        sessionState.session.id,
      ),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? [];
        final total = sales.fold(
          0.0,
          (sum, s) => sum + s.totalTtc - s.refundedAmount,
        ); // Already correct

        if (mobile) {
          return Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successSoft, // Ligne 765
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              Fmt.currency(total),
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          );
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'TOTAL SESSION',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              Fmt.currency(total),
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── BOTTOM NAV ────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_NavDest> destinations;
  final List<_NavDest> hiddenDestinations;
  final ValueChanged<int> onSelect;
  final VoidCallback onMenuPressed;

  const _BottomNav({
    required this.selectedIndex,
    required this.destinations,
    required this.hiddenDestinations,
    required this.onSelect,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    // Ligne 800
                    // Ligne 800
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ...destinations.asMap().entries.map((e) {
                    final i = e.key;
                    final d = e.value;
                    final selected = selectedIndex == i;
                    return _BottomNavItem(
                      destination: d,
                      selected: selected,
                      onTap: () => onSelect(i),
                    );
                  }),
                  _BottomNavItem(
                    destination: const _NavDest(
                      Icons.grid_view_rounded,
                      Icons.grid_view_rounded,
                      'Menu',
                    ),
                    selected: selectedIndex >= 3,
                    onTap: onMenuPressed,
                    isMenu: true,
                    hiddenDestinations: hiddenDestinations,
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

class _BottomNavItem extends StatelessWidget {
  final _NavDest destination;
  final bool selected;
  final VoidCallback onTap;
  final bool isMenu;
  final List<_NavDest>? hiddenDestinations;

  const _BottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.isMenu = false,
    this.hiddenDestinations,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isMenu
                  ? _MenuIconWithBadge(
                      icon: destination.icon,
                      selected: selected,
                      hiddenDestinations: hiddenDestinations ?? [],
                    )
                  : _NavIconWithBadge(
                      destination: destination,
                      selected: selected,
                      isRail: false,
                    ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileMoreMenu extends StatelessWidget {
  final List<
    ({
      bool adminOnly,
      _NavDest dest,
      String? feature,
      Widget screen,
      String title,
    })
  >
  pages;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _MobileMoreMenu({
    required this.pages,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Fonctionnalités',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final p = pages[index];
                  // Réutilisation de NavIconWithBadge pour afficher les notifications (Transferts, etc.) dans le menu
                  return InkWell(
                    onTap: () => onSelect(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _NavIconWithBadge(
                          destination: p.dest,
                          selected: false,
                          isRail: false,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.dest.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MenuIconWithBadge extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final List<_NavDest> hiddenDestinations;

  const _MenuIconWithBadge({
    required this.icon,
    required this.selected,
    required this.hiddenDestinations,
  });

  @override
  Widget build(BuildContext context) {
    final db = context.read<PosDatabase>();
    final baseIcon = Icon(
      icon,
      size: 22,
      color: selected ? AppColors.primary : AppColors.textMuted,
    );

    return FutureBuilder<String?>(
      future: db.getSetting('shop_id'),
      builder: (context, shopSnap) {
        final shopId = shopSnap.data;
        if (shopId == null || shopId.isEmpty) return baseIcon;

        // On vérifie si les destinations qui supportent les badges sont dans le menu
        final hasTransfers = hiddenDestinations.any(
          (d) => d.label == 'Transferts',
        );
        final hasReception = hiddenDestinations.any(
          (d) => d.label == 'Réception',
        );

        if (!hasTransfers && !hasReception) return baseIcon;

        return StreamBuilder<int>(
          stream: hasTransfers
              ? db.watchIncomingTransfersCount(shopId)
              : Stream.value(0),
          builder: (context, transferSnap) {
            return StreamBuilder<int>(
              stream: hasReception
                  ? db.watchPendingPurchaseOrders().map((l) => l.length)
                  : Stream.value(0),
              builder: (context, purchaseSnap) {
                final total =
                    (transferSnap.data ?? 0) + (purchaseSnap.data ?? 0);

                if (total == 0) return baseIcon;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    baseIcon,
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── WIDGET HELPER : ICÔNE AVEC BADGE DE NOTIFICATION ──────────
class _NavIconWithBadge extends StatefulWidget {
  final _NavDest destination;
  final bool selected;
  final bool isRail;

  const _NavIconWithBadge({
    required this.destination,
    required this.selected,
    required this.isRail,
  });

  @override
  State<_NavIconWithBadge> createState() => _NavIconWithBadgeState();
}

class _NavIconWithBadgeState extends State<_NavIconWithBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnimation = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le widget de base (Icone)
    final Widget baseIcon = Icon(
      widget.selected ? widget.destination.activeIcon : widget.destination.icon,
      size: widget.isRail
          ? 24
          : 22, // Légèrement plus petit pour plus d'élégance
      color: widget.isRail
          ? (widget.selected ? Colors.white : Colors.white54)
          : (widget.selected ? AppColors.primary : AppColors.textSecondary),
    );

    // On affiche le badge pour les Transferts, les Réceptions et les Produits (Alertes)
    if (widget.destination.label != 'Transferts' &&
        widget.destination.label != 'Réception' &&
        widget.destination.label != 'Produits') {
      return baseIcon;
    }

    final db = context.read<PosDatabase>();

    return FutureBuilder<String?>(
      future: db.getSetting('shop_id'),
      builder: (context, shopSnap) {
        final shopId = shopSnap.data;
        if (shopId == null || shopId.isEmpty) return baseIcon;

        // Flux pour les alertes de stock bas (badge normal)
        final lowStockStream = switch (widget.destination.label) {
          'Transferts' => db.watchIncomingTransfersCount(shopId),
          'Réception' => db.watchPendingPurchaseOrders().map((l) => l.length),
          'Produits' => db.watchProductAlertsCount(shopId),
          _ => Stream.value(0),
        };

        // Flux pour les ruptures de stock critiques (icône clignotante)
        final criticalStockStream = widget.destination.label == 'Produits'
            ? db.watchCriticalOutOfStockProductsCount(shopId)
            : Stream.value(0);

        return StreamBuilder<int>(
          // Stream pour les alertes critiques
          stream: criticalStockStream,
          builder: (context, criticalSnap) {
            final criticalCount = criticalSnap.data ?? 0;

            if (criticalCount > 0 && widget.destination.label == 'Produits') {
              // Si rupture critique, afficher l'icône de cloche clignotante
              return FadeTransition(
                opacity: _blinkAnimation,
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: widget.isRail ? 24 : 22,
                  color: AppColors.danger, // Couleur rouge pour l'alerte
                ),
              );
            }

            // Sinon, revenir à la logique du badge normal pour les autres alertes
            return StreamBuilder<int>(
              stream: lowStockStream,
              builder: (context, lowStockSnap) {
                final lowStockCount = lowStockSnap.data ?? 0;
                if (lowStockCount == 0) return baseIcon;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    baseIcon,
                    Positioned(
                      right: widget.isRail ? -2 : -4,
                      top: widget.isRail ? -2 : -4,
                      child: Container(
                        padding: const EdgeInsets.all(4), // Ligne 1103
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 1.5),
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            lowStockCount > 9 ? '9+' : '$lowStockCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── ICÔNE SYNC ────────────────────────────────────────────────
class _SyncStatusIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: getIt<SyncService>().statusStream.map((p) => p.status),
      initialData: getIt<SyncService>()
          .currentStatus, // Utilise l'état actuel au démarrage
      builder: (_, snap) {
        final status = snap.data ?? SyncStatus.idle;
        IconData icon;
        Color color;
        switch (status) {
          case SyncStatus.syncing:
            icon = Icons.sync;
            color = AppColors.info;
            break;
          case SyncStatus.upToDate:
            icon = Icons.cloud_done_outlined;
            color = AppColors.success;
            break;
          case SyncStatus.error:
            icon = Icons.cloud_off_outlined;
            color = AppColors.danger;
            break;
          case SyncStatus.partialError:
            icon = Icons.sync_problem;
            color = AppColors.warning;
            break;
          default:
            icon = Icons.cloud_outlined;
            color = Colors.white.withValues(alpha: 0.6);
        }
        final tooltip = switch (status) {
          SyncStatus.syncing => 'Synchronisation en cours...',
          SyncStatus.upToDate => 'Données synchronisées',
          SyncStatus.error => 'Erreur de synchronisation',
          SyncStatus.partialError => 'Sync partielle — réessai en cours',
          _ => 'Hors ligne',
        };
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SyncErrorScreen()),
          ),
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(icon, size: 18, color: color),
            ),
          ),
        );
      },
    );
  }
}

// ── POINT SYNC (rail) ─────────────────────────────────────────
class _SyncStatusDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: getIt<SyncService>().statusStream.map((p) => p.status),
      initialData: getIt<SyncService>()
          .currentStatus, // Utilise l'état actuel au démarrage
      builder: (_, snap) {
        final status = snap.data ?? SyncStatus.idle;
        Color color;
        switch (status) {
          case SyncStatus.syncing:
            color = AppColors.info;
            break;
          case SyncStatus.upToDate:
            color = AppColors.success;
            break;
          case SyncStatus.error:
            color = AppColors.danger;
            break;
          case SyncStatus.partialError:
            color = AppColors.warning;
            break;
          default:
            color = Colors.white.withValues(alpha: 0.6);
        }
        return Tooltip(
          message: switch (status) {
            SyncStatus.syncing => 'Sync en cours...',
            SyncStatus.upToDate => 'Synchronisé',
            SyncStatus.error => 'Erreur sync',
            _ => 'Hors ligne',
          },
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
          ),
        );
      },
    );
  }
}
