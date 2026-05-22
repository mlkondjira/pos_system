import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../data/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../screens/settings/sync_error_screen.dart';

/// Widget global qui écoute les changements de statut de synchronisation
/// et affiche des notifications (SnackBars) de manière centralisée.
class GlobalSyncListener extends StatefulWidget {
  final Widget child;
  const GlobalSyncListener({super.key, required this.child});

  @override
  State<GlobalSyncListener> createState() => _GlobalSyncListenerState();
}

class _GlobalSyncListenerState extends State<GlobalSyncListener> {
  StreamSubscription<SyncProgress>? _subscription;
  SyncStatus? _lastStatus;
  String? _lastErrorMessage;
  SyncProgress? _currentProgress;

  @override
  void initState() {
    super.initState();
    // On s'abonne au flux du service de synchronisation
    _subscription = getIt<SyncService>().statusStream.listen(
      _handleSyncProgress,
    );

    // Initialisation avec l'état actuel du service
    _currentProgress = getIt<SyncService>().currentProgress;
    _lastStatus = _currentProgress?.status;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleSyncProgress(SyncProgress progress) {
    if (!mounted) return;

    final isError =
        progress.status == SyncStatus.error ||
        progress.status == SyncStatus.partialError;

    // Logique de filtrage pour éviter les répétitions inutiles :
    // On affiche le SnackBar seulement si on entre dans un état d'erreur
    // ou si le message d'erreur a changé par rapport au cycle précédent.
    if (isError &&
        (_lastStatus != progress.status ||
            _lastErrorMessage != progress.message)) {
      _showErrorSnackBar(progress.message);
    }

    setState(() {
      _lastStatus = progress.status;
      _lastErrorMessage = progress.message;
      _currentProgress = progress;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.sync_problem_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'DÉTAILS',
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SyncErrorScreen()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSyncing = _lastStatus == SyncStatus.syncing;
    // Si la valeur est 0, on passe 'null' pour avoir une animation de balayage indéterminée
    final double? value = (_currentProgress?.value ?? 0) > 0
        ? _currentProgress?.value
        : null;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SafeArea(
              bottom: false,
              child: AnimatedOpacity(
                opacity: isSyncing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  height: 2.5, // Épaisseur discrète style "navigateur web"
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
