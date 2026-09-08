import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../database/database.dart';
import 'cloud_drive.dart';
import 'sync_snapshot.dart';

/// 云盘同步服务（B 档，多端合并模式）：
/// 全量快照 → 用户自有云盘（iCloud Drive / WebDAV）；恢复时幂等合并入库。
///
/// 多端模型（浏览器插件 / 桌面 / 移动共用同一份快照契约）：
/// - 无账号：用户云盘即身份（C 档账号留待 V2）
/// - [syncNow]：先拉取远端并合并（按 id 幂等并包，本地已存在行保留），
///   再推送合并后的全量——两端各自新增互不丢失，同 id 编辑冲突本地优先。
///
/// 依据《收藏数据存储方案》：媒体与全文永不进入自家服务器；
/// 这里同步的只有文本元数据 + 复习日志。
class SyncService {
  SyncService({required this.db, required this.cloud});

  final AppDatabase db;
  final CloudDrive cloud;

  /// 多端同步：拉取远端 → 幂等合并 → 推送全量。成功返回 null，失败返回错误文案。
  Future<String?> syncNow() async {
    final pull = await _pullMerge();
    if (pull != null) return pull;
    return backup();
  }

  Future<String?> _pullMerge() async {
    if (!await cloud.isAvailable()) return '${cloud.name} 不可用，请先配置';
    try {
      final text = await cloud.download();
      if (text == null || text.isEmpty) return null; // 无远端备份：仅推送
      final snap = SyncSnapshot.decode(text);
      await merge(db, snap);
      return null;
    } catch (e, st) {
      debugPrint('同步拉取失败：$e\n$st');
      return '同步失败：$e';
    }
  }

  /// 备份到云盘，成功返回 null，失败返回错误文案。
  Future<String?> backup() async {
    if (!await cloud.isAvailable()) return '${cloud.name} 不可用，请先配置';
    try {
      final snap = await SyncSnapshot.capture(db);
      await cloud.upload(snap.encode());
      return null;
    } catch (e) {
      return '备份失败：$e';
    }
  }

  /// 从云盘恢复（幂等合并：重复恢复不会重复插入）。
  Future<String?> restore() async {
    if (!await cloud.isAvailable()) return '${cloud.name} 不可用，请先配置';
    try {
      final text = await cloud.download();
      if (text == null || text.isEmpty) return '云端暂无备份';
      final snap = SyncSnapshot.decode(text);
      await merge(db, snap);
      return null;
    } catch (e, st) {
      debugPrint('restore 失败：$e\n$st');
      return '恢复失败：$e';
    }
  }

  Future<bool> cloudHasBackup() async {
    try {
      return await cloud.backupExists();
    } catch (_) {
      return false;
    }
  }

  /// 幂等合并：所有行按主键 insertOrIgnore（重复恢复安全）；
  /// 被墓碑记录的实体跳过（删除操作不会被同步复活）。
  Future<void> merge(AppDatabase db, SyncSnapshot snap) async {
    final rows = snap.rows;
    final tombstoneRows = await db.select(db.syncDeletions).get();
    final tombstones =
        tombstoneRows.map((r) => '${r.entityTable}|${r.entityId}').toSet();

    await db.transaction(() async {
      for (final raw in rows['collections'] as List? ?? const []) {
        final m = raw as Map<String, dynamic>;
        if (tombstones.contains('collections|${m['id']}')) continue;
        await db.into(db.collections).insert(
              CollectionsCompanion(
                id: Value(m['id'] as int),
                name: Value(m['name'] as String),
                parentId: Value(m['parentId'] as int?),
                ownerId: Value(m['ownerId'] as int?),
                isSystem: Value(m['isSystem'] as bool? ?? false),
                createdAt: Value(_date(m['createdAt'])),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      for (final raw in rows['cards'] as List? ?? const []) {
        final m = raw as Map<String, dynamic>;
        if (tombstones.contains('cards|${m['id']}')) continue; // 墓碑：跳过复活
        await db.into(db.cards).insert(
              CardsCompanion(
                id: Value(m['id'] as int),
                wordId: Value(m['wordId'] as int?),
                kind: Value(m['kind'] as String? ?? 'word'),
                prompt: Value(m['prompt'] as String),
                answer: Value(m['answer'] as String),
                audioFile: Value(m['audioFile'] as String?),
                lang: Value(m['lang'] as String?),
                tags: Value(m['tags'] as String?),
                repetitions: Value(m['repetitions'] as int? ?? 0),
                easeFactor: Value((m['easeFactor'] as num? ?? 2.5).toDouble()),
                intervalDays: Value(m['intervalDays'] as int? ?? 0),
                dueAt: Value(_date(m['dueAt'])),
                lastReviewedAt: Value(_dateOrNull(m['lastReviewedAt'])),
                createdAt: Value(_date(m['createdAt'])),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      for (final raw in rows['items'] as List? ?? const []) {
        final m = raw as Map<String, dynamic>;
        if (tombstones.contains('items|${m['id']}')) continue;
        await db.into(db.items).insert(
              ItemsCompanion(
                id: Value(m['id'] as int),
                cardId: Value(m['cardId'] as int?),
                source: Value(m['source'] as String? ?? 'manual'),
                mediaPath: Value(m['mediaPath'] as String?),
                originalUrl: Value(m['originalUrl'] as String?),
                sourceTitle: Value(m['sourceTitle'] as String?),
                note: Value(m['note'] as String?),
                lang: Value(m['lang'] as String?),
                status: Value(m['status'] as String? ?? 'inbox'),
                createdAt: Value(_date(m['createdAt'])),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      for (final raw in rows['review_logs'] as List? ?? const []) {
        final m = raw as Map<String, dynamic>;
        await db.into(db.reviewLogs).insert(
              ReviewLogsCompanion(
                id: Value(m['id'] as int),
                cardId: Value(m['cardId'] as int),
                reviewedAt: Value(_date(m['reviewedAt'])),
                quality: Value(m['quality'] as int),
                intervalDays: Value(m['intervalDays'] as int),
                easeFactor: Value((m['easeFactor'] as num).toDouble()),
                state: Value(m['state'] as String),
                source: Value(m['source'] as String? ?? 'review'),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      for (final raw in rows['item_collections'] as List? ?? const []) {
        final m = raw as Map<String, dynamic>;
        // 所属条目已被墓碑删除 → 跳过（避免外键悬空）
        if (tombstones.contains('items|${m['itemId']}')) continue;
        await db.into(db.itemCollections).insert(
              ItemCollectionsCompanion.insert(
                itemId: m['itemId'] as int,
                collectionId: m['collectionId'] as int,
                isPrimary: Value(m['isPrimary'] as bool? ?? false),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      for (final raw in rows['item_tags'] as List? ?? const []) {
        final m = raw as Map<String, dynamic>;
        if (tombstones.contains('items|${m['itemId']}')) continue;
        await db.into(db.itemTags).insert(
              ItemTagsCompanion.insert(
                itemId: m['itemId'] as int,
                tag: m['tag'] as String,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  DateTime _date(Object? v) {
    // drift toJson 将 DateTime 序列化为 epoch 微秒（int）
    if (v is num) {
      return DateTime.fromMicrosecondsSinceEpoch(v.round());
    }
    return DateTime.parse(v as String);
  }

  DateTime? _dateOrNull(Object? v) {
    if (v == null || (v is String && v.isEmpty)) return null;
    return _date(v);
  }
}
