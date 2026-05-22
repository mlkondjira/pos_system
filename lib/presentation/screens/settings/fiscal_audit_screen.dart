import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../widgets/shared_widgets.dart';

class FiscalAuditScreen extends StatefulWidget {
  const FiscalAuditScreen({super.key});

  @override
  State<FiscalAuditScreen> createState() => _FiscalAuditScreenState();
}

class _FiscalAuditScreenState extends State<FiscalAuditScreen> {
  bool _isValidating = false;
  bool? _isIntegrityOk;
  DateTime? _lastCheck;
  final PosDatabase _db = getIt<PosDatabase>();

  Future<void> _runFullAudit() async {
    setState(() {
      _isValidating = true;
      _isIntegrityOk = null;
    });

    // On laisse un petit délai pour l'effet visuel
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Appel à la méthode de chaînage fiscal du DAO
    final result = await _db.salesDao.verifyFiscalIntegrity();
    
    if (mounted) {
      setState(() {
        _isIntegrityOk = result;
        _isValidating = false;
        _lastCheck = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit & Intégrité Fiscale'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 32),
            const SectionLabel('Journal de sécurité récent'),
            const SizedBox(height: 12),
            _buildAuditLogsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final Color statusColor = _isValidating 
        ? AppColors.primary 
        : (_isIntegrityOk == true ? AppColors.success : (_isIntegrityOk == false ? AppColors.danger : AppColors.textMuted));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(color: statusColor.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _isValidating ? Icons.sync_rounded : (_isIntegrityOk == true ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded),
            size: 64,
            color: statusColor,
          ),
          const SizedBox(height: 16),
          Text(
            _isValidating ? 'Vérification en cours...' : (_isIntegrityOk == true ? 'Base de données intègre' : (_isIntegrityOk == false ? 'ERREUR D\'INTÉGRITÉ DÉTECTÉE' : 'Analyse requise')),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
          ),
          const SizedBox(height: 8),
          Text(
            _isIntegrityOk == true 
                ? 'Toutes les ventes sont correctement chaînées et signées numériquement.'
                : (_isIntegrityOk == false 
                    ? 'Attention : Une modification manuelle hors application a été détectée dans l\'historique des ventes.'
                    : 'Lancez un audit pour vérifier la validité de la chaîne fiscale.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (_lastCheck != null) ...[
            const SizedBox(height: 12),
            Text('Dernier contrôle : ${Fmt.dateTime(_lastCheck!)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isValidating ? null : _runFullAudit,
              icon: _isValidating 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.shield_outlined),
              label: const Text('VÉRIFIER LA SIGNATURE DES VENTES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsList() {
    return StreamBuilder<List<AuditLogWithActor>>(
      stream: _db.watchAuditLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final logs = snapshot.data!.take(10).toList(); // On ne montre que les 10 derniers
        
        if (logs.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune action critique enregistrée.')));
        }

        return Column(
          children: logs.map((log) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: _getIconForAction(log.log.action),
              title: Text(_translateAction(log.log.action), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Par ${log.actorName} • ${Fmt.time(log.log.timestamp)}', style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 16),
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _getIconForAction(String action) {
    IconData iconData = Icons.info_outline_rounded;
    Color color = AppColors.primary;

    if (action.contains('delete')) {
      iconData = Icons.delete_forever_rounded;
      color = AppColors.danger;
    } else if (action.contains('price') || action.contains('discount')) {
      iconData = Icons.monetization_on_rounded;
      color = AppColors.warning;
    } else if (action.contains('user')) {
      iconData = Icons.person_off_rounded;
      color = AppColors.textPrimary;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  String _translateAction(String action) {
    switch (action) {
      case 'product_deleted': return 'Suppression de produit';
      case 'discount_override': return 'Remise exceptionnelle';
      case 'user_deactivated': return 'Désactivation d\'un compte';
      case 'product_price_changed': return 'Changement de prix';
      case 'inventory_adjusted': return 'Ajustement manuel de stock';
      default: return action;
    }
  }
}