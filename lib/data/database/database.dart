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
  tables: [
    Words,
    Cards,
    Items,
    ReviewLogs,
    Collections,
    ItemCollections,
    ItemTags
  ],
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
    await ensureDefaultCollections();
  }

  /// 确保默认分类（工作/学习/未分类）存在且为系统分类（不可删除）。
  /// 幂等：旧库/新库均可安全调用（启动 bootstrap 也会执行）。
  Future<void> ensureDefaultCollections() async {
    const defaults = ['工作', '学习', '未分类'];
    final existing = await (select(collections)
          ..where((t) => t.isSystem.equals(true)))
        .get();
    final names = existing.map((c) => c.name).toSet();

    for (final name in defaults) {
      if (names.contains(name)) continue;
      await into(collections).insert(
        CollectionsCompanion.insert(
          name: name,
          isSystem: const Value(true),
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}
