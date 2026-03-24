// lib/presentation/screens/inventaire/inventaire_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import 'inventory_session_screen.dart';
import 'inventory_list_bloc.dart';

class InventaireScreen extends StatefulWidget {
  const InventaireScreen({super.key});

  @override
  State<InventaireScreen> createState() => _InventaireScreenState();
}

class _InventaireScreenState extends State<InventaireScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          InventoryListBloc(getIt<PosDatabase>())..add(LoadInventoryList()),
      child: BlocListener<InventoryListBloc, InventoryListState>(
        listenWhen: (prev, curr) =>
            _searchCtrl.text.isEmpty && curr.searchQuery.isNotEmpty,
        listener: (context, state) {
          _searchCtrl.text = state.searchQuery;
        },
        child: BlocBuilder<InventoryListBloc, InventoryListState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Inventaire'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nouveau inventaire'),
                      onPressed: () => _newInventory(context),
                    ),
                  ),
                ],
              ),
              body: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, InventoryListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.sessions.isEmpty) {
      return _empty(context);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => context
                .read<InventoryListBloc>()
                .add(SearchQueryChanged(v)),
            decoration: const InputDecoration(
              hintText: 'Rechercher par référence (ex: INV-2024...)',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _statusChip(context, 'all', 'Tous',
                  state.statusFilter == 'all'),
              const SizedBox(width: 8),
              _statusChip(context, 'in_progress', 'En cours',
                  state.statusFilter == 'in_progress'),
              const SizedBox(width: 8),
              _statusChip(context, 'completed', 'Terminé',
                  state.statusFilter == 'completed'),
              if (state.searchQuery.isNotEmpty ||
                  state.statusFilter != 'all') ...[
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    _searchCtrl.clear();
                    context
                        .read<InventoryListBloc>()
                        .add(ResetFilters());
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Réinitialiser',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.filteredSessions.isEmpty
              ? const Center(
                  child: Text(
                  'Aucun résultat trouvé',
                  style: TextStyle(color: AppColors.textMuted),
                ))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: state.filteredSessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _SessionCard(
                    session: state.filteredSessions[i],
                    onTap: () => _openSession(
                        context, state.filteredSessions[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _statusChip(BuildContext context, String value, String label,
      bool isSelected) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          context
              .read<InventoryListBloc>()
              .add(FilterStatusChanged(value));
        }
      },
      showCheckmark: false,
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fact_check_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Aucun inventaire',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Démarrez un inventaire pour compter\net ajuster vos stocks',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Démarrer un inventaire'),
              onPressed: () => _newInventory(context),
            ),
          ],
        ),
      );

  Future<void> _newInventory(BuildContext context) async {
    final notesCtrl = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Nouvel inventaire',
          style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'Un nouvel inventaire va charger tous vos produits actifs.\n'
              'Vous pourrez saisir les quantités comptées.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Ex: Inventaire mensuel novembre...',
              ),
              maxLines: 2,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Démarrer')),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.read<InventoryListBloc>().add(CreateInventory(
            notes: notesCtrl.text,
            userId: context.read<AuthBloc>().state.user!.id,
          ));
    }
  }

  void _openSession(BuildContext context, InventorySession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventorySessionScreen(session: session),
      ),
    );
  }
}

// ── SESSION CARD ──────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final InventorySession session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = session.status == 'completed';
    final isInProgress = session.status == 'in_progress';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInProgress ? AppColors.accent : AppColors.border,
            width: isInProgress ? 2 : 1,
          ),
        ),
        child: Row(children: [
          // Icône statut
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.successSoft
                  : isInProgress
                      ? AppColors.accentSoft
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : isInProgress
                      ? Icons.pending_rounded
                      : Icons.cancel_rounded,
              color: isCompleted
                  ? AppColors.success
                  : isInProgress
                      ? AppColors.accentDark
                      : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Référence + date + notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    session.ref,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(session.status),
                ]),
                const SizedBox(height: 4),
                Text(
                  Fmt.dateTime(session.startedAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                if (session.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.notes,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Total produits + écarts (discrepancies est dans la table)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${session.totalProducts}',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const Text(
              'produits',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            if (isCompleted) ...[
              const SizedBox(height: 4),
              Text(
                '${session.discrepancies} écarts',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: session.discrepancies > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ],
          ]),

          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

// ── STATUS BADGE ──────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'completed':
        bg = AppColors.successSoft;
        fg = AppColors.success;
        label = 'Terminé';
        break;
      case 'in_progress':
        bg = AppColors.accentSoft;
        fg = AppColors.accentDark;
        label = 'En cours';
        break;
      case 'cancelled':
        bg = AppColors.dangerSoft;
        fg = AppColors.danger;
        label = 'Annulé';
        break;
      default:
        bg = AppColors.surface;
        fg = AppColors.textMuted;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}