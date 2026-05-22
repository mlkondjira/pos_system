import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../screens/settings/sync_error_screen.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncService = getIt<SyncService>();

    return StreamBuilder<SyncProgress>(
      stream: syncService.statusStream,
      initialData: syncService.currentProgress,
      builder: (context, snapshot) {
        final progress = snapshot.data!;
        
        Color iconColor;
        IconData iconData;
        bool isRotating = false;

        switch (progress.status) {
          case SyncStatus.syncing:
            iconColor = AppColors.primary;
            iconData = Icons.sync_rounded;
            isRotating = true;
            _rotationController.repeat();
            break;
          case SyncStatus.upToDate:
            iconColor = AppColors.success;
            iconData = Icons.cloud_done_rounded;
            _rotationController.stop();
            break;
          case SyncStatus.error:
          case SyncStatus.partialError:
            iconColor = AppColors.danger;
            iconData = Icons.cloud_off_rounded;
            _rotationController.stop();
            break;
          default:
            iconColor = AppColors.textMuted;
            iconData = Icons.cloud_queue_rounded;
            _rotationController.stop();
        }

        return IconButton(
          icon: isRotating
              ? RotationTransition(
                  turns: _rotationController,
                  child: Icon(iconData, color: iconColor),
                )
              : Icon(iconData, color: iconColor),
          tooltip: progress.message.isNotEmpty ? progress.message : 'Statut synchro',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SyncErrorScreen()),
            );
          },
        );
      },
    );
  }
}