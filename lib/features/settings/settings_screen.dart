import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/analytics_service.dart';
import '../../data/export/export_service.dart';
import '../../providers.dart';
import 'cloud_backup_section.dart';

/// 设置：偏好 / 数据所有权 / 关于。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- 云盘备份（B 档）----
          const CloudBackupSection(),
          const SizedBox(height: 12),
          // ---- 云盘媒体维护（浏览器直传，仅 WebDAV 通道）----
          const _MediaMaintenanceCard(),
          const SizedBox(height: 12),
          // ---- 偏好 ----
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('外观'),
                  subtitle: Text(_themeLabel(ref.watch(themeModeProvider))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('跟随系统'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('浅色'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('深色'),
                      ),
                    ],
                    selected: {ref.watch(themeModeProvider)},
                    onSelectionChanged: (v) async {
                      final mode = v.first;
                      ref.read(themeModeProvider.notifier).state = mode;
                      await ref.read(settingsProvider).setThemeMode(
                            switch (mode) {
                              ThemeMode.light => 'light',
                              ThemeMode.dark => 'dark',
                              _ => 'system',
                            },
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ---- 数据所有权 ----
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('导出我的收藏库'),
                  subtitle: const Text('收藏元数据 → 本地 zip（JSON 机器可读）'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final path = await ExportService()
                          .export(ref.read(databaseProvider));
                      ref
                          .read(analyticsProvider)
                          .track(AnalyticsEvents.exportUsed);
                      messenger.showSnackBar(
                        SnackBar(content: Text('已导出：$path')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('导出失败：$e')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('隐私与数据'),
                  subtitle: const Text('数据默认只存在本机，不强制登录；服务器不存储你的媒体文件'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Glean',
                    applicationVersion: '0.1.0',
                    children: const [
                      Text(
                        '· 收藏数据默认仅保存在本机\n'
                        '· 所有生成内容均可编辑、可删除\n'
                        '· 导出 / 删除即删，随时拿回数据\n'
                        '· 服务器永不接收媒体文件（存储铁律）',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('关于 Glean'),
              subtitle: Text('把散落的好内容拾进来：收藏 / 分类 / 云盘同步。'),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => '浅色',
        ThemeMode.dark => '深色',
        _ => '跟随系统',
      };
}

/// 云盘媒体维护（浏览器直传的 /glean/media/ 文件；仅 WebDAV 通道支持）。
class _MediaMaintenanceCard extends ConsumerStatefulWidget {
  const _MediaMaintenanceCard();

  @override
  ConsumerState<_MediaMaintenanceCard> createState() =>
      _MediaMaintenanceCardState();
}

class _MediaMaintenanceCardState extends ConsumerState<_MediaMaintenanceCard> {
  Map<String, int>? _files; // 文件名 -> 字节数
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    // 媒体文件维护仅对支持媒体接口的通道显示（WebDAV / 各网盘适配器）
    const mediaChannels = {'webdav', 'baidu', 'ali', 'onedrive'};
    if (!mediaChannels.contains(settings.syncChannel)) {
      return const SizedBox.shrink();
    }

    final totalBytes = (_files?.values ?? const []).fold<int>(0, (a, b) => a + b);
    final summary = _files == null
        ? '点击查看浏览器直传的媒体文件'
        : '${_files!.length} 个文件 · ${_fmtSize(totalBytes)}';

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('云盘媒体文件'),
            subtitle: Text(_loading ? '统计中…' : summary),
            trailing: const Icon(Icons.refresh),
            onTap: _refresh,
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('清理云盘孤儿文件'),
            subtitle: const Text('删除条目已删但留在云盘的媒体文件'),
            onTap: _cleanup,
          ),
        ],
      ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1 << 10) return '${(bytes / (1 << 10)).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final cloud = ref.read(syncServiceProvider).cloud;
    final list = await cloud.listMedia();
    if (!mounted) return;
    setState(() {
      _files = list;
      _loading = false;
    });
  }

  Future<void> _cleanup() async {
    final cloud = ref.read(syncServiceProvider).cloud;
    final list = await cloud.listMedia();
    if (list.isEmpty) {
      _snack('媒体目录为空');
      return;
    }

    // 云盘文件名 vs 本地条目路径引用（取尾部文件名）
    final db = ref.read(databaseProvider);
    final items = await db.select(db.items).get();
    final used = items
        .map((i) => i.mediaPath?.split('/').last)
        .whereType<String>()
        .toSet();
    final orphans = list.keys.where((n) => !used.contains(n)).toList();
    if (orphans.isEmpty) {
      _snack('没有未引用的孤儿文件');
      return;
    }
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('清理 ${orphans.length} 个孤儿文件？'),
        content: const Text('这些文件在云盘 /glean/media/ 下，但没有对应的收藏条目引用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清理'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    var deleted = 0;
    for (final n in orphans) {
      if (await cloud.deleteMedia('/glean/media/$n')) deleted++;
    }
    if (!mounted) return;
    _snack('已清理 $deleted 个孤儿文件');
    await _refresh();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}