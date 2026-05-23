import 'package:flutter/material.dart';
import '../widgets/main_sidebar.dart';
import 'reports/owner_dashboard_screen.dart';
import 'caisse/caisse_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _db = getIt<PosDatabase>();
  int _currentIndex = 0;

  // Liste des pages correspondant aux index de la sidebar
  final List<Widget> _pages = [
    const OwnerDashboardScreen(),
    const CaisseScreen(),
    const Center(child: Text('Catalogue')),
    const Center(child: Text('Stocks')),
    const Center(child: Text('Ventes')),
    const Center(child: Text('Clients')),
    const Center(child: Text('Paramètres')),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 650;
    final bool isTablet = width >= 650 && width < 1100;

    return Scaffold(
      // Sur mobile, on affiche l'AppBar pour avoir accès au bouton hamburger
      appBar: isMobile
          ? AppBar(
              title: const Text('GPOS Cloud'),
              backgroundColor: AppColors.surface,
              elevation: 0,
            )
          : null,

      // Le Drawer utilise notre MainSidebar existante
      drawer: isMobile ? Drawer(width: 280, child: _buildSidebar(false)) : null,

      body: Row(
        children: [
          // Si on n'est pas sur mobile, la sidebar est injectée directement dans le body
          if (!isMobile) _buildSidebar(isTablet),

          Expanded(
            child: Container(
              color: AppColors.bg,
              // On utilise un IndexedStack pour garder l'état des pages
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool collapsed) {
    // On simule un shopId, idéalement récupéré depuis vos préférences
    const String shopId = 'current_shop_id';

    return StreamBuilder<int>(
      stream: _db.watchIncomingTransfersCount(shopId),
      builder: (context, snapshot) {
        return MainSidebar(
          currentIndex: _currentIndex,
          isCollapsed: collapsed,
          userName: 'Admin',
          userRole: 'Propriétaire',
          notifications: {
            3: snapshot.data ?? 0,
          }, // Index 3 = Commandes & Stocks
          onIndexChanged: (index) {
            setState(() => _currentIndex = index);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }
}
