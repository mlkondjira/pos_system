// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/database/pos_database.dart';
import '../../data/services/printer_service.dart';
import '../../data/services/sync_service.dart'; // N'oubliez pas l'import !
// L'erreur "uri_does_not_exist" indique que ce fichier doit être créé.
import '../../presentation/screens/settings/users_bloc.dart';
import '../../presentation/screens/settings/audit_log_bloc.dart';
import '../../presentation/blocs/products_bloc.dart';
final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Base de données SQLite (singleton)
  getIt.registerLazySingleton<PosDatabase>(() => PosDatabase());

  // Service de synchronisation (singleton) - Nécessite la Database et Supabase
  getIt.registerLazySingleton<SyncService>(() =>
      SyncService(getIt<PosDatabase>(), Supabase.instance.client));

  // Service imprimante Bluetooth (singleton)
  getIt.registerLazySingleton<PrinterService>(() => PrinterService(getIt<PosDatabase>()));

  // ─── BLOCS ────────────────────────────────────────────────
  // Enregistrez les Blocs en tant que "factory" pour obtenir une nouvelle instance à chaque fois.
  getIt.registerFactory<UsersBloc>(() => UsersBloc(getIt<PosDatabase>()));
  getIt.registerFactory<AuditLogBloc>(() => AuditLogBloc(getIt<PosDatabase>()));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(getIt<PosDatabase>()));
}
