import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';

/// 一键导出：收藏元数据 + 复习日志 → 本地 JSON（零依赖，机器可读）。
/// 依据《收藏数据存储方案》§8：数据所有权在用户侧，导出是基本承诺。
/// 后续版本升级为 zip（media + items.json）与系统分享。
class ExportService {
  const ExportService();

  Future<String> export(AppDatabase db) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = p.join(dir.path, 'museum', 'export');
    await Directory(exportDir).create(recursive: true);

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final base = p.join(exportDir, 'shiyi_export_$timestamp');

    final items = await db.select(db.items).get();
    final cards = await db.select(db.cards).get();
    final logs = await db.select(db.reviewLogs).get();
    final collections = await db.select(db.collections).get();

    final payload = <String, Object?>{
      'app': 'shiyi',
      'version': '0.1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'collections': collections
          .map((c) => {'id': c.id, 'name': c.name, 'is_system': c.isSystem})
          .toList(),
      'items': items.map((i) => i.toJson()).toList(),
      'cards': cards.map((c) => c.toJson()).toList(),
      'review_logs': logs.map((l) => l.toJson()).toList(),
    };

    final jsonPath = p.join(base, 'shiyi_data.json');
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return jsonPath;
  }
}