import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DataClassName('LocalNumber')
class LocalNumbers extends Table {
  Int64Column get e164Number => int64()();
  TextColumn get countryCode => text().withLength(min: 2, max: 8)();
  TextColumn get callerName => text().nullable()();
  RealColumn get spamScore => real().withDefault(const Constant(0.0))();
  TextColumn get category => text().withDefault(const Constant('unknown'))();
  BoolColumn get isVerifiedBusiness => boolean().withDefault(const Constant(false))();
  BoolColumn get isBlocked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {e164Number};
}

@DataClassName('CallLog')
class CallLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  Int64Column get e164Number => int64()();
  TextColumn get callerName => text().nullable()();
  TextColumn get callType => text().withDefault(const Constant('incoming'))(); // 'incoming', 'blocked', 'outgoing'
  RealColumn get spamScore => real().withDefault(const Constant(0.0))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [LocalNumbers, CallLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  Future<LocalNumber?> findNumber(BigInt number) =>
      (select(localNumbers)..where((tbl) => tbl.e164Number.equals(number))).getSingleOrNull();

  Future<List<LocalNumber>> getNumbersOrdered() =>
      (select(localNumbers)..orderBy([(tbl) => OrderingTerm.asc(tbl.e164Number)])).get();

  Future<int> upsertNumber(LocalNumbersCompanion entry) =>
      into(localNumbers).insertOnConflictUpdate(entry);

  Future<List<CallLog>> getRecentCalls({int limit = 50}) =>
      (select(callLogs)..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)])..limit(limit)).get();

  Future<int> addCallLog(CallLogsCompanion entry) =>
      into(callLogs).insert(entry);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    String folderPath;
    if (Platform.isIOS) {
      try {
        const channel = MethodChannel('cc.blackmatter.opencaller/callkit');
        final appGroupPath = await channel.invokeMethod<String>('getAppGroupDirectory');
        if (appGroupPath != null && appGroupPath.isNotEmpty) {
          folderPath = appGroupPath;
        } else {
          final dir = await getApplicationDocumentsDirectory();
          folderPath = dir.path;
        }
      } catch (_) {
        final dir = await getApplicationDocumentsDirectory();
        folderPath = dir.path;
      }
    } else {
      final dir = await getApplicationDocumentsDirectory();
      folderPath = dir.path;
    }

    final file = File(p.join(folderPath, 'opencaller_store.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
