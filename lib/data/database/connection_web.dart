// lib/data/database/connection_web.dart
// Connexion SQLite pour Flutter Web (via sql.js WASM)
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor openConnection() {
  return driftDatabase(
    name: 'pos_database',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
      // onResult est appelé quand la connexion Web est établie
      // (utile pour savoir si SharedWorker ou Web Worker est utilisé)
    ),
  );
}