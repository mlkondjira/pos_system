import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/services/printer_service.dart';
import '../../../core/di/injection.dart';
import '../../widgets/app_background.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  DateTimeRange? _selectedRange;

  Future<void> _exportToPdf(
    BuildContext context,
    List<AuditLogWithActor> logs,
  ) async {
    if (logs.isEmpty) return;

    final printerService = getIt<PrinterService>();

    // Préparation des données pour le tableau PDF
    final tableData = logs.map((item) {
      return [
        Fmt.dateTime(item.log.timestamp),
        item.log.action.replaceAll('_', ' ').toUpperCase(),
        item.actorName,
        _formatDetailsPlain(item.log.details ?? ''),
      ];
    }).toList();

    final rangeText = _selectedRange == null
        ? 'Période complète'
        : 'Du ${Fmt.date(_selectedRange!.start)} au ${Fmt.date(_selectedRange!.end)}';

    await printerService.sharePdfReport(
      fileName: 'Journal_Audit_${DateTime.now().millisecondsSinceEpoch}',
      introText:
          'Journal d\'audit du système POS.\nFiltre : $rangeText\nExporté le : ${Fmt.dateTime(DateTime.now())}',
      shareMessage: 'Voici le journal d\'audit exporté au format PDF.',
      subject: 'Export Journal d\'Audit',
      tableHeaders: ['Date', 'Action', 'Acteur', 'Détails'],
      tableData: tableData,
    );
  }

  String _formatDetailsPlain(String details) {
    try {
      final Map<String, dynamic> data = jsonDecode(details);
      if (data.isEmpty) return '-';
      return data.entries
          .map((e) => '${e.key.toUpperCase()}: ${e.value}')
          .join(', ');
    } catch (_) {
      return details;
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
      helpText: 'SÉLECTIONNER UNE PÉRIODE',
      confirmText: 'FILTRER',
      saveText: 'OK',
    );
    if (range != null) setState(() => _selectedRange = range);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<PosDatabase>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Journal d\'audit',
              style: TextStyle(
                fontWeight: FontWeight.w900, // Ligne 52
                color: AppColors.textPrimary, // Ligne 53
                fontSize: 18,
              ),
            ),
            if (_selectedRange != null)
              Text(
                '${Fmt.date(_selectedRange!.start)} - ${Fmt.date(_selectedRange!.end)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range_rounded,
              color: _selectedRange != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            onPressed: _pickDateRange,
            tooltip: 'Filtrer par date',
          ),
          StreamBuilder<List<AuditLogWithActor>>(
            stream: db.watchAuditLogs(
              start: _selectedRange?.start,
              end: _selectedRange?.end,
            ),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              return IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.primary,
                ),
                onPressed: logs.isEmpty
                    ? null
                    : () => _exportToPdf(context, logs),
                tooltip: 'Exporter en PDF',
              );
            },
          ),
          if (_selectedRange != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.danger),
              onPressed: () => setState(() => _selectedRange = null),
              tooltip: 'Effacer le filtre',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        child: StreamBuilder<List<AuditLogWithActor>>(
          stream: db.watchAuditLogs(
            start: _selectedRange?.start,
            end: _selectedRange?.end,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.danger),
                ),
              );
            }

            final logs = snapshot.data ?? [];

            if (logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_outlined, // Ligne 105
                      size: 80,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Historique vide',
                      style: TextStyle(
                        color: AppColors.textPrimary, // Ligne 105
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Les actions administratives apparaîtront ici.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ), // Ligne 110
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = logs[index];
                return _AuditLogCard(item: item);
              },
            );
          },
        ),
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLogWithActor item;

  const _AuditLogCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final log = item.log;
    final Color statusColor = _getLogColor(log.action);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicateur latéral de couleur pour une lecture rapide (Style Shopify Polaris)
              Container(width: 6, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              // Ligne 168
                              _formatActionLabel(log.action),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900, // Ligne 168
                                fontSize: 13,
                                letterSpacing: 0.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            Fmt.time(log.timestamp),
                            style: const TextStyle(
                              // Ligne 178
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4), // Ligne 188
                          Text(
                            item.actorName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Fmt.date(log.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (log.details != null && log.details!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _formatDetails(log.details!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.4,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLogColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('delete') ||
        a.contains('deactivated') ||
        a.contains('refund')) {
      return AppColors.danger;
    }
    if (a.contains('create') || a.contains('add') || a.contains('activated')) {
      return AppColors.success;
    }
    if (a.contains('price') ||
        a.contains('discount') ||
        a.contains('override')) {
      return Colors.orange;
    }
    return AppColors.primary;
  }

  String _formatActionLabel(String action) {
    return action.replaceAll('_', ' ').toUpperCase();
  }

  String _formatDetails(String details) {
    try {
      final Map<String, dynamic> data = jsonDecode(details);
      if (data.isEmpty) return 'Aucun détail supplémentaire.';
      return data.entries
          .map((e) => '${e.key.toUpperCase()}: ${e.value}')
          .join('\n');
    } catch (_) {
      return details;
    }
  }
}
