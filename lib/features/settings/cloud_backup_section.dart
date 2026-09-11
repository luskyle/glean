import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/sync/netdisk/ali_drive.dart';
import '../../data/sync/netdisk/baidu_auth.dart';
import '../../data/sync/netdisk/common.dart';
import '../../data/sync/netdisk/onedrive_drive.dart';
import '../../providers.dart';

/// 云盘备份配置：通道选择 + 各通道凭据 + 立即备份/恢复。
/// - iCloud Drive：iOS 主力通道
/// - WebDAV：坚果云 / NAS（零开发直连）
/// - 百度网盘 / 阿里云盘 / OneDrive：C 档原生适配器
///   （开放平台申请 Client Id/Secret + oob 授权码绑定）
class CloudBackupSection extends ConsumerStatefulWidget {
  const CloudBackupSection({super.key});

  @override
  ConsumerState<CloudBackupSection> createState() => _CloudBackupSectionState();
}

class _CloudBackupSectionState extends ConsumerState<CloudBackupSection> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _idCtrl = TextEditingController(); // 当前网盘通道的 Client ID
  final _secretCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String _channel = 'none';
  bool _busy = false;
  bool _oauthBusy = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _channel = s.syncChannel;
    _urlCtrl.text = s.webdavUrl ?? '';
    _userCtrl.text = s.webdavUser ?? '';
    _passCtrl.text = s.webdavPassword ?? '';
    _loadChannelCreds(s);
  }

  void _loadChannelCreds(dynamic s) {
    switch (_channel) {
      case 'baidu':
        _idCtrl.text = s.baiduClientId ?? '';
        _secretCtrl.text = s.baiduClientSecret ?? '';
      case 'ali':
        _idCtrl.text = s.aliClientId ?? '';
        _secretCtrl.text = s.aliClientSecret ?? '';
      case 'onedrive':
        _idCtrl.text = s.oneClientId ?? '';
        _secretCtrl.text = s.oneClientSecret ?? '';
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _idCtrl.dispose();
    _secretCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectChannel(String channel) async {
    final s = ref.read(settingsProvider);
    await s.setSyncChannel(channel);
    _loadChannelCreds(s);
    setState(() => _channel = channel);
    ref.invalidate(syncServiceProvider);
  }

  // ---- WebDAV ----

  Future<void> _saveWebdav() async {
    final s = ref.read(settingsProvider);
    await s.setWebdavUrl(_urlCtrl.text.trim());
    await s.setWebdavUser(_userCtrl.text.trim());
    await s.setWebdavPassword(_passCtrl.text);
    ref.invalidate(syncServiceProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('WebDAV 已保存，正在同步…')));
    }
    await _run('sync');
  }

  // ---- OAuth 网盘（百度 / 阿里 / OneDrive 经通用面板接入）----

  bool _hasToken(String channel) {
    final prefs = ref.read(sharedPrefsProvider);
    return switch (channel) {
      'baidu' => BaiduTokenStore(prefs).hasToken,
      'ali' => PrefsTokenStore(prefs, 'ali').hasToken,
      'onedrive' => PrefsTokenStore(prefs, 'onedrive').hasToken,
      _ => false,
    };
  }

  Future<void> _saveCreds(String channel) async {
    final s = ref.read(settingsProvider);
    final id = _idCtrl.text.trim();
    final secret = _secretCtrl.text.trim();
    switch (channel) {
      case 'baidu':
        await s.setBaiduClientId(id);
        await s.setBaiduClientSecret(secret);
      case 'ali':
        await s.setAliClientId(id);
        await s.setAliClientSecret(secret);
      case 'onedrive':
        await s.setOneClientId(id);
        await s.setOneClientSecret(secret);
    }
    ref.invalidate(syncServiceProvider);
    _snack('$channel 凭据已保存');
  }

  Uri? _authorizeUri(String channel) {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      _snack('请先填写并保存 Client ID');
      return null;
    }
    return Uri.parse(switch (channel) {
      'baidu' => BaiduAuth.buildAuthorizeUrl(id),
      'ali' => AliDrive.buildAuthorizeUrl(id),
      'onedrive' => OneDriveDrive.buildAuthorizeUrl(id),
      _ => throw UnsupportedError(channel),
    });
  }

  Future<void> _openAuth(String channel) async {
    final uri = _authorizeUri(channel);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    _snack('浏览器授权后，把地址栏 code 复制粘贴到下方');
  }

  Future<void> _exchange(String channel) async {
    final code = _codeCtrl.text.trim();
    final id = _idCtrl.text.trim();
    final secret = _secretCtrl.text.trim();
    if (code.isEmpty || id.isEmpty || secret.isEmpty) {
      _snack('请填写 Client ID / Secret 与授权码');
      return;
    }
    setState(() => _oauthBusy = true);
    try {
      switch (channel) {
        case 'baidu':
          final t = await BaiduAuth.exchangeCode(
            code: code,
            clientId: id,
            clientSecret: secret,
          );
          await BaiduTokenStore(ref.read(sharedPrefsProvider)).save(t);
        case 'ali':
          final t = await exchangeNetdiskToken(
            endpoint: Uri.parse(AliDrive.tokenUrl),
            body: {
              'grant_type': 'authorization_code',
              'code': code,
              'client_id': id,
              'client_secret': secret,
            },
          );
          await PrefsTokenStore(ref.read(sharedPrefsProvider), 'ali').save(t);
        case 'onedrive':
          final t = await exchangeNetdiskToken(
            endpoint: Uri.parse(OneDriveDrive.tokenUrl),
            body: {
              'grant_type': 'authorization_code',
              'code': code,
              'client_id': id,
              'client_secret': secret,
              'redirect_uri': 'oob',
              'scope': 'Files.ReadWrite.AppFolder offline_access User.Read',
            },
          );
          await PrefsTokenStore(ref.read(sharedPrefsProvider), 'onedrive').save(t);
      }
      _codeCtrl.clear();
      ref.invalidate(syncServiceProvider);
      _snack('授权成功，可以同步了');
    } catch (e) {
      _snack('授权失败：$e');
    } finally {
      if (mounted) setState(() => _oauthBusy = false);
    }
  }

  Future<void> _unbind(String channel) async {
    final prefs = ref.read(sharedPrefsProvider);
    switch (channel) {
      case 'baidu':
        await BaiduTokenStore(prefs).clear();
      case 'ali':
        await PrefsTokenStore(prefs, 'ali').clear();
      case 'onedrive':
        await PrefsTokenStore(prefs, 'onedrive').clear();
    }
    ref.invalidate(syncServiceProvider);
    _snack('已解除授权');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---- 通用 ----

  Future<void> _run(String action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final svc = ref.read(syncServiceProvider);
      final String? err = switch (action) {
        'sync' => await svc.syncNow(),
        'restore' => await svc.restore(),
        _ => await svc.backup(),
      };
      if (err != null) {
        messenger.showSnackBar(SnackBar(content: Text(err)));
      } else {
        if (action != 'restore') {
          await ref.read(settingsProvider).markBackupNow();
        }
        ref.invalidate(libraryItemsProvider);
        ref.invalidate(collectionsProvider);
        final msg = switch (action) {
          'sync' => '同步完成',
          'restore' => '已从云端恢复',
          _ => '备份完成',
        };
        messenger.showSnackBar(SnackBar(content: Text(msg)));
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
      'baidu' => '百度网盘',
      'ali' => '阿里云盘',
      'onedrive' => 'OneDrive',
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
            const Text(
              '数据只同步文本元数据（收藏/分组/标签），媒体永不进入服务器',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final (v, label) in const [
                  ('icloud', 'iCloud Drive'),
                  ('webdav', 'WebDAV'),
                  ('baidu', '百度网盘'),
                  ('ali', '阿里云盘'),
                  ('onedrive', 'OneDrive'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _channel == v,
                    onSelected: (_) => _selectChannel(v),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_channel == 'webdav') ...[
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
            if (_channel == 'baidu' ||
                _channel == 'ali' ||
                _channel == 'onedrive') ...[
              TextField(
                controller: _idCtrl,
                decoration: const InputDecoration(
                  labelText: 'Client ID',
                  hintText: '开放平台申请的 API Key',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _secretCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Client Secret'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _saveCreds(_channel),
                  child: const Text('保存凭据'),
                ),
              ),
              const Divider(height: 28),
              if (!_hasToken(_channel)) ...[
                const Text(
                  '授权三步：① 打开授权页 → ② 复制授权码 → ③ 粘贴并绑定',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _openAuth(_channel),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('打开网页授权'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(
                    labelText: '授权码（code）',
                    hintText: '浏览器地址栏 ?code= 后面的内容',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _oauthBusy ? null : () => _exchange(_channel),
                    child: const Text('绑定授权'),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '已授权 $channelLabel（令牌随同步自动刷新）',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _unbind(_channel),
                      child: const Text('解绑'),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _run('sync'),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('立即同步'),
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