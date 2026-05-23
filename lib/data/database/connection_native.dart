// lib/data/database/connection_native.dart
// Connexion SQLite pour Android, iOS, Windows, macOS, Linux
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor openConnection() {
  return driftDatabase(
    name: 'pos_database',
    // web n'est PAS spécifié ici — uniquement pour les plateformes natives
  );
}
