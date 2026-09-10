import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../data/database/database.dart';
import '../../providers.dart';
import '../../shared/empty_state.dart';

/// 本地素材库（记忆教练：链接不导入）：
/// 桌面端链接目录（可填用途）→ 递归扫描图片/视频建索引；
/// 目录分组视图 + 网格/列表切换；素材仅本地使用，不参与云同步。
class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  String _viewMode = 'grid';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('素材库'),
        actions: [
          // 视图切换：网格 / 列表
          SegmentedButton<String>(
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(
                  value: 'grid',
                  icon: Icon(Icons.grid_view_outlined, size: 16)),
              ButtonSegment(
                  value: 'list',
                  icon: Icon(Icons.view_agenda_outlined, size: 16)),
            ],
            selected: {_viewMode},
            onSelectionChanged: (s) => setState(() => _viewMode = s.first),
          ),
          IconButton(
            tooltip: '链接本地目录',
            icon: const Icon(Icons.folder_open),
            onPressed: _linkFolder,
          ),
        ],
      ),
      body: _FoldersView(viewMode: _viewMode),
    );
  }

  // ---- 目录链接（带用途） ----

  Future<void> _linkFolder() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择素材目录（图片 / 视频）',
      );
      if (dir == null || dir.isEmpty || !mounted) return;
      // 可输入用途说明
      final purpose = await _promptPurpose(title: '目录用途（可选）');
      if (!mounted) return;
      await ref.read(mediaRepositoryProvider).linkFolder(dir, purpose: purpose);
      ref.invalidate(mediaAssetsProvider);
      ref.invalidate(mediaFoldersProvider);
      messenger.showSnackBar(SnackBar(content: Text('已链接：$dir')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('链接失败：$e')));
    }
  }

  Future<String?> _promptPurpose(
      {required String title, String? initial}) async {
    final ctrl = TextEditingController(text: initial ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '如：备考截图 / 课程海报'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('跳过'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return (result == null || result.isEmpty) ? null : result;
  }
}

/// 目录级视图：目录卡片列表 + 目录内素材网格/列表。
class _FoldersView extends ConsumerWidget {
  const _FoldersView({required this.viewMode});

  final String viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(mediaFoldersProvider);
    final assets = ref.watch(mediaAssetsProvider);

    return folders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.photo_library_outlined,
              title: '素材库还空着',
              subtitle: '链接本地目录后，图片/视频素材会出现在这里。',
            ),
          );
        }
        // 目录分组：每个目录一块（标题行 + 素材网格）
        final blocks = <Widget>[];
        for (final folder in list) {
          final assetsOf =
              assets.value?.where((a) => a.folderId == folder.id).toList() ??
                  const <MediaAssetRow>[];
          blocks.add(_FolderHeader(folder: folder));
          if (assetsOf.isEmpty) {
            blocks.add(Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '（目录下没有媒体文件）',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ));
          } else if (viewMode == 'grid') {
            // iPhone 相册风格：紧凑正方形小格子密度排列，无文字
            blocks.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: [
                    for (final a in assetsOf)
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: _AssetGridTile(asset: a),
                      ),
                  ],
                ),
              ),
            );
          } else {
            // 列表模式：缩略图 + 文件名 + 用途
            for (final a in assetsOf) {
              blocks.add(_AssetListTile(asset: a));
            }
          }
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: blocks,
        );
      },
    );
  }
}

/// 目录头：名称 + 用途 + 菜单（改用途 / 取消链接）。
class _FolderHeader extends ConsumerWidget {
  const _FolderHeader({required this.folder});

  final MediaFolderRow folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
      child: Row(
        children: [
          Icon(Icons.folder, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (folder.purpose != null && folder.purpose!.isNotEmpty)
                  Text(
                    '用途：${folder.purpose}',
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'purpose') {
                _editPurpose(context, ref);
              } else if (v == 'unlink') {
                _unlink(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'purpose', child: Text('修改用途')),
              PopupMenuItem(value: 'unlink', child: Text('取消链接目录')),
            ],
          ),
        ],
      ),
    );
  }

  void _editPurpose(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: folder.purpose ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('目录用途'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) {
      ref.read(mediaRepositoryProvider).updateFolderPurpose(
            folder.id,
            result.isEmpty ? null : result,
          );
      ref.invalidate(mediaFoldersProvider);
    }
  }

  void _unlink(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('取消链接「${folder.name}」？'),
        content: const Text('只移除素材索引，本地文件不会删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('取消链接'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(mediaRepositoryProvider).unlinkFolder(folder.id);
      ref.invalidate(mediaFoldersProvider);
      ref.invalidate(mediaAssetsProvider);
    }
  }
}

/// 素材网格项（图片缩略 / 视频首帧）。
class _AssetGridTile extends ConsumerStatefulWidget {
  const _AssetGridTile({required this.asset});

  final MediaAssetRow asset;

  @override
  ConsumerState<_AssetGridTile> createState() => _AssetGridTileState();
}

class _AssetGridTileState extends ConsumerState<_AssetGridTile> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    if (widget.asset.type == 'video' && File(widget.asset.path).existsSync()) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.file(File(widget.asset.path));
    _video = ctrl;
    try {
      await ctrl.initialize();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = widget.asset.path;
    final fileExists = path.isNotEmpty && File(path).existsSync();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.asset.type == 'video' && _videoReady)
            _VideoPreview(controller: _video!)
          else if (fileExists)
            GestureDetector(
              onTap: _openAssetPage,
              onLongPress: () => setState(() => _selected = !_selected),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _broken(scheme),
              ),
            )
          else
            _broken(scheme),
          // 视频角标
          if (widget.asset.type == 'video')
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.videocam,
                    size: 12, color: Colors.white),
              ),
            ),
          // 选中态
          if (_selected)
            Positioned.fill(
              child: Container(
                color: scheme.primary.withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 32),
              ),
            ),
        ],
      ),
    );
  }

  void _openAssetPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssetDetailSheet(asset: widget.asset),
    );
  }

  Widget _broken(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
    );
  }
}

/// 素材详情页：查看大图 + 用途 + 操作（改用途 / 取消链接）。
class _AssetDetailSheet extends ConsumerWidget {
  const _AssetDetailSheet({required this.asset});

  final MediaAssetRow asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('素材', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              asset.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // 大图
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _AssetDetailMedia(asset: asset),
            ),
            const SizedBox(height: 16),
            Text('用途说明', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              asset.purpose == null || asset.purpose!.isEmpty
                  ? '未填写'
                  : asset.purpose!,
              style: TextStyle(
                  fontSize: 14,
                  color: asset.purpose == null
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editPurpose(context, ref),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('编辑用途'),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  style:
                      OutlinedButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: () => _unlink(context, ref),
                  icon: const Icon(Icons.link_off, size: 16),
                  label: const Text('取消链接'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editPurpose(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: asset.purpose ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('素材用途'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '这张图/视频是干嘛用的'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref
          .read(mediaRepositoryProvider)
          .setAssetPurpose([asset.id], result.isEmpty ? null : result);
      ref.invalidate(mediaAssetsProvider);
    }
  }

  void _unlink(BuildContext context, WidgetRef ref) {
    ref.read(mediaRepositoryProvider).unlinkAsset(asset.id);
    ref.invalidate(mediaAssetsProvider);
    Navigator.of(context).pop();
  }
}

/// 素材大图（详情页）。
class _AssetDetailMedia extends StatefulWidget {
  const _AssetDetailMedia({required this.asset});

  final MediaAssetRow asset;

  @override
  State<_AssetDetailMedia> createState() => _AssetDetailMediaState();
}

class _AssetDetailMediaState extends State<_AssetDetailMedia> {
  VideoPlayerController? _video;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.asset.type == 'video' && File(widget.asset.path).existsSync()) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.file(File(widget.asset.path));
    _video = ctrl;
    try {
      await ctrl.initialize();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.asset.type == 'video' && _videoReady) {
      return _VideoPreview(controller: _video!);
    }
    if (File(widget.asset.path).existsSync()) {
      return Image.file(
        File(widget.asset.path),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image_outlined,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    return Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant);
  }
}

/// 素材列表项（列表模式）。
class _AssetListTile extends StatelessWidget {
  const _AssetListTile({required this.asset});

  final MediaAssetRow asset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: File(asset.path).existsSync() && asset.type == 'image'
                ? Image.file(File(asset.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: scheme.onSurfaceVariant))
                : Icon(Icons.videocam_outlined, color: scheme.onSurfaceVariant),
          ),
        ),
        title: Text(asset.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          asset.purpose == null || asset.purpose!.isEmpty
              ? '图片 · 未填写用途${asset.type == 'video' ? '（视频）' : ''}'
              : asset.purpose!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _AssetDetailSheet(asset: asset),
        ),
      ),
    );
  }
}

/// 视频预览（静音循环播放首帧）。
class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.setLooping(true);
    widget.controller.setVolume(0);
    widget.controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: widget.controller.value.size.width,
        height: widget.controller.value.size.height,
        child: VideoPlayer(widget.controller),
      ),
    );
  }
}

/// 素材渲染（图片 / 视频首帧）——收藏弹层与记忆库卡片共用。
class SourceMediaView extends ConsumerStatefulWidget {
  const SourceMediaView({super.key, required this.assetId, this.height = 160});

  final int assetId;
  final double height;

  @override
  ConsumerState<SourceMediaView> createState() => _SourceMediaViewState();
}

class _SourceMediaViewState extends ConsumerState<SourceMediaView> {
  VideoPlayerController? _video;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final assets = await ref.read(mediaAssetsProvider.future);
    final asset = assets.where((a) => a.id == widget.assetId).firstOrNull;
    if (asset == null || !File(asset.path).existsSync()) return;
    if (asset.type == 'video') {
      final ctrl = VideoPlayerController.file(File(asset.path));
      _video = ctrl;
      try {
        await ctrl.initialize();
        if (mounted) setState(() => _videoReady = true);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final assets = ref.watch(mediaAssetsProvider).value ?? const [];
    final asset = assets.where((a) => a.id == widget.assetId).firstOrNull;

    Widget child;
    if (asset == null || !File(asset.path).existsSync()) {
      child = Container(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child:
            Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
      );
    } else if (asset.type == 'video' && _videoReady && _video != null) {
      child = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _video!.value.size.width,
          height: _video!.value.size.height,
          child: VideoPlayer(_video!),
        ),
      );
      _video!.setLooping(true);
      _video!.setVolume(0);
      _video!.play();
    } else {
      child = Image.file(
        File(asset.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image_outlined,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: child,
      ),
    );
  }
}
