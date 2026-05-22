import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/sync_service.dart';
import 'shared_widgets.dart'; // Assumant que StatCard est défini ici

class GrossMarginCard extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? terminalId;

  const GrossMarginCard({
    super.key,
    required this.startDate,
    required this.endDate,
    this.terminalId,
  });

  @override
  Widget build(BuildContext context) {
    // Accéder à SyncService via getIt ou BlocProvider si vous l'avez configuré ainsi
    final syncService = getIt<SyncService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: syncService.getDashboardStats(
        startDate: startDate,
        endDate: endDate,
        terminalId: terminalId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const StatCard(
            title: 'Marge Brute',
            value: '...',
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
          );
        }
        if (snapshot.hasError) {
          return StatCard(
            title: 'Marge Brute',
            value: 'Erreur',
            icon: Icons.error_outline,
            color: AppColors.danger,
            tooltip: snapshot.error.toString(),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const StatCard(
            title: 'Marge Brute',
            value: 'N/A',
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
          );
        }

        final grossMargin = snapshot.data!['gross_margin'] as double? ?? 0.0;

        return StatCard(
          title: 'Marge Brute',
          value: Fmt.currency(grossMargin),
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        );
      },
    );
  }
}
