import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';

class MainNavigationLayout extends StatefulWidget {
  const MainNavigationLayout({super.key});

  @override
  State<MainNavigationLayout> createState() => _MainNavigationLayoutState();
}

class _MainNavigationLayoutState extends State<MainNavigationLayout> {
  int _selectedIndex = 0;

  // Liste des destinations partagée entre les deux modes de navigation
  final List<NavDestination> _destinations = [
    NavDestination(icon: Icons.point_of_sale_rounded, label: 'Caisse'),
    NavDestination(icon: Icons.inventory_2_rounded, label: 'Produits'),
    NavDestination(icon: Icons.analytics_rounded, label: 'Rapports'),
    NavDestination(icon: Icons.people_rounded, label: 'Clients'),
    NavDestination(icon: Icons.settings_rounded, label: 'Réglages'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1200;
        final bool isTablet =
            constraints.maxWidth >= 600 &&
            constraints.maxWidth < 1200; // Réintroduit
        final bool isMobile = constraints.maxWidth < 600; // Reste inchangé

        return Scaffold(
          body: AppBackground(
            child: Row(
              children: [
                if (!isMobile)
                  _buildNavigationRail(
                    isDesktop,
                    isTablet,
                  ), // Passage de isTablet
                Expanded(
                  child: ClipRRect(
                    // On peut ajouter un arrondi sur le contenu principal pour l'effet "Dashboard"
                    child: _buildCurrentScreen(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isMobile ? _buildBottomBar() : null,
        );
      },
    );
  }

  Widget _buildNavigationRail(bool extended, bool isTablet) {
    // Ajout de isTablet
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: NavigationRail(
        minWidth: isTablet
            ? 80
            : 72, // Exemple: une largeur compacte légèrement plus grande pour les tablettes
        extended: extended,
        minExtendedWidth: 200,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.7),
        unselectedIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedIconTheme: const IconThemeData(color: Colors.white),
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: _buildLogo(extended),
        ),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) =>
            setState(() => _selectedIndex = index),
        destinations: _destinations.map((d) {
          final bool isSelected = _destinations.indexOf(d) == _selectedIndex;
          return NavigationRailDestination(
            icon: Icon(
              isSelected ? d.icon : d.icon,
              size: 24,
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(
              d.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _destinations
            .map(
              (d) =>
                  BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLogo(bool extended) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: extended
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 28),
          if (extended) ...[
            const SizedBox(width: 12),
            const Text(
              'GPOS',
              style: TextStyle(
                fontWeight: FontWeight.w900, // Ligne 68
                fontSize: 20,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      // Par défaut, AnimatedSwitcher utilise une FadeTransition.
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: Container(
        key: ValueKey<int>(
          _selectedIndex,
        ), // CRUCIAL pour déclencher l'animation
        child: Center(
          child: Text(
            'Écran: ${_destinations[_selectedIndex].label}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class NavDestination {
  final IconData icon;
  final String label;
  NavDestination({required this.icon, required this.label});
}
