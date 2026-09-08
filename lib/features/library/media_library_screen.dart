import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../data/database/database.dart';
import '../../providers.dart';
import '../../shared/empty_state.dart';

/// 本地素材库（记忆教练：链接不导入）：
/// 桌面端选择目录 → 递归扫描图片/视频 → 建索引；素材仅本地使用，
/// 不参与云同步。素材可被收藏（卡片）引用。
class MediaLibraryScreen extends ConsumerWidget {
  const MediaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(mediaAssetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('素材库'),
        actions: [
          IconButton(
            tooltip: '链接本地目录',
            icon: const Icon(Icons.folder_open),
            onPressed: () => _linkFolder(context, ref),
          ),
        ],
      ),
      body: assets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.photo_library_outlined,
                title: '素材库还空着',
                subtitle: '链接本地目录后，图片/视频素材会出现在这里。',
                action: FilledButton.icon(
                  onPressed: () => _linkFolder(context, ref),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('链接目录'),
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => _AssetTile(asset: list[i]),
          );
        },
      ),
    );
  }

  /// 桌面端：文件选择器选目录 → 递归扫描入索引。
  Future<void> _linkFolder(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择素材目录（图片 / 视频）',
      );
      if (dir == null || dir.isEmpty) return;
      await ref.read(mediaRepositoryProvider).linkFolder(dir);
      ref.invalidate(mediaAssetsProvider);
      messenger.showSnackBar(SnackBar(content: Text('已链接：$dir')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('链接失败：$e')));
    }
  }
}

/// 素材网格项：图片缩略图 / 视频首帧。
class _AssetTile extends ConsumerStatefulWidget {
  const _AssetTile({required this.asset});

  final MediaAssetRow asset;

  @override
  ConsumerState<_AssetTile> createState() => _AssetTileState();
}

class _AssetTileState extends ConsumerState<_AssetTile> {
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
    } catch (_) {
      // 无法解码：显示静图占位
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
    final path = widget.asset.path;
    final fileExists = path.isNotEmpty && File(path).existsSync();

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: widget.asset.type == 'video' && _videoReady
                  ? _VideoPreview(controller: _video!)
                  : (fileExists
                      ? Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _broken(scheme),
                        )
                      : _broken(scheme)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                children: [
                  Icon(
                    widget.asset.type == 'video'
                        ? Icons.videocam_outlined
                        : Icons.image_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _broken(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: scheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }
}

/// 视频预览（静音循环首帧播放）。
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
/// 给定素材 id → 查素材 → 渲染；素材缺失显示占位。
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
        child: Icon(
          Icons.broken_image_outlined,
          color: scheme.onSurfaceVariant,
          size: 28,
        ),
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
