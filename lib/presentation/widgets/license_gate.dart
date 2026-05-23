// lib/presentation/widgets/license_gate.dart
// ============================================================
//  Widget garde-barrière de licence
//  Bloque l'accès aux features premium et affiche une CTA
//  Usage :
//    LicenseGate(
//      feature: 'reports',
//      child: ReportsScreen(),
//    )
// ============================================================
import 'package:flutter/material.dart';
import '../../core/services/license_service.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../screens/subscription/subscription_screen.dart';

class LicenseGate extends StatelessWidget {
  final String feature;
  final Widget child;
  final Widget? fallback; // Widget alternatif (optionnel)

  const LicenseGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final license = getIt<LicenseService>();

    return StreamBuilder<LicenseState>(
      stream: license.stateStream,
      initialData: license.currentState,
      builder: (context, snap) {
        final state = snap.data ?? license.currentState;

        if (state.canAccess(feature)) {
          return child;
        }

        return fallback ?? _UpgradePrompt(feature: feature);
      },
    );
  }
}

// ── PROMPT D'UPGRADE ──────────────────────────────────────────

class _UpgradePrompt extends StatelessWidget {
  final String feature;
  const _UpgradePrompt({required this.feature});

  @override
  Widget build(BuildContext context) {
    final info = _featureInfo(feature);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primaryLight,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              info.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'SpaceGrotesk',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              info.description,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Disponible en plan ${info.requiredPlan}',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              ),
              icon: const Icon(
                  Icons.rocket_launch_outlined,
                  size: 16),
              label: const Text('Voir les plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _FeatureInfo _featureInfo(String feature) {
    switch (feature) {
      case 'reports':
        return const _FeatureInfo(
          title: 'Rapports avancés',
          description:
              'Accédez aux graphiques de CA, top produits, '
              'analyse TVA et exports CSV/PDF.',
          requiredPlan: 'Pro',
        );
      case 'sync':
        return const _FeatureInfo(
          title: 'Synchronisation cloud',
          description:
              'Synchronisez vos données sur tous vos appareils '
              'et accédez à vos ventes depuis n\'importe où.',
          requiredPlan: 'Pro',
        );
      case 'multi_store':
        return const _FeatureInfo(
          title: 'Dashboard multi-magasins',
          description:
              'Gérez tous vos points de vente depuis un seul '
              'écran et comparez leurs performances.',
          requiredPlan: 'Premium',
        );
      case 'ai_reports':
        return const _FeatureInfo(
          title: 'Rapports IA WhatsApp',
          description:
              'Recevez chaque lundi un rapport intelligent '
              'analysé par IA directement sur votre WhatsApp.',
          requiredPlan: 'Premium',
        );
      default:
        return const _FeatureInfo(
          title: 'Fonctionnalité premium',
          description:
              'Cette fonctionnalité nécessite un abonnement.',
          requiredPlan: 'Pro',
        );
    }
  }
}

class _FeatureInfo {
  final String title;
  final String description;
  final String requiredPlan;
  const _FeatureInfo({
    required this.title,
    required this.description,
    required this.requiredPlan,
  });
}

// ── BANNER COMPACT (pour les écrans partiellement limités) ────

class LicenseBanner extends StatelessWidget {
  final String feature;
  final String message;

  const LicenseBanner({
    super.key,
    required this.feature,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final license = getIt<LicenseService>();

    if (license.canAccess(feature)) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SubscriptionScreen(),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.lock_outline_rounded,
              size: 14, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryLight)),
          ),
          const Text('Upgrader →',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ]),
      ),
    );
  }
}
