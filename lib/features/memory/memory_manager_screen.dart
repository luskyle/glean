import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../providers.dart';
import '../../shared/empty_state.dart';
import '../inbox/item_actions.dart';
import '../library/media_library_screen.dart';
import 'memory_set_browse_screen.dart';
import 'memory_set_review_screen.dart';

/// 记忆管理（记忆教练）：用户自建「记忆集」，
/// 对集合整体学习/复习/回顾。集合可拉入素材自动成卡，或拉入已有收藏。
class MemoryManagerScreen extends ConsumerWidget {
  const MemoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(memorySetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆管理'),
        actions: [
          IconButton(
            tooltip: '新建记忆集',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _createSet(context, ref),
          ),
        ],
      ),
      body: sets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.workspaces_outline,
                title: '还没有记忆集',
                subtitle: '建一个集合（如「考证刷题」），把素材或收藏拉进来，'
                    '就能对集合整体复习。',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final s in list) _SetCard(set: s)],
          );
        },
      ),
    );
  }

  Future<void> _createSet(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新建记忆集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: purposeCtrl,
              decoration: const InputDecoration(
                labelText: '用途 / 说明（可选）',
                hintText: '如：考研英语真题词 / 产品知识库',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameCtrl.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final setId = await ref
          .read(memorySetRepositoryProvider)
          .create(name, purpose: purposeCtrl.text.trim());
      ref.invalidate(memorySetsProvider);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemorySetDetailScreen(setId: setId),
          ),
        );
      }
    }
  }
}

/// 记忆集卡片：名称 + 用途 + 条数 + 进入。
class _SetCard extends ConsumerWidget {
  const _SetCard({required this.set});

  final MemorySetRow set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // 条目数（异步加载展示）
    final count = ref.watch(_memorySetCountProvider(set.id)).valueOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.workspaces_outline, color: scheme.primary),
        ),
        title: Text(
          set.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          set.purpose == null || set.purpose!.isEmpty
              ? '${count ?? '…'} 条内容'
              : '${set.purpose} · ${count ?? '…'} 条',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemorySetDetailScreen(setId: set.id),
          ),
        ),
      ),
    );
  }
}

/// 集合条目数。
final _memorySetCountProvider =
    FutureProvider.autoDispose.family<int, int>((ref, setId) async {
  final repo = ref.watch(memorySetRepositoryProvider);
  return (await repo.itemsOf(setId)).length;
});

/// 记忆集详情：条目列表 + 拉入素材/收藏 + 开始复习 + 浏览回顾。
class MemorySetDetailScreen extends ConsumerWidget {
  const MemorySetDetailScreen({super.key, required this.setId});

  final int setId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 无法用 watch + Future detail，用 Provider.future 组合
    final detail = ref.watch(memorySetDetailProvider(setId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.valueOrNull?.set.name ?? '记忆集'),
        actions: [
          IconButton(
            tooltip: '添加素材',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => _addAssets(context, ref),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (d) {
          final items = d.items;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 用途说明
              if (d.set.purpose != null && d.set.purpose!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    d.set.purpose!,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              // 操作行：开始复习 / 浏览回顾
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            items.isEmpty ? null : () => _startReview(context),
                        icon: const Icon(Icons.style, size: 18),
                        label: const Text('开始复习'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            items.isEmpty ? null : () => _browse(context),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('浏览回顾'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 条目列表
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            '集合还是空的。\n点右上角「添加素材」从素材库批量拉入（自动成卡），'
                            '或去记忆库把收藏加进来。',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            color: scheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(
                                it.card?.prompt ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                it.card?.answer ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'remove') {
                                    _removeItem(context, ref, it.item.id);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'remove', child: Text('移出集合')),
                                ],
                              ),
                              onTap: () => ItemActions.open(context, ref, it),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addAssets(BuildContext context, WidgetRef ref) async {
    final assets = await ref.read(mediaAssetsProvider.future);
    if (!context.mounted) return;
    if (assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('素材库为空，先去「素材库」链接本地目录')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MediaLibraryScreen()),
      );
      return;
    }
    // 素材多选弹层
    final picked = <MediaAssetRow>[];
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssetMultiPicker(
        assets: assets,
        selected: picked,
      ),
    );
    if (result == true && picked.isNotEmpty && context.mounted) {
      final setRepo = ref.read(memorySetRepositoryProvider);
      await setRepo.addMediaAssets(setId, picked);
      if (!context.mounted) return;
      ref.invalidate(memorySetDetailProvider(setId));
      ref.invalidate(_memorySetCountProvider(setId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已加入 ${picked.length} 个素材，自动成卡')),
      );
    }
  }

  void _removeItem(BuildContext context, WidgetRef ref, int itemId) {
    ref.read(memorySetRepositoryProvider).removeItem(setId, itemId);
    ref.invalidate(memorySetDetailProvider(setId));
    ref.invalidate(_memorySetCountProvider(setId));
  }

  void _startReview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemorySetReviewSessionScreen(setId: setId),
      ),
    );
  }

  void _browse(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemorySetBrowseScreen(setId: setId),
      ),
    );
  }
}

/// 素材多选弹层。
class _AssetMultiPicker extends StatefulWidget {
  const _AssetMultiPicker({required this.assets, required this.selected});

  final List<MediaAssetRow> assets;
  final List<MediaAssetRow> selected;

  @override
  State<_AssetMultiPicker> createState() => _AssetMultiPickerState();
}

class _AssetMultiPickerState extends State<_AssetMultiPicker> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('选择素材（多选，自动成卡）',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Flexible(
              child: SizedBox(
                height: 320,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 120,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: widget.assets.length,
                  itemBuilder: (_, i) {
                    final a = widget.assets[i];
                    final sel = _checked.contains(a.id);
                    return InkWell(
                      onTap: () => setState(() {
                        if (sel) {
                          _checked.remove(a.id);
                        } else {
                          _checked.add(a.id);
                        }
                      }),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: MediaThumb(asset: a),
                          ),
                          if (sel)
                            Container(
                              color: scheme.primary.withValues(alpha: 0.25),
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.check_circle,
                                  size: 18, color: Colors.white),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _checked.isEmpty
                    ? null
                    : () {
                        widget.selected
                          ..clear()
                          ..addAll(widget.assets
                              .where((a) => _checked.contains(a.id)));
                        Navigator.pop(context, true);
                      },
                child: Text('加入（${_checked.length}）'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 素材缩略图（选择器用）。
class MediaThumb extends StatelessWidget {
  const MediaThumb({super.key, required this.asset});

  final MediaAssetRow asset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (asset.type == 'video') {
      return Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.videocam_outlined,
            color: scheme.onSurfaceVariant, size: 24),
      );
    }
    if (asset.path.isNotEmpty && File(asset.path).existsSync()) {
      return Image.file(
        File(asset.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
      );
    }
    return Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant);
  }
}
