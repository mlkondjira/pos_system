import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MainSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;
  final String userName;
  final String userRole;
  final bool isCollapsed;
  final Map<int, int> notifications;

  const MainSidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.userName,
    required this.userRole,
    this.isCollapsed = false,
    this.notifications = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Si on est dans un Drawer, l'AnimatedContainer doit prendre toute la largeur disponible
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isCollapsed
          ? 100
          : (Navigator.canPop(context) ? double.infinity : 280),
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(
          alpha: Navigator.canPop(context) ? 1.0 : 0.8,
        ),
        border: const Border(
          right: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // --- Header / Logo ---
              _buildHeader(),

              // --- Navigation Items ---
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  children: [
                    _buildSectionLabel('PILOTAGE'),
                    _buildNavItem(
                      0,
                      'Tableau de Bord',
                      Icons.dashboard_customize_outlined,
                      AppColors.primary,
                    ),
                    _buildNavItem(
                      1,
                      'Caisse Rapide',
                      Icons.point_of_sale_rounded,
                      AppColors.accent,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionLabel('INVENTAIRE'),
                    _buildNavItem(
                      2,
                      'Catalogue Produits',
                      Icons.inventory_2_outlined,
                      Colors.orange,
                    ),
                    _buildNavItem(
                      3,
                      'Commandes & Stocks',
                      Icons.local_shipping_outlined,
                      Colors.purple,
                      badgeCount: notifications[3],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionLabel('FINANCE & CLIENTS'),
                    _buildNavItem(
                      4,
                      'Historique Ventes',
                      Icons.receipt_long_outlined,
                      AppColors.info,
                    ),
                    _buildNavItem(
                      5,
                      'Gestion Clients',
                      Icons.people_alt_outlined,
                      Colors.pink,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionLabel('SYSTÈME'),
                    _buildNavItem(
                      6,
                      'Paramètres',
                      Icons.settings_suggest_outlined,
                      AppColors.textMuted,
                    ),
                  ],
                ),
              ),

              // --- User Profile Footer ---
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isCollapsed ? 0 : 24,
        60,
        isCollapsed ? 0 : 24,
        30,
      ),
      child: Row(
        mainAxisAlignment: isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_graph_rounded,
            size: 28,
            color: AppColors.primary,
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPOS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'SYSTEM CLOUD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    if (isCollapsed) {
      return const Divider(
        height: 32,
        indent: 20,
        endIndent: 20,
        color: AppColors.border,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData icon,
    Color accentColor, {
    int? badgeCount,
  }) {
    final isSelected = currentIndex == index;
    final hasBadge = badgeCount != null && badgeCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onIndexChanged(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              // On réutilise notre widget LiquidGlassIcon
              Transform.scale(
                scale: 0.8,
                child: Badge(
                  label: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  isLabelVisible: hasBadge,
                  backgroundColor: AppColors.danger,
                  offset: const Offset(8, -8),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? accentColor : AppColors.textMuted,
                  ),
                ),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              userName[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    userRole.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.dangerLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
