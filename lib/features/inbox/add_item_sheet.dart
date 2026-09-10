import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/analytics_service.dart';
import '../../data/repositories/item_repository.dart';
import '../../domain/tagging/language.dart';
import '../../providers.dart';
import '../library/media_library_screen.dart';

/// 手录收藏：**一个输入框收藏，其余全自动**（零摩擦）。
///
/// - 输入内容 → 自动识别语言、默认未分类、进入收件箱
/// - 「更多选项」折叠：类型 / 标签 / 本地素材 / 分组（可后补）
/// - 类型（词条/语录/灵感）写入收藏来源（source），媒体优先记 photo
class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({super.key});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  bool _moreOpen = false;
  String _kind = 'auto';
  final Set<String> _tags = {};
  int? _collectionId;
  int? _mediaAssetId; // 本地素材库引用（不参与云同步）

  @override
  void dispose() {
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  String _guessedKind(String text) {
    if (text.contains(RegExp(r'[\s\u3000]{2,}|\p{P}', unicode: true)) &&
        text.length > 20) {
      return 'quote';
    }
    return 'word';
  }

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('先输入要收藏的内容')));
      return;
    }

    final lang = langCodeOf(detectLang(content));
    // 类型（词条/语录/灵感）→ source；媒体优先记 photo
    final kind = _kind == 'auto' ? _guessedKind(content) : _kind;
    final source = _mediaAssetId != null
        ? 'photo'
        : (kind == 'word' || kind == 'quote' || kind == 'idea' ? kind : 'manual');

    await ref.read(itemRepositoryProvider).createItem(
          note: content,
          source: source,
          lang: lang,
          tags: _tags.toList(),
          collectionId: _collectionId,
          mediaAssetId: _mediaAssetId,
        );
    ref.read(analyticsProvider).track(
      AnalyticsEvents.itemCollected,
      props: {'source': source, 'kind': kind},
    );

    if (mounted) {
      Navigator.of(context).pop();
      ref.invalidate(libraryItemsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已收藏到收件箱')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final collections = ref.watch(collectionsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('收藏', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              '一句话就够了：输入内容，其余自动完成',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // ---- 主输入（唯一必填）----
            TextField(
              controller: _contentCtrl,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '想收藏的内容：单词、句子、灵感…',
                suffixIcon: _contentCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _contentCtrl.clear();
                          setState(() {});
                        },
                      ),
              ),
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 14),
            // ---- 分类选择（主界面直接可选）----
            collections.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (cols) => Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<int?>(
                  value: _collectionId,
                  underline: const SizedBox.shrink(),
                  hint: const Text('放到未分类'),
                  icon: const Icon(Icons.folder_outlined, size: 20),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('未分类'),
                    ),
                    ...cols.where((c) => c.name != kUncategorizedName).map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() => _collectionId = v),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // ---- 收起/展开更多 ----
            InkWell(
              onTap: () => setState(() => _moreOpen = !_moreOpen),
              child: Row(
                children: [
                  Icon(
                    _moreOpen ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '更多选项',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (_moreOpen) ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'auto', label: Text('自动')),
                  ButtonSegment(value: 'word', label: Text('词条')),
                  ButtonSegment(value: 'quote', label: Text('语录')),
                  ButtonSegment(value: 'idea', label: Text('灵感')),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 12),
              // ---- 本地素材（链接素材库，不导入）----
              _MediaPickerRow(
                assetId: _mediaAssetId,
                onChanged: (id) => setState(() => _mediaAssetId = id),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagCtrl,
                decoration: const InputDecoration(
                  labelText: '标签',
                  hintText: '回车添加',
                ),
                onSubmitted: (t) {
                  final tag = t.trim();
                  if (tag.isNotEmpty) {
                    setState(() => _tags.add(tag));
                    _tagCtrl.clear();
                  }
                },
              ),
              if (_tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 6,
                    children: _tags
                        .map((t) => InputChip(
                              label: Text('#$t'),
                              onDeleted: () => setState(() => _tags.remove(t)),
                            ))
                        .toList(),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('收藏'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 素材选择行：从本地素材库挑选素材挂到收藏上（不导入、不同步）。
class _MediaPickerRow extends ConsumerWidget {
  const _MediaPickerRow({required this.assetId, required this.onChanged});

  final int? assetId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(mediaAssetsProvider).value ?? const [];
    final scheme = Theme.of(context).colorScheme;
    final selected = assetId == null
        ? null
        : assets.where((a) => a.id == assetId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Text('本地素材（可选）', style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            // 跳去素材库
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MediaLibraryScreen()),
              ),
              icon: const Icon(Icons.photo_library_outlined, size: 16),
              label: const Text('素材库'),
            ),
          ],
        ),
        if (assets.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '素材库为空，先去「素材库」链接本地目录',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          )
        else
          DropdownButton<int?>(
            value: assetId,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: const Text('挑选素材…'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('不挂素材'),
              ),
              for (final a in assets)
                DropdownMenuItem<int?>(
                  value: a.id,
                  child: Text(
                    a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => onChanged(v),
          ),
        if (selected != null && assetId != null) ...[
          const SizedBox(height: 8),
          SourceMediaView(assetId: assetId!, height: 120),
        ],
      ],
    );
  }
}