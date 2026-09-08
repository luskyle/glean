import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers.dart';

/// 云盘备份配置（B 档）：通道选择 + WebDAV 凭据 + 立即备份/恢复。
/// iCloud Drive 为 iOS 主力通道；WebDAV 覆盖国内 Android/桌面。
class CloudBackupSection extends ConsumerStatefulWidget {
  const CloudBackupSection({super.key});

  @override
  ConsumerState<CloudBackupSection> createState() => _CloudBackupSectionState();
}

class _CloudBackupSectionState extends ConsumerState<CloudBackupSection> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _channel = 'none';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _channel = s.syncChannel;
    _urlCtrl.text = s.webdavUrl ?? '';
    _userCtrl.text = s.webdavUser ?? '';
    _passCtrl.text = s.webdavPassword ?? '';
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectChannel(String channel) async {
    final s = ref.read(settingsProvider);
    await s.setSyncChannel(channel);
    setState(() => _channel = channel);
    ref.invalidate(syncServiceProvider);
  }

  Future<void> _saveWebdav() async {
    final s = ref.read(settingsProvider);
    await s.setWebdavUrl(_urlCtrl.text.trim());
    await s.setWebdavUser(_userCtrl.text.trim());
    await s.setWebdavPassword(_passCtrl.text);
    ref.invalidate(syncServiceProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('WebDAV 已保存')));
    }
  }

  Future<void> _run(String action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final svc = ref.read(syncServiceProvider);
      final String? err =
          action == 'backup' ? await svc.backup() : await svc.restore();
      if (err != null) {
        messenger.showSnackBar(SnackBar(content: Text(err)));
      } else {
        if (action == 'backup') {
          await ref.read(settingsProvider).markBackupNow();
        } else {
          ref.invalidate(inboxItemsProvider);
          ref.invalidate(libraryItemsProvider);
          ref.invalidate(reviewOverviewProvider);
          ref.invalidate(quotaProvider);
          ref.invalidate(collectionsProvider);
        }
        messenger.showSnackBar(
            SnackBar(content: Text(action == 'backup' ? '备份完成' : '已从云端恢复')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('操作失败：$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final last = s.lastBackupAt;
    final channelLabel = switch (_channel) {
      'icloud' => 'iCloud Drive',
      'webdav' => 'WebDAV',
      _ => '未配置',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined,
                    size: 22, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text('云盘备份',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '通道：$channelLabel'
              '${last != null ? ' · 最近备份 ${DateFormat('MM-dd HH:mm').format(last)}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              '数据只同步文本元数据与复习日志，媒体永不进入服务器',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'icloud', label: Text('iCloud Drive')),
                ButtonSegment(value: 'webdav', label: Text('WebDAV')),
              ],
              selected: {_channel == 'webdav' ? 'webdav' : 'icloud'},
              onSelectionChanged: (v) => _selectChannel(v.first),
            ),
            if (_channel == 'webdav') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'WebDAV 地址',
                  hintText: 'https://dav.jianguoyun.com/dav/',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(labelText: '账号'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '密码'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: _saveWebdav,
                  child: const Text('保存'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _run('backup'),
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('立即备份'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run('restore'),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('从云端恢复'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
