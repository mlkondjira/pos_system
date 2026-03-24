import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import 'audit_log_bloc.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  bool _isExporting = false;

  Future<void> _exportLogs(List<AuditLogWithActor> logs) async {
    setState(() => _isExporting = true);
    try {
      // 1. Préparation des données CSV
      List<List<dynamic>> rows = [];
      rows.add(['Date', 'Heure', 'Acteur', 'Action Brute', 'Description', 'ID Cible']);

      for (final item in logs) {
        final date = item.log.timestamp;
        rows.add([
          DateFormat('dd/MM/yyyy').format(date),
          DateFormat('HH:mm:ss').format(date),
          item.actorName,
          item.log.action,
          _formatAction(item.log), // Utilisation de la fonction helper
          item.log.targetEntityId.toString(),
        ]);
      }

      // 2. Génération CSV (avec échappement des guillemets)
      String csvData = rows.map((row) {
        return row.map((cell) {
          final value = cell?.toString() ?? '';
          if (value.contains(';') || value.contains('"') || value.contains('\n')) {
            return '"${value.replaceAll('"', '""')}"';
          }
          return value;
        }).join(';');
      }).join('\n');

      // 3. Encodage avec BOM pour compatibilité Excel
      final bytes = utf8.encode(csvData);
      final bom = [0xEF, 0xBB, 0xBF];

      final directory = await getTemporaryDirectory();
      final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final path = p.join(directory.path, 'audit_logs_$nowStr.csv');

      final file = File(path);
      await file.writeAsBytes(bom + bytes);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'text/csv')],
          subject: 'Export Audit Logs',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuditLogBloc>()..add(LoadAuditLogs()),
      child: BlocBuilder<AuditLogBloc, AuditLogState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Journal d\'audit'),
            actions: [
              if (state.logs.isNotEmpty)
                IconButton(
                  icon: _isExporting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                      : const Icon(Icons.download_rounded),
                  tooltip: 'Exporter en CSV',
                  onPressed: _isExporting ? null : () => _exportLogs(state.logs),
                ),
            ],
          ),
          body: Builder(builder: (context) {
            if (state.isLoading && state.logs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.logs.isEmpty) {
              return const Center(child: Text('Aucune action enregistrée.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final logWithActor = state.logs[index];
                return _AuditLogTile(log: logWithActor.log, actorName: logWithActor.actorName);
              },
            );
          }),
        ),
      ),
    );
  }
}

// Fonction helper extraite pour être utilisée par l'UI et l'export
String _formatAction(AuditLog log) {
  try {
    String targetLabel = '(ID: ${log.targetEntityId})';
    Map<String, dynamic>? details;
    if (log.details != null) {
      details = jsonDecode(log.details!);
      if (details != null && details['targetName'] != null) {
        targetLabel = '"${details['targetName']}"';
      }
    }

    switch (log.action) {
      case 'user_deactivated':
        return 'a désactivé l\'utilisateur $targetLabel';
      case 'user_activated':
        return 'a réactivé l\'utilisateur $targetLabel';
      case 'user_pin_changed':
        return 'a changé le code PIN de l\'utilisateur $targetLabel';
      case 'user_role_changed':
        if (details != null) {
          return 'a changé le rôle de l\'utilisateur $targetLabel de "${details['from']}" à "${details['to']}"';
        }
        return 'a changé le rôle de l\'utilisateur (ID: ${log.targetEntityId})';
      case 'product_price_changed':
        if (log.details != null) {
          final details = jsonDecode(log.details!);
          return 'a changé le prix de "${details['productName']}" de ${Fmt.currency(details['from'])} à ${Fmt.currency(details['to'])}';
        }
        return 'a changé le prix du produit (ID: ${log.targetEntityId})';
      default:
        return log.action.replaceAll('_', ' ');
    }
  } catch (e) {
    return log.action;
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLog log;
  final String actorName;

  const _AuditLogTile({required this.log, required this.actorName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                children: [
                  TextSpan(
                    text: actorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextSpan(text: ' ${_formatAction(log)}'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                Fmt.dateTime(log.timestamp),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}