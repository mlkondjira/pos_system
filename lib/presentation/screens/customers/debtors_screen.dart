import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/database/sales_dao.dart';
import 'customer_debt_detail_screen.dart';
import '../../widgets/shared_widgets.dart';

class DebtorsScreen extends StatefulWidget {
  const DebtorsScreen({super.key});

  @override
  State<DebtorsScreen> createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends State<DebtorsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = getIt<PosDatabase>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(),
      body: StreamBuilder<List<DebtorSummary>>(
        stream: db.salesDao.watchDebtorsSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final debtors = snapshot.data ?? [];
          final filtered = _query.isEmpty
              ? debtors
              : debtors
                    .where(
                      (d) => d.customer.name.toLowerCase().contains(
                        _query.toLowerCase(),
                      ),
                    )
                    .toList();

          if (filtered.isEmpty && _query.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_user_outlined,
              title: 'Aucune dette en cours',
              subtitle: 'Tous vos clients sont à jour de leurs paiements.',
            );
          }

          final totalBacklog = filtered.fold(
            0.0,
            (sum, d) => sum + d.totalDebt,
          );

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.surface,
                child: PosSearchBar(
                  controller: _searchCtrl,
                  hint: 'Rechercher un client...',
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
              _buildTotalHeader(totalBacklog),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Aucun résultat trouvé'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _DebtorCard(debtor: filtered[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalHeader(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Ligne 108
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'CAPITAL À RÉCUPÉRER',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Fmt.currency(total),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtorCard extends StatelessWidget {
  final DebtorSummary debtor;
  const _DebtorCard({required this.debtor});

  Future<void> _contact(String method) async {
    if (debtor.customer.phone == null) return;
    final phone = debtor.customer.phone!.replaceAll(RegExp(r'\D'), '');
    final uri = method == 'whatsapp'
        ? Uri.parse(
            'https://wa.me/$phone?text=Bonjour ${debtor.customer.name}, nous vous contactons concernant votre solde de ${Fmt.currency(debtor.totalDebt)} dans notre boutique.',
          )
        : Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: const CircleAvatar(
          radius: 26,
          backgroundColor: Colors.transparent,
          child: Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
        ),
        title: Text(
          debtor.customer.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  debtor.customer.phone ?? 'Aucun numéro',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (debtor.customer.phone != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.call_rounded,
                    label: 'Appeler',
                    color: AppColors.primary,
                    onTap: () => _contact('tel'),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Relancer',
                    color: AppColors.success,
                    onTap: () => _contact('whatsapp'),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.currency(debtor.totalDebt),
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'SOLDE DÛ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDebtDetailScreen(debtor: debtor),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
