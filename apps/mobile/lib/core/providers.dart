import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart';
import 'network/api_client.dart';
import 'network/sync_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final client = ref.watch(apiClientProvider);
  final db = ref.watch(databaseProvider);
  return SyncService(apiClient: client, database: db);
});
