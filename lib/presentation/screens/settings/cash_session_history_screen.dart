import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/services/printer_service.dart';
import 'cash_session_history_bloc.dart';

class CashSessionHistoryScreen extends StatefulWidget {
  const CashSessionHistoryScreen({super.key});

  @override
  State<CashSessionHistoryScreen> createState() =>
      _CashSessionHistoryScreenState();
}

class _CashSessionHistoryScreenState extends State<CashSessionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CashHistoryBloc(getIt<PosDatabase>())..add(LoadCashHistory()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Historique des caisses'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            BlocBuilder<CashHistoryBloc, CashHistoryState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    color: state.dateRange != null ? AppColors.accent : null,
                  ),
                  onPressed: () => _selectDateRange(context),
                  tooltip: 'Filtrer par date',
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFF093FB)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                BlocBuilder<CashHistoryBloc, CashHistoryState>(
                  builder: (context, state) {
                    if (state.dateRange == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.white.withValues(alpha: 0.1),
                      child: Row(
                        // Ligne 53
                        children: [
                          const Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Du ${Fmt.date(state.dateRange!.start)} au ${Fmt.date(state.dateRange!.end)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => context
                                .read<CashHistoryBloc>()
                                .add(const DateRangeChanged(null)),
                            tooltip: 'Effacer le filtre',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<CashHistoryBloc, CashHistoryState>(
                    builder: (context, state) {
                      if (state.isLoading && state.sessions.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.sessions.isEmpty) {
                        return Center(
                          child: Text(
                            state.dateRange == null
                                ? 'Aucune session de caisse trouvée.'
                                : 'Aucune session pour cette période.',
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.sessions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _SessionTile(
                            sessionData: state.sessions[index],
                            onPrint: () => _printReport(state.sessions[index]),
                            onExportPdf: () =>
                                _exportPdf(state.sessions[index]),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final bloc = context.read<CashHistoryBloc>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: bloc.state.dateRange,
    );

    if (range != null) {
      bloc.add(DateRangeChanged(range));
    }
  }

  void _printReport(CashSessionWithUser sessionData) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final printer = getIt<PrinterService>();
      if (!printer.isConnected) {
        throw Exception('Aucune imprimante connectée.');
      }

      final db = getIt<PosDatabase>();

      // Ligne 137 (ou 179) - CORRIGÉ
      final payments = await db.salesDao.getPaymentsForSession(
        sessionData.session.id,
      );
      final settings = await db.getAllSettings();

      final reportText = PrinterService.buildCashSessionReport(
        session: sessionData.session,
        userName: sessionData.user.name,
        payments: payments,
        currency: settings['currency_symbol'] ?? 'F',
      );

      await printer.printReport(reportText);

      if (!mounted) return;
      navigator.pop(); // close loading
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Rapport envoyé à l\'imprimante.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop(); // close loading
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur d\'impression: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _exportPdf(CashSessionWithUser sessionData) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final db = getIt<PosDatabase>();
      final payments = await db.salesDao.getPaymentsForSession(
        sessionData.session.id,
      );
      final settings = await db.getAllSettings();
      final shopName = settings['shop_name'] ?? 'Mon Magasin';
      final currency = settings['currency_symbol'] ?? 'F';
      final shopLogoPath = settings['shop_logo_path'];

      pw.ImageProvider? logoImage;
      if (shopLogoPath != null && shopLogoPath.isNotEmpty) {
        final logoFile = File(shopLogoPath);
        if (await logoFile.exists()) {
          logoImage = pw.MemoryImage(await logoFile.readAsBytes());
        }
      }

      final doc = pw.Document();

      final cashSales = payments
          .where((p) => p.method == 'cash')
          .fold<double>(0.0, (sum, p) => sum + p.amount - p.changeGiven);

      final otherPayments = payments
          .where((p) => p.method != 'cash')
          .fold<Map<String, double>>({}, (map, p) {
            map[p.method] = (map[p.method] ?? 0) + p.amount - p.changeGiven;
            return map;
          });

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null)
                  pw.Center(
                    child: pw.SizedBox(
                      height: 80,
                      width: 80,
                      child: pw.Image(logoImage),
                    ),
                  ),
                pw.SizedBox(height: logoImage != null ? 10 : 0),
                pw.Center(
                  child: pw.Text(
                    shopName.toUpperCase(),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'RAPPORT DE CLÔTURE DE CAISSE',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date: ${Fmt.date(sessionData.session.startedAt)}'),
                    pw.Text('Utilisateur: ${sessionData.user.name}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Ouverture: ${Fmt.time(sessionData.session.startedAt)}',
                    ),
                    if (sessionData.session.endedAt != null)
                      pw.Text(
                        'Fermeture: ${Fmt.time(sessionData.session.endedAt!)}',
                      ),
                  ],
                ),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 10),
                pw.Text(
                  'DÉTAIL',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                _pdfRow(
                  'Fond de caisse',
                  sessionData.session.startingCash,
                  currency,
                ),
                _pdfRow('Ventes espèces', cashSales, currency),
                pw.Divider(),
                _pdfRow(
                  'TOTAL ESPÈCES ATTENDU',
                  sessionData.session.expectedCash ?? 0,
                  currency,
                  isBold: true,
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'COMPTAGE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                _pdfRow(
                  'Montant compté',
                  sessionData.session.endingCash ?? 0,
                  currency,
                ),
                _pdfRow(
                  'Écart',
                  sessionData.session.discrepancy ?? 0,
                  currency,
                  color: (sessionData.session.discrepancy ?? 0) != 0
                      ? PdfColors.red
                      : null,
                ),
                if (otherPayments.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'AUTRES PAIEMENTS',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  ...otherPayments.entries.map(
                    (e) => _pdfRow(Fmt.paymentMethod(e.key), e.value, currency),
                  ),
                ],
                if (sessionData.session.notes.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'NOTES',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(sessionData.session.notes),
                ],
              ],
            );
          },
        ),
      );

      if (!mounted) return;
      navigator.pop(); // close loading

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'cloture_caisse_${sessionData.session.id}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur export PDF: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  pw.Widget _pdfRow(
    String label,
    double value,
    String currency, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: color,
            ),
          ),
          pw.Text(
            Fmt.currency(value, symbol: currency),
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final CashSessionWithUser sessionData;
  final VoidCallback onPrint;
  final VoidCallback onExportPdf;
  const _SessionTile({
    required this.sessionData,
    required this.onPrint,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final session = sessionData.session;
    final user = sessionData.user;
    final discrepancy = session.discrepancy ?? 0.0;
    final isClosed = session.status == 'closed';

    Color statusColor;
    IconData statusIcon;

    if (!isClosed) {
      statusColor = AppColors.info;
      statusIcon = Icons.lock_open_rounded;
    } else if (discrepancy == 0) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline_rounded;
    } else {
      statusColor = AppColors.warning;
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context), // Ligne 197
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            // Ligne 206
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session du ${Fmt.date(session.startedAt)} par ${user.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1, // Ligne 213
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ouvert à ${Fmt.time(session.startedAt)}'
                  '${isClosed ? ' • Fermé à ${Fmt.time(session.endedAt!)}' : ' • EN COURS'}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isClosed)
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Fmt.currency(discrepancy),
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: discrepancy == 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                    const Text(
                      'Écart',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.textMuted,
                  ),
                  onPressed: onExportPdf,
                  tooltip: 'Exporter en PDF',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.print_outlined,
                    color: AppColors.textMuted,
                  ),
                  onPressed: onPrint,
                  tooltip: 'Imprimer le rapport',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
