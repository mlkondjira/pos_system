import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/services/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class SyncErrorScreen extends StatelessWidget {
  const SyncErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = getIt<PosDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreurs de Synchronisation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tout relancer',
            onPressed: () => getIt<SyncService>().forceSync(),
          ),
        ],
      ),
      body: StreamBuilder<List<SyncQueueData>>(
        stream: db.watchSyncErrors(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Tout est en ordre',
              subtitle: 'Aucune erreur de synchronisation détectée.',
            );
          }

          final errors = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: errors.length,
            itemBuilder: (context, index) {
              final error = errors[index];
              final isStockError =
                  error.entityType == 'stock_delta' ||
                  error.entityType == 'product';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isStockError
                        ? AppColors.warningSoft
                        : AppColors.dangerSoft,
                    child: Icon(
                      isStockError
                          ? Icons.inventory_2_rounded
                          : Icons.error_outline_rounded,
                      color: isStockError
                          ? AppColors.warning
                          : AppColors.danger,
                    ),
                  ),
                  title: Text(
                    '${error.entityType.toUpperCase()} #${error.entityId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error.errorMessage ?? 'Erreur inconnue',
                        style: const TextStyle(color: AppColors.danger),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tentatives : ${error.retryCount}/5',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.success,
                    ),
                    onPressed: () =>
                        db.retrySync(error.entityType, error.entityId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
