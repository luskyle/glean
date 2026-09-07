import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

const kSchemaVersion = 1;

/// 拾忆主库（drift/SQLite）。
///
/// 打开方式：`driftDatabase(name: 'shiyi')`（drift_flutter 一站式，
/// 自带 sqlite3_flutter_libs 原生库与 path 处理；测试中改为内存库）。
@DriftDatabase(
  tables: [Words, Cards, Items, ReviewLogs, Collections, ItemCollections, ItemTags],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 打开磁盘上的应用数据库（正式运行入口）。
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'shiyi'));

  /// 测试用内存库。
  factory AppDatabase.forTesting() =>
      AppDatabase(NativeDatabase.memory(logStatements: false));

  @override
  int get schemaVersion => kSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedSystemCollections();
        },
        onUpgrade: (m, from, to) async {
          // 破坏性迁移前自动导出 .bak（技术调研 §四）：当前仅占位，
          // 数据模型锁定后再补备份导出。
          await m.createAll();
        },
      );

  Future<void> _seedSystemCollections() async {
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(
        collections,
        [
          CollectionsCompanion.insert(
            name: '工作',
            isSystem: const Value(true),
            createdAt: now,
          ),
          CollectionsCompanion.insert(
            name: '日语',
            isSystem: const Value(true),
            createdAt: now,
          ),
          CollectionsCompanion.insert(
            name: '灵感',
            isSystem: const Value(true),
            createdAt: now,
          ),
          CollectionsCompanion.insert(
            name: '未分类',
            isSystem: const Value(true),
            createdAt: now,
          ),
        ],
      );
    });
  }
}