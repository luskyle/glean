import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';

/// 一键导出：收藏元数据 → 本地 zip（JSON 机器可读 + 说明）。
/// 依据《收藏数据存储方案》§8：数据所有权在用户侧，导出是基本承诺。
/// zip 内布局：`glean_data.json` + `README.txt`。
class ExportService {
  ExportService({Directory? directory}) : _overrideDirectory = directory;

  final Directory? _overrideDirectory;

  Future<Directory> _exportRoot() async {
    if (_overrideDirectory != null) return _overrideDirectory;
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, 'museum', 'export'));
  }

  Future<String> export(AppDatabase db) async {
    final exportDir = await _exportRoot();
    await exportDir.create(recursive: true);

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final zipPath = p.join(exportDir.path, 'glean_export_$timestamp.zip');

    final items = await db.select(db.items).get();
    final collections = await db.select(db.collections).get();

    final payload = <String, Object?>{
      'app': 'glean',
      'version': '0.1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'collections': collections
          .map((c) => {'id': c.id, 'name': c.name, 'is_system': c.isSystem})
          .toList(),
      'items': items.map((i) => i.toJson()).toList(),
    };

    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'glean_data.json',
          const JsonEncoder.withIndent('  ').convert(payload),
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'README.txt',
          'Glean 收藏助手导出包 $timestamp\n'
              '说明：glean_data.json 为全量数据（收藏条目/分组），\n'
              '字段见各对象键名，机器可读；可导入任意分析工具。\n'
              '数据默认仅存本机，导出即归属；删除数据请联系「设置 → 隐私与数据」。\n',
        ),
      );

    final bytes = ZipEncoder().encodeBytes(archive, level: 6);
    await File(zipPath).writeAsBytes(bytes);
    return zipPath;
  }
}