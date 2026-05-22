// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/database/pos_database.dart';
import '../../data/services/printer_service.dart';
import '../../data/services/sync_service.dart'; // N'oubliez pas l'import !
import '../../core/utils/logger_service.dart';
import '../../core/utils/notification_service.dart';
import 'package:pos_system/core/services/navigation_service.dart';
import '../../presentation/screens/settings/audit_log_bloc.dart'; // Correction du chemin d'importation
import '../../presentation/blocs/override_report_bloc.dart'; // Ajout de l'importation pour OverrideReportBloc
import '../../presentation/blocs/theme_bloc.dart';
import '../../presentation/blocs/products_bloc.dart';
import '../../presentation/blocs/discounts_bloc.dart'; // Keep this import
import '../../presentation/blocs/users_bloc.dart'; // New import for UsersBloc

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Service de navigation global
  getIt.registerLazySingleton<NavigationService>(() => NavigationService());

  // Base de données SQLite (singleton)
  getIt.registerLazySingleton<PosDatabase>(() => PosDatabase());

  // Service de logging (singleton)
  getIt.registerLazySingleton<LoggerService>(() => LoggerService());

  // Service de notification locale (singleton)
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  // Service de synchronisation (singleton) - Nécessite la Database et Supabase
  getIt.registerLazySingleton<SyncService>(
      () => SyncService(getIt<PosDatabase>(), Supabase.instance.client));

  // Service imprimante Bluetooth (singleton)
  getIt.registerLazySingleton<PrinterService>(
      () => PrinterService(getIt<PosDatabase>()));

  // ─── BLOCS ──────────────────────────────────────────────────────────────
  // Enregistrez les Blocs en tant que "factory" pour obtenir une nouvelle instance à chaque fois.
  getIt.registerFactory<UsersBloc>(() => UsersBloc(getIt<PosDatabase>()));
  getIt.registerFactory<AuditLogBloc>(() => AuditLogBloc(getIt<PosDatabase>()));
  getIt.registerFactory<OverrideReportBloc>(
      () => OverrideReportBloc(getIt<PosDatabase>()));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(getIt<PosDatabase>()));
  getIt.registerFactory<DiscountsBloc>(
      () => DiscountsBloc(getIt<PosDatabase>()));
  getIt.registerFactory<ThemeBloc>(() => ThemeBloc(getIt<PosDatabase>()));
}
