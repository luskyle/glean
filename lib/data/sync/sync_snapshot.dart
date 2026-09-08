import 'dart:convert';

import '../database/database.dart';

/// 同步快照：全库可恢复序列化（items/cards/collections/review_logs）。
/// 与 zip 导出共用同一数据源；增量合并能力随运行数据量增长再演进
/// （规划：<2MB/万条，全量快照即可满足早期规模）。
class SyncSnapshot {
  const SyncSnapshot({required this.payload});

  final Map<String, Object?> payload;

  String encode() => const JsonEncoder.withIndent(' ').convert(payload);

  /// 构建当前库的全量快照。
  static Future<SyncSnapshot> capture(AppDatabase db) async {
    final items = await db.select(db.items).get();
    final cards = await db.select(db.cards).get();
    final logs = await db.select(db.reviewLogs).get();
    final collections = await db.select(db.collections).get();
    final links = await db.select(db.itemCollections).get();
    final tags = await db.select(db.itemTags).get();

    final payload = <String, Object?>{
      'app': 'shiyi',
      'version': '0.1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'rows': <String, Object?>{
        'collections': collections.map((c) => c.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'cards': cards.map((c) => c.toJson()).toList(),
        'review_logs': logs.map((l) => l.toJson()).toList(),
        'item_collections': links.map((l) => l.toJson()).toList(),
        'item_tags': tags.map((t) => t.toJson()).toList(),
      },
    };
    return SyncSnapshot(payload: payload);
  }

  static SyncSnapshot decode(String text) {
    return SyncSnapshot(
      payload: jsonDecode(text) as Map<String, Object?>,
    );
  }

  Map<String, Object?> get rows =>
      (payload['rows'] as Map<String, dynamic>? ?? const {});
}

/// 兼容 zip 导出数据的只读访问（供测试/导出复用快照的对照）。
Map<String, Object?> extractRows(SyncSnapshot snapshot) => snapshot.rows;
