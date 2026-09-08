import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/repositories/item_repository.dart';
import '../../providers.dart';
import '../../shared/empty_state.dart';
import '../../shared/ios_large_title.dart';
import '../../shared/status_chip.dart';
import '../inbox/item_actions.dart';

/// 记忆库：全部成卡的管理视图。
/// 搜索（全文）/ 筛选（语言、状态）/ 分组（库 + 未分类兜底）。
///
/// [active]：非活动 Tab 时 build 短路，停止构建与流监听（减少后台开销）。
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.active = true});

  final bool active;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    final filter = ref.watch(libraryFilterProvider);
    final items = ref.watch(libraryItemsProvider);
    final collections = ref.watch(collectionsProvider);
    final links = ref.watch(itemCollectionLinksProvider);
    final stats = ref.watch(collectionStatsProvider);

    return Column(
      children: [
        const IOSLargeTitle('记忆库'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '搜索卡片（全文）',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(libraryFilterProvider.notifier).state =
                            filter.copyWith(search: '');
                      },
                    ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (v) => ref.read(libraryFilterProvider.notifier).state =
                filter.copyWith(search: v),
          ),
        ),
        // 筛选行：状态 + 语言
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: '全部',
                  selected: filter.status == null,
                  onTap: () => ref.read(libraryFilterProvider.notifier).state =
                      filter.copyWith(status: null),
                ),
                _FilterChip(
                  label: '学习中',
                  selected: filter.status == 'learning',
                  onTap: () => _setStatus('learning'),
                ),
                _FilterChip(
                  label: '已掌握',
                  selected: filter.status == 'mastered',
                  onTap: () => _setStatus('mastered'),
                ),
                _FilterChip(
                  label: '冷置',
                  selected: filter.status == 'cold',
                  onTap: () => _setStatus('cold'),
                ),
                const SizedBox(width: 8),
                const VerticalDivider(),
                _FilterChip(
                  label: '日',
                  selected: filter.lang == 'ja',
                  onTap: () => _setLang('ja'),
                ),
                _FilterChip(
                  label: '英',
                  selected: filter.lang == 'en',
                  onTap: () => _setLang('en'),
                ),
                _FilterChip(
                  label: '中',
                  selected: filter.lang == 'zh',
                  onTap: () => _setLang('zh'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.collections_bookmark_outlined,
                  title: '记忆库还空着',
                  subtitle: '收件箱的条目成卡后会自动出现在这里（默认未分类）。',
                );
              }
              return _groupedList(
                context,
                list,
                collections.value ?? const [],
                links.value ?? const [],
                stats.value ?? const {},
              );
            },
          ),
        ),
      ],
    );
  }

  void _setStatus(String s) {
    final f = ref.read(libraryFilterProvider);
    ref.read(libraryFilterProvider.notifier).state = f.copyWith(status: s);
  }

  void _setLang(String l) {
    ref.read(libraryFilterProvider.notifier).state =
        ref.read(libraryFilterProvider).toggleLang(l);
  }

  Widget _groupedList(
    BuildContext context,
    List<ItemWithCard> items,
    List<CollectionRow> collections,
    List<ItemCollectionRow> links,
    Map<int, ({int total, int mastered})> stats,
  ) {
    // itemId → 主库
    final primaryOf = <int, int>{};
    for (final link in links) {
      if (link.isPrimary) primaryOf[link.itemId] = link.collectionId;
    }

    final groups = <CollectionRow, List<ItemWithCard>>{};
    final ungrouped = <ItemWithCard>[];
    final colById = {for (final c in collections) c.id: c};
    for (final item in items) {
      final cid = primaryOf[item.item.id];
      final col = cid == null ? null : colById[cid];
      if (col == null) {
        ungrouped.add(item);
      } else {
        groups.putIfAbsent(col, () => []).add(item);
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(libraryItemsProvider);
        ref.invalidate(collectionStatsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
        children: [
          for (final entry in groups.entries)
            _CollectionGroup(
              collection: entry.key,
              items: entry.value,
              stat: stats[entry.key.id],
              onRename: () => _renameCollection(context, entry.key),
              onDelete: () => _deleteCollection(context, entry.key),
            ),
          if (ungrouped.isNotEmpty)
            _CollectionGroup(
              collection: CollectionRow(
                id: -1,
                name: '未分类',
                parentId: null,
                ownerId: null,
                isSystem: true,
                createdAt: DateTime(0),
              ),
              items: ungrouped,
              stat: null,
              isDefaultGroup: true,
              onRename: () {},
              onDelete: () {},
            ),
        ],
      ),
    );
  }

  Future<void> _renameCollection(
      BuildContext context, CollectionRow col) async {
    final ctrl = TextEditingController(text: col.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('重命名分组'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: '名称'),
          autofocus: true,
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
    if (name != null && name.isNotEmpty) {
      await ref.read(itemRepositoryProvider).renameCollection(col.id, name);
      ref.invalidate(collectionsProvider);
      ref.invalidate(collectionStatsProvider);
    }
  }

  Future<void> _deleteCollection(
      BuildContext context, CollectionRow col) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('删除分组「${col.name}」？'),
        content: const Text('条目不会被删除，会回到「未分类」。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(itemRepositoryProvider).deleteCollection(col.id);
      ref.invalidate(collectionsProvider);
      ref.invalidate(collectionStatsProvider);
    }
  }
}

/// 分组头部：名称 + 卡片数/掌握率 + 菜单（重命名/删除）。
class _CollectionGroup extends ConsumerWidget {
  const _CollectionGroup({
    required this.collection,
    required this.items,
    required this.stat,
    this.isDefaultGroup = false,
    required this.onRename,
    required this.onDelete,
  });

  final CollectionRow collection;
  final List<ItemWithCard> items;
  final ({int total, int mastered})? stat;
  final bool isDefaultGroup;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = stat == null
        ? 0.0
        : (stat!.total == 0 ? 0.0 : stat!.mastered / stat!.total);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(
          isDefaultGroup ? Icons.folder_outlined : Icons.folder,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          collection.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          stat == null
              ? '${items.length} 张'
              : '${stat!.total} 张 · 掌握 ${(ratio * 100).toStringAsFixed(0)}%',
        ),
        // 菜单：重命名 / 删除（系统库允许改名；默认「未分类」不做任何操作）
        trailing: PopupMenuButton<String>(
          onSelected: (v) =>
              v == 'rename' ? onRename() : (v == 'delete' ? onDelete() : null),
          itemBuilder: (_) => [
            if (!isDefaultGroup)
              const PopupMenuItem(value: 'rename', child: Text('重命名')),
            if (!isDefaultGroup && !collection.isSystem)
              const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
        children: [
          for (final item in items)
            ListTile(
              leading: LanguageBadge(lang: item.item.lang),
              title: Text(
                item.card?.prompt ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                item.card?.answer ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: StatusChip(status: item.item.status),
              onTap: () => ItemActions.open(context, ref, item),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
