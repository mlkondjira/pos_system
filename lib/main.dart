// ============================================================
//  main.dart — Point d'entrée POS System
//  Flutter multiplateforme : Android · iOS · Windows · macOS · Linux
// ============================================================
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'core/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'core/utils/formatters.dart';
import 'core/ui/liquid_glass_icon.dart';
import 'core/constants/supabase_config.dart';
import 'data/database/pos_database.dart';
import 'data/services/sync_service.dart';
import 'presentation/blocs/auth_bloc.dart' hide AppStarted;
import 'presentation/blocs/cash_session_bloc.dart';
import 'presentation/blocs/cart_bloc.dart';
import 'login_screen.dart';
import 'presentation/screens/cash_drawer/open_cash_drawer_screen.dart';
import 'presentation/screens/cash_drawer/close_cash_drawer_screen.dart';
import 'presentation/screens/caisse/caisse_screen.dart';
import 'presentation/screens/produits/produits_screen.dart';
import 'presentation/screens/inventaire/inventaire_screen.dart';
import 'presentation/screens/inventory/stock_transfer_screen.dart';
import 'presentation/screens/sales/sale_history_screen.dart';
import 'presentation/screens/customers/customers_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'presentation/screens/reports/owner_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

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

  try {
    await getIt<SyncService>().initialize();
  } on PlatformException catch (e) {
    debugPrint('Failed to initialize connectivity listener: $e');
  }

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
                  CashSessionBloc(getIt<PosDatabase>())..add(AppStarted())),
        ],
        child: MaterialApp(
          title: 'POS System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.isBeingForceLoggedOut) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compte désactivé, déconnexion en cours...'),
                    backgroundColor: AppColors.danger,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (!authState.isAuthenticated) return const LoginScreen();
                return BlocBuilder<CashSessionBloc, CashSessionState>(
                  builder: (context, sessionState) {
                    if (sessionState is CashSessionLoading ||
                        sessionState is CashSessionInitial) {
                      return const Scaffold(
                          body: Center(child: CircularProgressIndicator()));
                    }
                    if (sessionState is NoCashSession) {
                      return const OpenCashDrawerScreen();
                    }
                    return const AppShell();
                  },
                );
              },
            ),
          ),
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

// ── SHELL PRINCIPAL ──────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final isAdmin = user?.role == 'admin' || user?.role == 'owner';

    final allPages = [
      (dest: const _NavDest(Icons.point_of_sale_outlined, Icons.point_of_sale, 'Caisse'), screen: const CaisseScreen(), title: 'Caisse', adminOnly: false),
      (dest: const _NavDest(Icons.inventory_2_outlined, Icons.inventory_2, 'Produits'), screen: const ProduitsScreen(), title: 'Catalogue produits', adminOnly: false),
      (dest: const _NavDest(Icons.checklist_rtl_outlined, Icons.checklist_rtl, 'Inventaire'), screen: const InventaireScreen(), title: 'Inventaire', adminOnly: false),
      (dest: const _NavDest(Icons.local_shipping_outlined, Icons.local_shipping, 'Transferts'), screen: const StockTransferScreen(), title: 'Transferts de stock', adminOnly: false),
      (dest: const _NavDest(Icons.receipt_long_outlined, Icons.receipt_long, 'Ventes'), screen: const SaleHistoryScreen(), title: 'Historique des ventes', adminOnly: false),
      (dest: const _NavDest(Icons.people_outline, Icons.people, 'Clients'), screen: const CustomersScreen(), title: 'Clients', adminOnly: false),
      (dest: const _NavDest(Icons.bar_chart_outlined, Icons.bar_chart, 'Rapports'), screen: const ReportsScreen(), title: 'Rapports', adminOnly: true),
      (dest: const _NavDest(Icons.cloud_circle_outlined, Icons.cloud_circle, 'Multi-Shop'), screen: const OwnerDashboardScreen(), title: 'Dashboard Cloud', adminOnly: true),
      (dest: const _NavDest(Icons.settings_outlined, Icons.settings, 'Paramètres'), screen: const SettingsScreen(), title: 'Paramètres', adminOnly: true),
    ];

    final accessiblePages =
        allPages.where((p) => !p.adminOnly || isAdmin).toList();
    if (_idx >= accessiblePages.length) _idx = 0;

    final destinations = accessiblePages.map((p) => p.dest).toList();
    final screens = accessiblePages.map((p) => p.screen).toList();
    final titles = accessiblePages.map((p) => p.title).toList();
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA), // Indigo
              Color(0xFF764BA2), // Violet
              Color(0xFFF093FB), // Rose clair
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: isWide
            ? _wideLayout(destinations, screens, titles)
            : _narrowLayout(destinations, screens, titles),
      ),
    );
  }

  Widget _wideLayout(List<_NavDest> destinations, List<Widget> screens,
      List<String> titles) {
    return Row(children: [
      _SideRail(
        selectedIndex: _idx,
        destinations: destinations,
        onSelect: (i) => setState(() => _idx = i),
      ),
      Expanded(
        child: Column(children: [
          _TopBar(title: titles[_idx], showCartBadge: _idx == 0),
          Expanded(child: screens[_idx]),
        ]),
      ),
    ]);
  }

  Widget _narrowLayout(List<_NavDest> destinations, List<Widget> screens,
      List<String> titles) {
    return Column(children: [
      ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withValues(alpha: 0.15),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              left: 16,
              right: 16,
              bottom: 10,
            ),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child:
                    const Icon(Icons.point_of_sale, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(titles[_idx],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (_idx == 0) const _SessionTotalDisplay(mobile: true),
              if (_idx == 0)
                IconButton(
                  icon: const Icon(Icons.lock_outline,
                      color: Colors.white70, size: 22),
                  tooltip: 'Fermer la caisse',
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CloseCashDrawerScreen())),
                ),
            ]),
          ),
        ),
      ),
      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_idx),
            child: screens[_idx],
          ),
        ),
      ),
      _BottomNav(
        selectedIndex: _idx,
        destinations: destinations.take(5).toList(),
        onSelect: (i) => setState(() => _idx = i),
      ),
    ]);
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border(
                right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2))),
          ),
          child: Column(children: [
            const SizedBox(height: 20),

            // Logo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.point_of_sale,
                  color: Colors.white, size: 22),
            ),

            const SizedBox(height: 16),

            // ── CORRECTION : Flexible + SingleChildScrollView ──
            // Remplace Column + Spacer qui débordait avec 9 destinations
            Expanded(
              child: Column(
                children: [
                  // Liste d'icônes scrollable si trop nombreuses
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: destinations.asMap().entries.map((e) {
                          final i = e.key;
                          final d = e.value;
                          final selected = selectedIndex == i;
                          return Tooltip(
                            message: d.label,
                            preferBelow: false,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5),
                              child: GestureDetector(
                                onTap: () => onSelect(i),
                                child: LiquidGlassIcon(
                                  icon: selected ? d.activeIcon : d.icon,
                                  selected: selected,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Bas du rail — fixe, jamais scrollé
                  const SizedBox(height: 8),
                  _StockAlertDot(),
                  const SizedBox(height: 10),
                  _SyncStatusDot(),
                  const SizedBox(height: 10),
                  Tooltip(
                    message: 'Déconnexion',
                    child: InkWell(
                      onTap: () =>
                          context.read<AuthBloc>().add(LogoutRequested()),
                      borderRadius: BorderRadius.circular(12),
                      child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(Icons.logout_rounded,
                            size: 22, color: Colors.white60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ]),
        ),
      ),
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            border: Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2))),
          ),
          child: Row(children: [
            Text(title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                )),
            const Spacer(),
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
                  icon: const Icon(Icons.lock_outline,
                      size: 22, color: Colors.white70),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CloseCashDrawerScreen())),
                ),
              ),
            if (showCartBadge)
              BlocBuilder<CartBloc, CartState>(builder: (_, cart) {
                if (cart.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.shopping_cart,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '${cart.itemCount} · ${Fmt.currency(cart.totalTtc)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ]),
                );
              }),
          ]),
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
      stream: context
          .read<PosDatabase>().salesDao
          .watchSessionSales(sessionState.session.id),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? [];
        final total = sales.fold(0.0, (sum, s) => sum + s.totalTtc);

        if (mobile) {
          return Container(
            margin: const EdgeInsets.only(right: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Text(Fmt.currency(total),
                style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          );
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('TOTAL SESSION',
                style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            Text(Fmt.currency(total),
                style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFamily: 'SpaceGrotesk')),
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
  final ValueChanged<int> onSelect;

  const _BottomNav({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: destinations.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value;
                  final selected = selectedIndex == i;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onSelect(i),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? d.activeIcon : d.icon,
                              size: 24,
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.65),
                            ),
                            const SizedBox(height: 4),
                            Text(d.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.65),
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── INDICATEUR STOCK FAIBLE ───────────────────────────────────
class _StockAlertDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: context.read<PosDatabase>().watchLowStockProducts(),
      builder: (_, snap) {
        final n = snap.data?.length ?? 0;
        if (n == 0) return const SizedBox.shrink();
        return Tooltip(
          message: '$n produit(s) en stock faible',
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 20, color: AppColors.warning),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('$n',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
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
      stream: getIt<SyncService>().statusStream,
      initialData: getIt<SyncService>().currentStatus, // Utilise l'état actuel au démarrage
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
        return Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(icon, size: 18, color: color),
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
      stream: getIt<SyncService>().statusStream,
      initialData: getIt<SyncService>().currentStatus, // Utilise l'état actuel au démarrage
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
            ),
          ),
        );
      },
    );
  }
}