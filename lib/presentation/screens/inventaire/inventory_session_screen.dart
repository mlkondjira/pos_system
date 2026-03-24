// lib/presentation/screens/inventaire/inventory_session_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../blocs/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import '../settings/inventory_session_bloc.dart';

class InventorySessionScreen extends StatefulWidget {
  final InventorySession session;
  const InventorySessionScreen({super.key, required this.session});
  @override State<InventorySessionScreen> createState() => _InventorySessionScreenState();
}

class _InventorySessionScreenState extends State<InventorySessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();

  bool get isReadOnly => widget.session.status == 'completed' || widget.session.status == 'cancelled';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); _searchCtrl.dispose(); super.dispose(); }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color, duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _onBarcodeDetected(BuildContext context, String barcode) async {
    context.read<InventorySessionBloc>().add(ToggleScanner());
    final db = getIt<PosDatabase>();
    final line = await db.getInventoryLineByBarcode(widget.session.id, barcode);
    if (!context.mounted) return;
    if (line != null) {
      _showCountDialog(line);
    } else {
      _showSnack('Produit non trouvé dans cet inventaire: $barcode', AppColors.danger);
    }
  }

  Future<void> _showCountDialog(InventoryLine line) async {
    if (isReadOnly) return;
    final ctrl = TextEditingController(
      text: line.countedQty?.toString() ?? '',
    );
    final notesCtrl = TextEditingController(text: line.notes);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(line.productName, style: const TextStyle(
          fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700,
        )),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Stock théorique
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Stock théorique', style: TextStyle(
                color: AppColors.info, fontWeight: FontWeight.w500, fontSize: 13,
              )),
              Text('${line.expectedQty}', style: const TextStyle(
                fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700,
                fontSize: 18, color: AppColors.info,
              )),
            ]),
          ),
          const SizedBox(height: 16),
          // Quantité comptée
          TextFormField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 24,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Quantité comptée',
              filled: true, fillColor: AppColors.surface,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              hintText: 'Ex: Produit abîmé, à commander...',
            ),
            maxLines: 2,
          ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(ctrl.text);
              if (qty == null) return;
              context.read<InventorySessionBloc>().add(
                UpdateCountedQuantity(line.id, qty, notesCtrl.text),
              );
              
              if (context.mounted) Navigator.pop(context);
              
              final diff = qty - line.expectedQty;
              _showSnack(
                diff == 0 ? '✓ ${line.productName}: stock OK'
                  : '${line.productName}: ${diff > 0 ? "+$diff" : "$diff"} écart',
                diff == 0 ? AppColors.success : AppColors.warning,
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateSession() async {
    final bloc = context.read<InventorySessionBloc>();
    final lines = bloc.state.lines;
    
    final uncounted = lines.where((l) => !l.isValidated).length;

    if (uncounted > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Valider l\'inventaire ?', style: TextStyle(
            fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700,
          )),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSoft, borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '$uncounted produit(s) non compté(s).\nIls ne seront pas ajustés.',
                  style: const TextStyle(color: AppColors.warning, fontSize: 13),
                )),
              ]),
            ),
            const SizedBox(height: 12),
            const Text('Les stocks des produits comptés seront mis à jour dans la base de données.'),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Valider et appliquer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (ok != true) return;
    }

    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      bloc.add(ValidateSession(widget.session.id, user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventorySessionBloc(getIt<PosDatabase>())
        ..add(LoadInventoryLines(widget.session.id)),
      child: BlocListener<InventorySessionBloc, InventorySessionState>(
        listenWhen: (prev, curr) => prev.isSuccess != curr.isSuccess || prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          if (state.isSuccess) {
            _showSnack('Inventaire validé ! Stocks mis à jour.', AppColors.success);
            Navigator.pop(context);
          } else if (state.errorMessage != null) {
            _showSnack('Erreur lors de la validation : ${state.errorMessage}', AppColors.danger);
          }
        },
        child: BlocBuilder<InventorySessionBloc, InventorySessionState>(
          builder: (context, state) {
            return _buildScaffold(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, InventorySessionState state) => Scaffold(
    appBar: AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.session.ref, style: const TextStyle(
          fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 16,
        )),
        Text(Fmt.dateTime(widget.session.startedAt),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
      actions: [
        if (!isReadOnly) ...[
          IconButton(
            icon: Icon(Icons.qr_code_scanner_rounded,
                color: state.showScanner ? AppColors.accent : AppColors.textSecondary),
            onPressed: () => context.read<InventorySessionBloc>().add(ToggleScanner()),
            tooltip: 'Scanner un code-barres',
          ),
          const SizedBox(width: 8),
        ],
        if (!isReadOnly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: state.isValidating ? null : _validateSession,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: state.isValidating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Valider', style: TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700)),
            ),
          ),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tabs,
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.accent,
        tabs: const [
          Tab(text: 'Produits'),
          Tab(text: 'Résumé'),
          Tab(text: 'Historique'),
        ],
      ),
    ),
    body: Column(children: [
      // Scanner
      if (state.showScanner) Container(
        height: 180,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: MobileScanner(onDetect: (capture) {
          final barcode = capture.barcodes.firstOrNull?.rawValue;
          if (barcode != null) _onBarcodeDetected(context, barcode);
        }),
      ),

      // Filtres et recherche (tab 1)
      Expanded(child: TabBarView(controller: _tabs, children: [
        _buildProductsTab(context, state),
        _buildSummaryTab(state),
        _buildHistoryTab(state),
      ])),
    ]),
  );

  // ── Onglet Produits ────────────────────────────────────────

  Widget _buildProductsTab(BuildContext context, InventorySessionState state) => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => context.read<InventorySessionBloc>().add(UpdateSearchQuery(v)),
          decoration: InputDecoration(
            hintText: 'Rechercher un produit...',
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            isDense: true,
            suffixIcon: state.searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () {
                    _searchCtrl.clear(); 
                    context.read<InventorySessionBloc>().add(UpdateSearchQuery(''));
                  })
                : null,
          ),
        )),
        const SizedBox(width: 10),
        // Filtre
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list_rounded, color: AppColors.textSecondary),
          onSelected: (v) => context.read<InventorySessionBloc>().add(UpdateFilter(v)),
          itemBuilder: (_) => [
            _menuItem('all', 'Tous', state.filter == 'all'),
            _menuItem('uncounted', 'Non comptés', state.filter == 'uncounted'),
            _menuItem('counted', 'Comptés', state.filter == 'counted'),
            _menuItem('discrepancy', 'Avec écarts', state.filter == 'discrepancy'),
          ],
        ),
      ]),
    ),
    Expanded(child: Builder(
      builder: (ctx) {
        var lines = state.lines;

        // Filtre texte
        if (state.searchQuery.isNotEmpty) {
          final q = state.searchQuery.toLowerCase();
          lines = lines.where((l) =>
              l.productName.toLowerCase().contains(q) ||
              (l.barcode?.toLowerCase().contains(q) ?? false)).toList();
        }
        // Filtre statut
        switch (state.filter) {
          case 'uncounted': lines = lines.where((l) => !l.isValidated).toList(); break;
          case 'counted': lines = lines.where((l) => l.isValidated).toList(); break;
          case 'discrepancy': lines = lines.where((l) => l.isValidated && (l.difference ?? 0) != 0).toList(); break;
        }

        if (lines.isEmpty) {
          return const Center(
          child: Text('Aucun produit', style: TextStyle(color: AppColors.textMuted)),
        );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: lines.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) => _InventoryLineTile(
            line: lines[i],
            isReadOnly: isReadOnly,
            onTap: () => _showCountDialog(lines[i]),
          ),
        );
      },
    )),
  ]);

  // ── Onglet Résumé ──────────────────────────────────────────

  Widget _buildSummaryTab(InventorySessionState state) {
      final lines = state.lines;
      final counted = lines.where((l) => l.isValidated).length;
      final uncounted = lines.length - counted;
      final discrepancies = lines.where((l) => l.isValidated && (l.difference ?? 0) != 0).toList();
      final positives = discrepancies.where((l) => (l.difference ?? 0) > 0).length;
      final negatives = discrepancies.where((l) => (l.difference ?? 0) < 0).length;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Progression
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Progression', style: TextStyle(
                  fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 16,
                )),
                Text('$counted / ${lines.length}', style: const TextStyle(
                  fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700,
                  fontSize: 16, color: AppColors.accent,
                )),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: lines.isEmpty ? 0 : counted / lines.length,
                  minHeight: 10,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _dot(AppColors.success, '$counted comptés'),
                const Spacer(),
                _dot(AppColors.textMuted, '$uncounted restants'),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(children: [
            Expanded(child: _statCard('Écarts total', '${discrepancies.length}',
                color: discrepancies.isEmpty ? AppColors.success : AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Surplus (+)', '$positives', color: AppColors.info)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Manquants (−)', '$negatives', color: AppColors.danger)),
          ]),

          if (discrepancies.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Produits avec écarts', style: TextStyle(
              fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 15,
            )),
            const SizedBox(height: 10),
            ...discrepancies.map((l) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Expanded(child: Text(l.productName, style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13,
                ))),
                Text('${l.expectedQty} → ${l.countedQty}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (l.difference ?? 0) > 0 ? AppColors.infoSoft : AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(l.difference ?? 0) > 0 ? "+" : ""}${l.difference}',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 13,
                      color: (l.difference ?? 0) > 0 ? AppColors.info : AppColors.danger,
                    ),
                  ),
                ),
              ]),
            )),
          ],

          if (widget.session.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.notes_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.session.notes,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ]),
            ),
          ],
        ]),
      );
  }

  // ── Onglet Historique ──────────────────────────────────────

  Widget _buildHistoryTab(InventorySessionState state) {
      final validated = state.lines.where((l) => l.isValidated).toList()
        ..sort((a, b) => (b.id).compareTo(a.id));
      if (validated.isEmpty) {
        return const Center(
        child: Text('Aucun produit compté pour l\'instant',
            style: TextStyle(color: AppColors.textMuted)),
      );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: validated.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, i) {
          final l = validated[i];
          final diff = l.difference ?? 0;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Icon(diff == 0 ? Icons.check_circle_rounded
                  : diff > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 16,
                color: diff == 0 ? AppColors.success : diff > 0 ? AppColors.info : AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
              Text('Théo: ${l.expectedQty}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              Text('Compté: ${l.countedQty}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: diff == 0 ? AppColors.success : diff > 0 ? AppColors.info : AppColors.danger)),
              if (diff != 0) ...[
                const SizedBox(width: 8),
                Text('(${diff > 0 ? "+" : ""}$diff)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: diff > 0 ? AppColors.info : AppColors.danger)),
              ],
            ]),
          );
        },
      );
  }

  Widget _dot(Color color, String label) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);

  Widget _statCard(String label, String value, {required Color color}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(
        fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 24, color: color,
      )),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          textAlign: TextAlign.center),
    ]),
  );

  PopupMenuItem<String> _menuItem(String value, String label, bool selected) =>
      PopupMenuItem(value: value, child: Row(children: [
        if (selected) const Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
        if (!selected) const SizedBox(width: 16),
        const SizedBox(width: 8),
        Text(label),
      ]));
}

// ── Tuile de ligne d'inventaire ────────────────────────────────

class _InventoryLineTile extends StatelessWidget {
  final InventoryLine line;
  final bool isReadOnly;
  final VoidCallback onTap;
  const _InventoryLineTile({required this.line, required this.isReadOnly, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final diff = line.difference ?? 0;
    final counted = line.isValidated;

    return InkWell(
      onTap: isReadOnly ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !counted ? AppColors.border
                : diff != 0 ? (diff > 0 ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA))
                : const Color(0xFFBBF7D0),
            width: counted ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Indicateur statut
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: !counted ? AppColors.surface
                  : diff != 0 ? (diff > 0 ? AppColors.infoSoft : AppColors.dangerSoft)
                  : AppColors.successSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              !counted ? Icons.radio_button_unchecked_rounded
                  : diff != 0 ? Icons.warning_amber_rounded : Icons.check_rounded,
              size: 16,
              color: !counted ? AppColors.textMuted
                  : diff != 0 ? (diff > 0 ? AppColors.info : AppColors.danger)
                  : AppColors.success,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(line.productName, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (line.barcode != null)
              Text(line.barcode!, style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted,
              )),
            if (line.notes.isNotEmpty)
              Text(line.notes, style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),

          // Quantités
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              const Text('Théo: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text('${line.expectedQty}', style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
              )),
            ]),
            if (counted) ...[
              Row(children: [
                const Text('Compté: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text('${line.countedQty}', style: const TextStyle(
                  fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 13,
                )),
              ]),
              if (diff != 0) Text(
                '${diff > 0 ? "+" : ""}$diff',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 12,
                  color: diff > 0 ? AppColors.info : AppColors.danger,
                ),
              ) else const Text('OK', style: TextStyle(
                fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600,
              )),
            ] else
              const Text('À compter', style: TextStyle(
                fontSize: 11, color: AppColors.textMuted,
              )),
          ]),

          if (!isReadOnly) ...[
            const SizedBox(width: 8),
            const Icon(Icons.edit_rounded, size: 14, color: AppColors.textMuted),
          ],
        ]),
      ),
    );
  }
}
