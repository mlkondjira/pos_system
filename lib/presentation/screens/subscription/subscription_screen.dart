// lib/presentation/screens/subscription/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/license_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _license = getIt<LicenseService>();

  @override
  void initState() {
    super.initState();
    _license.forceRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Abonnement GPOS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textMuted,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<LicenseState>(
        stream: _license.stateStream,
        initialData: _license.currentState,
        builder: (context, snap) {
          final state = snap.data ?? _license.currentState;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CurrentPlanBanner(state: state),
                const SizedBox(height: 16),
                if (state.isInTrial) ...[
                  _TrialBanner(daysLeft: state.daysLeftInTrial),
                  const SizedBox(height: 12),
                ],
                if (state.isExpired) ...[
                  _ExpiredBanner(),
                  const SizedBox(height: 12),
                ],
                const _SectionTitle('CHOISIR UN PLAN'),
                const SizedBox(height: 10),
                _PlanCard(
                  limits: kPlanFree,
                  isCurrentPlan: state.plan == GposPlan.free,
                  onSelect: null,
                ),
                const SizedBox(height: 10),
                _PlanCard(
                  limits: kPlanPro,
                  isCurrentPlan: state.plan == GposPlan.pro,
                  isRecommended: true,
                  onSelect: state.plan == GposPlan.pro
                      ? null
                      : () => _showPayment(kPlanPro),
                ),
                const SizedBox(height: 10),
                _PlanCard(
                  limits: kPlanPremium,
                  isCurrentPlan: state.plan == GposPlan.premium,
                  onSelect: state.plan == GposPlan.premium
                      ? null
                      : () => _showPayment(kPlanPremium),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('COMPARATIF'),
                const SizedBox(height: 10),
                _CompareTable(),
                const SizedBox(height: 24),
                _SupportCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPayment(PlanLimits plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PaymentSheet(plan: plan),
    );
  }
}

// ── SECTION TITLE ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: AppColors.textMuted,
    ),
  );
}

// ── BANNER PLAN ACTUEL ────────────────────────────────────────

class _CurrentPlanBanner extends StatelessWidget {
  final LicenseState state;
  const _CurrentPlanBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = _planColor(state.plan);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            // Ligne 105
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              // Ligne 117
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_planIcon(state.plan), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan ${state.limits.planName}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                Text(
                  state.isInTrial
                      ? '${state.daysLeftInTrial} jours d\'essai restants'
                      : state.isExpired
                      ? 'Abonnement expiré'
                      : 'Abonnement actif',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (state.isFromCache)
            const Tooltip(
              message: 'Données en cache',
              child: Icon(
                Icons.cloud_off_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Color _planColor(GposPlan p) => switch (p) {
    GposPlan.free => AppColors.textMuted,
    GposPlan.pro => AppColors.primary,
    GposPlan.premium => const Color(0xFF8B5CF6),
  };

  IconData _planIcon(GposPlan p) => switch (p) {
    GposPlan.free => Icons.store_outlined,
    GposPlan.pro => Icons.rocket_launch_outlined,
    GposPlan.premium => Icons.workspace_premium_outlined,
  };
}

// ── BANNERS ───────────────────────────────────────────────────

class _TrialBanner extends StatelessWidget {
  final int daysLeft;
  const _TrialBanner({required this.daysLeft});
  @override
  Widget build(BuildContext context) => _AlertBanner(
    icon: Icons.access_time_rounded,
    color: AppColors.warning,
    soft: AppColors.warningSoft,
    message:
        'Essai Pro — $daysLeft jour${daysLeft > 1 ? 's' : ''} restant${daysLeft > 1 ? 's' : ''}. Passez en Pro pour continuer.',
  );
}

class _ExpiredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const _AlertBanner(
    icon: Icons.error_outline_rounded,
    color: AppColors.danger,
    soft: AppColors.dangerSoft,
    message: 'Abonnement expiré. Certaines fonctionnalités sont limitées.',
  );
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color, soft;
  final String message;
  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.soft,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: soft, // Ligne 191
      borderRadius: BorderRadius.circular(10), // Ligne 191
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    ),
  );
}

// ── PLAN CARD ────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PlanLimits limits;
  final bool isCurrentPlan, isRecommended;
  final VoidCallback? onSelect;
  const _PlanCard({
    required this.limits,
    required this.isCurrentPlan,
    this.isRecommended = false,
    this.onSelect,
  });

  Color get color => switch (limits.plan) {
    GposPlan.free => AppColors.textMuted,
    GposPlan.pro => AppColors.primary,
    GposPlan.premium => const Color(0xFF8B5CF6),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isCurrentPlan // Ligne 230
              ? color
              : isRecommended
              ? color.withValues(alpha: 0.4)
              : AppColors.border,
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isRecommended // Ligne 244
                  ? color.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            limits.planName,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Recommandé',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        limits.priceLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Plan actuel',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (onSelect != null)
                  ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Choisir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Features
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _Feat(
                  'Produits',
                  limits.isUnlimitedProducts
                      ? 'Illimité'
                      : '${limits.maxProducts} max',
                  true,
                ),
                _Feat(
                  'Magasins',
                  limits.isUnlimitedStores
                      ? 'Illimité'
                      : '${limits.maxStores} max',
                  true,
                ),
                _Feat(
                  'Sync cloud',
                  limits.syncEnabled ? 'Inclus' : 'Non inclus',
                  limits.syncEnabled,
                ),
                _Feat(
                  'Rapports avancés',
                  limits.reportsEnabled ? 'Inclus' : 'Non inclus',
                  limits.reportsEnabled,
                ),
                _Feat(
                  'Multi-magasins',
                  limits.multiStore ? 'Inclus' : 'Non inclus',
                  limits.multiStore,
                ),
                _Feat(
                  'Rapports IA WhatsApp',
                  limits.aiReports ? 'Inclus' : 'Non inclus',
                  limits.aiReports,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feat extends StatelessWidget {
  final String label, value;
  final bool included;
  const _Feat(this.label, this.value, this.included);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          included ? Icons.check_circle_rounded : Icons.cancel_outlined,
          size: 14,
          color: included ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: included ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: included ? AppColors.textSecondary : AppColors.textMuted,
          ),
        ),
      ],
    ),
  );
}

// ── COMPARE TABLE ─────────────────────────────────────────────

class _CompareTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        children: [
          _hdr(),
          _row('Produits', '50', '∞', '∞'),
          _row('Magasins', '1', '3', '∞'),
          _row('Sync cloud', '✗', '✓', '✓'),
          _row('Rapports', '✗', '✓', '✓'),
          _row('Multi-shop', '✗', '✗', '✓'),
          _row('IA WhatsApp', '✗', '✗', '✓'),
          _priceRow(),
        ],
      ),
    );
  }

  TableRow _hdr() => TableRow(
    decoration: const BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    children: [
      _c('Feature', hdr: true),
      _c('Free', hdr: true),
      _c('Pro', hdr: true, color: AppColors.primary),
      _c('Premium', hdr: true, color: const Color(0xFF8B5CF6)),
    ],
  );

  TableRow _row(String f, String fr, String pr, String pm) => TableRow(
    children: [
      _c(f, feat: true),
      _c(fr, muted: fr == '✗'),
      _c(pr, muted: pr == '✗'),
      _c(pm, muted: pm == '✗'),
    ],
  );

  TableRow _priceRow() => TableRow(
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.04),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
    ),
    children: [
      _c('Prix/mois', hdr: true),
      _c('Gratuit'),
      _c('3 000 FCFA', color: AppColors.primary, bold: true),
      _c('8 000 FCFA', color: const Color(0xFF8B5CF6), bold: true),
    ],
  );

  Widget _c(
    String t, {
    bool hdr = false,
    bool feat = false,
    bool muted = false,
    Color? color,
    bool bold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Text(
      t,
      textAlign: feat ? TextAlign.left : TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        fontWeight: hdr || bold ? FontWeight.w700 : FontWeight.w400,
        color: muted ? AppColors.textMuted : color ?? AppColors.textPrimary,
      ),
    ),
  );
}

// ── PAYMENT SHEET ─────────────────────────────────────────────

class _PaymentSheet extends StatelessWidget {
  final PlanLimits plan;
  const _PaymentSheet({required this.plan});

  Color get color =>
      plan.plan == GposPlan.pro ? AppColors.primary : const Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Passer au plan ${plan.planName}',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'SpaceGrotesk',
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              plan.priceLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _PayMethod(
              icon: '📱',
              title: 'Payer par Wave',
              phone: '+221 77 675 53 53',
              steps: [
                'Ouvrez l\'app Wave',
                'Tapez "Envoyer de l\'argent"',
                'Numéro : +221 77 675 53 53',
                'Montant : ${plan.priceFcfa} FCFA',
                'Message : GPOS-${plan.plan.name.toUpperCase()}',
              ],
            ),
            const SizedBox(height: 12),
            _PayMethod(
              icon: '🟠',
              title: 'Payer par Orange Money',
              phone: '+221 77 675 53 53',
              steps: [
                'Composez #144#',
                'Choisissez "Transfert d\'argent"',
                'Numéro : +221 77 675 53 53',
                'Montant : ${plan.priceFcfa} FCFA',
                'Message : GPOS-${plan.plan.name.toUpperCase()}',
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.info,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Après le paiement',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Envoyez la capture de votre paiement par WhatsApp. '
                    'Votre plan sera activé dans les 2 heures.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('J\'ai effectué le paiement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final String icon, title, phone;
  final List<String> steps;
  const _PayMethod({
    required this.icon,
    required this.title,
    required this.phone,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Numéro copié'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(right: 8, top: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SUPPORT ───────────────────────────────────────────────────

class _SupportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceCard(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: const Row(
      children: [
        Icon(
          Icons.support_agent_rounded,
          color: AppColors.primaryLight,
          size: 20,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Besoin d\'aide ?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'support@gpos.sn  •  WhatsApp : +221 77 XXX XX XX',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
