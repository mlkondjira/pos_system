// lib/presentation/screens/inventaire/inventory_session_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../blocs/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/services/printer_service.dart';
import '../../widgets/shared_widgets.dart';
import '../settings/inventory_session_bloc.dart';

class InventorySessionScreen extends StatefulWidget {
  final InventorySession session;
  const InventorySessionScreen({super.key, required this.session});
  @override
  State<InventorySessionScreen> createState() => _InventorySessionScreenState();
}

class _InventorySessionScreenState extends State<InventorySessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();

  bool get isReadOnly =>
      widget.session.status == 'completed' ||
      widget.session.status == 'cancelled';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _onBarcodeDetected(BuildContext context, String barcode) async {
    context.read<InventorySessionBloc>().add(ToggleScanner());
    final db = getIt<PosDatabase>();
    final line = await db.getInventoryLineByBarcode(widget.session.id, barcode);
    if (!context.mounted) return;
    if (line != null) {
      _showCountDialog(context, line);
    } else {
      _showSnack(
        'Produit non trouvé dans cet inventaire: $barcode',
        AppColors.danger,
      );
    }
  }

  Future<void> _showCountDialog(
    BuildContext context,
    InventoryLine line,
  ) async {
    if (isReadOnly) return;

    // On capture le BLOC ici avec le bon contexte avant d'ouvrir le dialogue
    final bloc = context.read<InventorySessionBloc>();

    final ctrl = TextEditingController(text: line.countedQty?.toString() ?? '');
    final defectiveCtrl = TextEditingController(
      text: line.defectiveQty.toString(),
    );
    final obsoleteCtrl = TextEditingController(
      text: line.obsoleteQty.toString(),
    );
    final expiredCtrl = TextEditingController(text: line.expiredQty.toString());
    final notesCtrl = TextEditingController(text: line.notes);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          line.productName,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stock théorique
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'STOCK THÉORIQUE', // Ligne 120
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${line.expectedQty}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20, // Ligne 120
                        color: AppColors.primary, // Ligne 121
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Quantité comptée
              TextFormField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number, // Ligne 150
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ], // Ligne 150
                style: TextStyle(
                  fontWeight: FontWeight.w900, // Ligne 150
                  fontSize: 32, // Ligne 150
                  color: Theme.of(context).colorScheme.onSurface, // Ligne 150
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'QUANTITÉ COMPTÉE',
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              const SizedBox(height: 12),
              const SectionLabel('Invendables inclus dans le total'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: defectiveCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cassé',
                        prefixIcon: Icon(Icons.broken_image_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: obsoleteCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Obsolète',
                        prefixIcon: Icon(Icons.history_toggle_off, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: expiredCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Périmé',
                  prefixIcon: Icon(Icons.event_busy_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Ex: Produit abîmé, à commander...',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(ctrl.text);
              if (qty == null) return;

              final defective = int.tryParse(defectiveCtrl.text) ?? 0;
              final obsolete = int.tryParse(obsoleteCtrl.text) ?? 0;
              final expired = int.tryParse(expiredCtrl.text) ?? 0;

              // Utilisation de l'instance du bloc capturée
              bloc.add(
                UpdateCountedQuantity(
                  lineId: line.id,
                  quantity: qty,
                  notes: notesCtrl.text,
                  defectiveQty: defective,
                  obsoleteQty: obsolete,
                  expiredQty: expired,
                ),
              );

              if (context.mounted) Navigator.pop(context);

              final diff = qty - line.expectedQty;
              _showSnack(
                diff == 0
                    ? '✓ ${line.productName}: stock OK'
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

  Future<void> _validateSession(BuildContext context) async {
    final bloc = context.read<InventorySessionBloc>();
    // Capture context-sensitive objects before async gaps.
    final authBloc = context.read<AuthBloc>();
    final lines = bloc.state.lines;

    final uncounted = lines.where((l) => !l.isValidated).length;

    if (uncounted > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            'Valider l\'inventaire ?',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$uncounted produit(s) non compté(s).\nIls ne seront pas ajustés.',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Les stocks des produits comptés seront mis à jour dans la base de données.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Valider et appliquer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (ok != true) return;
    } else {
      // Confirmation standard quand tout est compté
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            'Confirmer la validation',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Tous les produits ont été comptés.\n'
            'Les stocks seront mis à jour et cette session sera clôturée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Valider',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (ok != true) return;
    }

    final user = authBloc.state.user;
    if (user != null) {
      bloc.add(ValidateSession(widget.session.id, user.id));
    }
  }

  Future<void> _exportInventoryReport(
    InventorySessionState inventoryState,
  ) async {
    // Capture context-sensitive objects before async gaps.
    final authBloc = context.read<AuthBloc>();

    try {
      // On recharge la session depuis la DB pour avoir les données finales (completedAt, etc.)
      final db = getIt<PosDatabase>();
      final session = await (db.select(
        db.inventorySessions,
      )..where((s) => s.id.equals(widget.session.id))).getSingle();

      final lines = inventoryState.lines;
      final user = authBloc.state.user;

      if (user == null) return;

      final reportText = PrinterService.buildInventoryReport(
        session: session,
        lines: lines,
        userName: user.name,
      );

      // Générer les bytes du PDF en format A4
      final pdfBytes = await getIt<PrinterService>().generateReportPdfBytes(
        reportText,
      );

      // Sauvegarder dans un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, 'Inventaire-${session.ref}.pdf');
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Partager le fichier
      await SharePlus.instance.share(
        ShareParams(
          text: 'Rapport d\'inventaire - ${session.ref}',
          files: [
            XFile(
              filePath,
              name: 'Inventaire-${session.ref}.pdf',
              mimeType: 'application/pdf',
            ),
          ],
          subject: 'Rapport d\'inventaire - ${session.ref}',
        ),
      );
    } catch (e) {
      debugPrint('Erreur export inventaire PDF: $e');
      if (mounted) {
        _showSnack('Erreur lors de la génération du PDF: $e', AppColors.danger);
      }
    }
  }

  Future<void> _exportLossReport(InventorySessionState inventoryState) async {
    final authBloc = context.read<AuthBloc>();

    try {
      final db = getIt<PosDatabase>();
      final session = await (db.select(
        db.inventorySessions,
      )..where((s) => s.id.equals(widget.session.id))).getSingle();

      final lines = inventoryState.lines;
      final user = authBloc.state.user;

      if (user == null) return;

      // Introduction textuelle du rapport
      final introText =
          'RAPPORT DES PERTES D\'INVENTAIRE\n'
          'Référence: ${session.ref}\n'
          'Date: ${Fmt.dateTime(session.startedAt)}\n'
          'Utilisateur: ${user.name}';

      // Préparation des données structurées pour le tableau PDF
      final headers = ['Article', 'Cassé', 'Obsolète', 'Périmé', 'Total'];
      final lossLines = lines
          .where((l) => (l.defectiveQty + l.obsoleteQty + l.expiredQty) > 0)
          .map(
            (l) => [
              l.productName,
              l.defectiveQty.toString(),
              l.obsoleteQty.toString(),
              l.expiredQty.toString(),
              (l.defectiveQty + l.obsoleteQty + l.expiredQty).toString(),
            ],
          )
          .toList();

      final pdfBytes = await getIt<PrinterService>().generateReportPdfBytes(
        introText,
        tableHeaders: headers,
        tableData: lossLines,
      );

      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(
        tempDir.path,
        'Rapport-Pertes-${session.ref}.pdf',
      );
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              filePath,
              name: 'Rapport-Pertes-${session.ref}.pdf',
              mimeType: 'application/pdf',
            ),
          ],
          text: 'Rapport des pertes d\'inventaire - ${session.ref}',
          subject: 'Rapport des pertes d\'inventaire - ${session.ref}',
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur lors de la génération du PDF: $e', AppColors.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          InventorySessionBloc(getIt<PosDatabase>())
            ..add(LoadInventoryLines(widget.session.id)),
      child: BlocListener<InventorySessionBloc, InventorySessionState>(
        listenWhen: (prev, curr) =>
            prev.isSuccess != curr.isSuccess ||
            prev.errorMessage != curr.errorMessage,
        listener: (context, state) async {
          final navigator = Navigator.of(context);
          if (state.isSuccess) {
            _showSnack(
              'Inventaire validé ! Stocks mis à jour.',
              AppColors.success,
            );
            await _exportInventoryReport(state);
            if (mounted) navigator.pop();
          } else if (state.errorMessage != null) {
            _showSnack(
              'Erreur lors de la validation : ${state.errorMessage}',
              AppColors.danger,
            );
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

  Widget _buildScaffold(
    BuildContext context,
    InventorySessionState state,
  ) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.session.ref,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            Fmt.dateTime(widget.session.startedAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // On utilise un container avec une largeur maximum pour laisser de la place au titre
        // et on rend le contenu horizontalement défilable.
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!isReadOnly) ...[
                  IconButton(
                    icon: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: state.showScanner
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    onPressed: () => context.read<InventorySessionBloc>().add(
                      ToggleScanner(),
                    ),
                  ),
                ],
                if (!isReadOnly)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 12,
                      top: 8,
                      bottom: 8,
                    ),
                    child: ElevatedButton(
                      onPressed: state.isValidating
                          ? null
                          : () => _validateSession(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: state.isValidating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Valider',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabs,
        labelColor: AppColors.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Produits'),
          Tab(text: 'Résumé'),
          Tab(text: 'Historique'),
        ],
      ),
    ),
    body: Column(
      children: [
        // Scanner
        if (state.showScanner)
          Container(
            height: 180,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull?.rawValue;
                if (barcode != null) _onBarcodeDetected(context, barcode);
              },
            ),
          ),

        // Filtres et recherche (tab 1)
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildProductsTab(context, state),
              _buildSummaryTab(state),
              _buildHistoryTab(state),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Onglet Produits ────────────────────────────────────────

  Widget _buildProductsTab(BuildContext context, InventorySessionState state) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onChanged: (v) => context.read<InventorySessionBloc>().add(
                      UpdateSearchQuery(v),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                context.read<InventorySessionBloc>().add(
                                  const UpdateSearchQuery(''),
                                );
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filtre
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.filter_list_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (v) =>
                      context.read<InventorySessionBloc>().add(UpdateFilter(v)),
                  itemBuilder: (_) => [
                    _menuItem('all', 'Tous', state.filter == 'all'),
                    _menuItem(
                      'uncounted',
                      'Non comptés',
                      state.filter == 'uncounted',
                    ),
                    _menuItem('counted', 'Comptés', state.filter == 'counted'),
                    _menuItem(
                      'discrepancy',
                      'Avec écarts',
                      state.filter == 'discrepancy',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (ctx) {
                var lines = state.lines;

                // Filtre texte
                if (state.searchQuery.isNotEmpty) {
                  final q = state.searchQuery.toLowerCase();
                  lines = lines
                      .where(
                        (l) =>
                            l.productName.toLowerCase().contains(q) ||
                            (l.barcode?.toLowerCase().contains(q) ?? false),
                      )
                      .toList();
                }
                // Filtre statut
                switch (state.filter) {
                  case 'uncounted':
                    lines = lines.where((l) => !l.isValidated).toList();
                    break;
                  case 'counted':
                    lines = lines.where((l) => l.isValidated).toList();
                    break;
                  case 'discrepancy':
                    lines = lines
                        .where((l) => l.isValidated && (l.difference ?? 0) != 0)
                        .toList();
                    break;
                }

                if (lines.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun produit',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _InventoryLineTile(
                    line: lines[i],
                    isReadOnly: isReadOnly,
                    onTap: () => _showCountDialog(context, lines[i]),
                  ),
                );
              },
            ),
          ),
        ],
      );

  // ── Onglet Résumé ──────────────────────────────────────────

  Widget _buildSummaryTab(InventorySessionState state) {
    final lines = state.lines;
    final counted = lines.where((l) => l.isValidated).length;
    final uncounted = lines.length - counted;
    final discrepancies = lines
        .where((l) => l.isValidated && (l.difference ?? 0) != 0)
        .toList();
    final losses = lines
        .where(
          (l) => l.defectiveQty > 0 || l.obsoleteQty > 0 || l.expiredQty > 0,
        )
        .toList();
    final positives = discrepancies
        .where((l) => (l.difference ?? 0) > 0)
        .length;
    final negatives = discrepancies
        .where((l) => (l.difference ?? 0) < 0)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progression
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AVANCEMENT DU COMPTAGE',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$counted / ${lines.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: lines.isEmpty ? 0 : counted / lines.length,
                    minHeight: 10,
                    backgroundColor: AppColors.bg,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _dot(AppColors.success, '$counted comptés'),
                    const Spacer(),
                    _dot(AppColors.textMuted, '$uncounted restants'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Écarts total',
                  '${discrepancies.length}',
                  color: discrepancies.isEmpty
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Surplus (+)',
                  '$positives',
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Manquants (−)',
                  '$negatives',
                  color: AppColors.danger,
                ),
              ),
            ],
          ),

          if (discrepancies.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'PRODUITS AVEC ÉCARTS',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 10),
            ...discrepancies.map(
              (l) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${l.expectedQty} → ${l.countedQty}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (l.difference ?? 0) > 0
                            ? AppColors.infoSoft
                            : AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (l.difference ?? 0) > 0
                            ? '+${l.difference}'
                            : '${l.difference}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: (l.difference ?? 0) > 0
                              ? AppColors.info
                              : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (widget.session.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.session.notes,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isReadOnly &&
              (discrepancies.isNotEmpty || losses.isNotEmpty)) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _exportLossReport(state),
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.danger,
                ),
                label: const Text('Télécharger Rapport de Pertes (PDF)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Onglet Historique ──────────────────────────────────────

  Widget _buildHistoryTab(InventorySessionState state) {
    final validated = state.lines.where((l) => l.isValidated).toList()
      ..sort((a, b) => (b.id).compareTo(a.id));
    if (validated.isEmpty) {
      return const Center(
        child: Text(
          'Aucun produit compté pour l\'instant',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: validated.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final l = validated[i];
        final diff = l.difference ?? 0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                diff == 0
                    ? Icons.check_circle_rounded
                    : diff > 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: diff == 0
                    ? AppColors.success
                    : diff > 0
                    ? AppColors.info
                    : AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                'Théo: ${l.expectedQty}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Compté: ${l.countedQty}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: diff == 0
                      ? AppColors.success
                      : diff > 0
                      ? AppColors.info
                      : AppColors.danger,
                ),
              ),
              if (diff != 0) ...[
                const SizedBox(width: 8),
                Text(
                  '(${diff > 0 ? "+" : ""}$diff)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: diff > 0 ? AppColors.info : AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _dot(Color color, String label) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _statCard(String label, String value, {required Color color}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 26,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  PopupMenuItem<String> _menuItem(String value, String label, bool selected) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            if (!selected) const SizedBox(width: 16),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      );
}

// ── Tuile de ligne d'inventaire ────────────────────────────────

class _InventoryLineTile extends StatelessWidget {
  final InventoryLine line;
  final bool isReadOnly;
  final VoidCallback onTap;
  const _InventoryLineTile({
    required this.line,
    required this.isReadOnly,
    required this.onTap,
  });

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
          color: AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !counted
                ? AppColors.border
                : diff != 0
                ? (diff > 0 ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA))
                : AppColors.success.withValues(alpha: 0.3),
            width: counted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // Indicateur statut
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: !counted
                    ? AppColors.surface
                    : diff != 0
                    ? (diff > 0 ? AppColors.infoSoft : AppColors.dangerSoft)
                    : AppColors.successSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                !counted
                    ? Icons.radio_button_unchecked_rounded
                    : diff != 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_rounded,
                size: 16,
                color: !counted
                    ? AppColors.textMuted
                    : diff != 0
                    ? (diff > 0 ? AppColors.info : AppColors.danger)
                    : AppColors.success,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (line.barcode != null)
                    Text(
                      line.barcode!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  if (line.notes.isNotEmpty)
                    Text(
                      line.notes,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (line.defectiveQty > 0 ||
                      line.obsoleteQty > 0 ||
                      line.expiredQty > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Pertes: ${line.defectiveQty + line.obsoleteQty + line.expiredQty} unité(s)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Quantités
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Text(
                      'Théo: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${line.expectedQty}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (counted) ...[
                  Row(
                    children: [
                      const Text(
                        'Compté: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${line.countedQty}',
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (diff != 0)
                    Text(
                      '${diff > 0 ? "+" : ""}$diff',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: diff > 0 ? AppColors.info : AppColors.danger,
                      ),
                    )
                  else
                    const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ] else
                  const Text(
                    'À compter',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),

            if (!isReadOnly) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.edit_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
