import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Singleton provider for the local SQLite database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(() => db.close());
  return db;
});
