import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dictionary/language_catalog.dart';
import '../../domain/study_plan.dart';
import '../../providers.dart';
import 'study_session_screen.dart';

/// 关卡学习页：某一语言的阶梯关卡（基础 → 进阶，渐进解锁）。
///
/// 解锁规则：第一级恒解锁；下一级需上一级已学数达到门槛
/// （min(上一级总词数, 100)）。
class StudyLevelScreen extends ConsumerStatefulWidget {
  const StudyLevelScreen({super.key, required this.lang});

  final String lang;

  @override
  ConsumerState<StudyLevelScreen> createState() => _StudyLevelScreenState();
}

class _StudyLevelScreenState extends ConsumerState<StudyLevelScreen> {
  Map<String, int> _learned = {};
  Map<String, int> _totals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(itemRepositoryProvider);
    final levels = StudyPlan.levelsFor(widget.lang);
    final totals = <String, int>{};
    for (final l in levels) {
      totals[l] = await repo.levelWordCount(widget.lang, l);
    }
    final learned = await repo.learnedCountByLevel(widget.lang);
    if (!mounted) return;
    setState(() {
      _learned = learned;
      _totals = totals;
      _loading = false;
    });
  }

  Future<void> _openLevel(String level) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudySessionScreen(lang: widget.lang, level: level),
      ),
    );
    // 返回后刷新进度
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final info = LanguageCatalog.entries.firstWhere(
      (e) => e.code == widget.lang,
      orElse: () => LanguageCatalog.entries.first,
    );

    return Scaffold(
      appBar: AppBar(title: Text('学习 · ${info.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  '从基础开始，学会关卡里的词即可解锁更难关卡',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < levels.length; i++)
                  _LevelCard(
                    label: StudyPlan.labelOf(levels[i]),
                    total: _totals[levels[i]] ?? 0,
                    learned: _learned[levels[i]] ?? 0,
                    done:
                        (_learned[levels[i]] ?? 0) >= (_totals[levels[i]] ?? 0),
                    unlocked: StudyPlan.isLevelUnlocked(
                      index: i,
                      prevLearned: _learned[levels[i == 0 ? 0 : i - 1]] ?? 0,
                      prevTotal: _totals[levels[i == 0 ? 0 : i - 1]] ?? 0,
                    ),
                    onTap: () => _openLevel(levels[i]),
                  ),
              ],
            ),
    );
  }

  List<String> get levels => StudyPlan.levelsFor(widget.lang);
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.label,
    required this.total,
    required this.learned,
    required this.done,
    required this.unlocked,
    required this.onTap,
  });

  final String label;
  final int total;
  final int learned;
  final bool done;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : (learned / total).clamp(0.0, 1.0);
    final statusText =
        done ? '已学完' : (unlocked ? '已学 $learned/$total' : '🔒 先学完上一关');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: unlocked && !done ? onTap : null,
        enabled: unlocked && !done,
        leading: Icon(
          done
              ? Icons.verified
              : (unlocked ? Icons.play_circle_outline : Icons.lock_outline),
          color: done
              ? scheme.primary
              : (unlocked ? scheme.primary : scheme.onSurfaceVariant),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        trailing: done
            ? Icon(Icons.check_circle, color: scheme.primary)
            : (unlocked ? const Icon(Icons.chevron_right) : null),
      ),
    );
  }
}
