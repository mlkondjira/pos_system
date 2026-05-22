import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/services/printer_service.dart';
import '../../blocs/override_report_bloc.dart';
import '../../widgets/shared_widgets.dart';

class OverrideReportScreen extends StatelessWidget {
  const OverrideReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OverrideReportBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Autorisations de Remises', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            BlocBuilder<OverrideReportBloc, OverrideReportState>(
              builder: (context, state) => IconButton(
                icon: const Icon(Icons.date_range_rounded),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    initialDateRange: state.dateRange,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                  );
                  if (range != null && context.mounted) {
                    context.read<OverrideReportBloc>().add(ChangeDateRange(range));
                  }
                },
              ),
            ),
            BlocBuilder<OverrideReportBloc, OverrideReportState>(
              builder: (context, state) => IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'Exporter en PDF',
                onPressed: state.logs.isEmpty ? null : () => _exportPdf(context, state),
              ),
            ),
          ],
        ),
        body: BlocBuilder<OverrideReportBloc, OverrideReportState>(
          builder: (context, state) {
            if (state.isLoading) return const Center(child: CircularProgressIndicator());
            if (state.logs.isEmpty) {
              return const EmptyState(
                icon: Icons.verified_user_outlined,
                title: 'Aucun override détecté',
                subtitle: 'Aucune remise importante n\'a été validée sur cette période.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final entry = state.logs[index];
                final details = jsonDecode(entry.log.details ?? '{}');

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_open_rounded, color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Text(Fmt.dateTime(entry.log.timestamp), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            StatusBadge(label: details['discount_value'] ?? '0%', color: AppColors.danger),
                          ],
                        ),
                        const Divider(height: 24),
                        _infoRow('Autorisé par', entry.actorName, isPrimary: true),
                        _infoRow('Caissier', details['cashier_name'] ?? 'Inconnu'),
                        _infoRow('Produit', details['product_name'] ?? 'Inconnu'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: TextStyle(
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
            color: isPrimary ? AppColors.primary : AppColors.textPrimary,
          )),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, OverrideReportState state) async {
    final printer = getIt<PrinterService>();
    final range = state.dateRange;
    
    // 1. Préparation de l'en-tête du rapport
    final introText = 'RAPPORT D\'AUTORISATION DE REMISES\n'
        'Période : ${Fmt.date(range.start)} au ${Fmt.date(range.end)}\n'
        'Total des opérations : ${state.logs.length}';

    // 2. Préparation des données du tableau
    final headers = ['Date', 'Autorisé par', 'Caissier', 'Produit', 'Remise'];
    final tableData = state.logs.map((entry) {
      final details = jsonDecode(entry.log.details ?? '{}');
      return <String>[
        Fmt.dateTime(entry.log.timestamp),
        entry.actorName,
        (details['cashier_name'] ?? 'Inconnu').toString(),
        (details['product_name'] ?? 'Inconnu').toString(),
        (details['discount_value'] ?? '0%').toString(),
      ];
    }).toList();

    // 3. Appel au service de partage
    await printer.sharePdfReport(
      fileName: 'Rapport_Overrides_${range.start.millisecondsSinceEpoch}',
      introText: introText,
      shareMessage: 'Voici le rapport des autorisations de remises du ${Fmt.date(range.start)} au ${Fmt.date(range.end)}.',
      subject: 'Rapport Overrides POS',
      tableHeaders: headers,
      tableData: tableData,
    );
  }
}