import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../telephony/telephony_platform.dart';
import 'api_client.dart';

class SyncService {
  final ApiClient apiClient;
  final AppDatabase database;

  SyncService({
    required this.apiClient,
    required this.database,
  });

  Future<int> performDeltaSync({String countryCode = 'CR'}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastEtag = prefs.getString('etag_$countryCode');
    final lastSyncTimestampStr = prefs.getString('last_sync_$countryCode');
    final lastSync = lastSyncTimestampStr != null ? DateTime.tryParse(lastSyncTimestampStr) : null;

    try {
      final response = await apiClient.getDelta(
        countryCode: countryCode,
        since: lastSync,
        ifNoneMatch: lastEtag,
      );

      if (response.statusCode == 304) {
        debugPrint('Delta sync: dataset up to date (304 Not Modified)');
        return 0;
      }

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];
      final newEtag = response.headers.value('etag') ?? (data['etag'] as String?);

      debugPrint('Delta sync: processing ${items.length} incoming number updates...');

      int insertedCount = 0;
      await database.batch((batch) {
        for (final item in items) {
          final map = item as Map<String, dynamic>;
          final e164 = map['e164_number'] as int;
          final ccode = map['country_code'] as String;
          final callerName = map['caller_name'] as String?;
          final spamScore = (map['spam_score'] as num?)?.toDouble() ?? 0.0;
          final category = (map['category'] as String?) ?? 'unknown';
          final verified = (map['is_verified_business'] as bool?) ?? false;

          batch.insert(
            database.localNumbers,
            LocalNumbersCompanion(
              e164Number: Value(BigInt.from(e164)),
              countryCode: Value(ccode),
              callerName: Value(callerName),
              spamScore: Value(spamScore),
              category: Value(category),
              isVerifiedBusiness: Value(verified),
              isBlocked: Value(spamScore >= 0.80),
              updatedAt: Value(DateTime.now()),
            ),
            mode: InsertMode.insertOrReplace,
          );
          insertedCount++;
        }
      });

      // Save state
      if (newEtag != null) {
        await prefs.setString('etag_$countryCode', newEtag);
      }
      await prefs.setString('last_sync_$countryCode', DateTime.now().toUtc().toIso8601String());

      // On iOS: Reload CallKit Extension
      await TelephonyPlatform.reloadCallDirectoryExtension();

      debugPrint('Delta sync successfully completed. $insertedCount numbers synced.');
      return insertedCount;
    } catch (e) {
      debugPrint('Delta sync failed: $e');
      rethrow;
    }
  }
}
