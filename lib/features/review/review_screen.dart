import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/empty_state.dart';
import 'curve_screen.dart';
import 'review_session_screen.dart';

/// 复习页（默认落点）：今日任务 + 开始复习 + 遗忘曲线入口。
///
/// [active]：非活动 Tab 时 build 短路，停止构建与统计监听（减少后台开销）。
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!active) return const SizedBox.shrink();
    final overview = ref.watch(reviewOverviewProvider);
    final scheme = Theme.of(context).colorScheme;

    return overview.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (o) {
        if (o.due == 0 && o.masterRatio == 0) {
          // 全新用户引导
          return const EmptyState(
            icon: Icons.school_outlined,
            title: '今天还没有复习任务',
            subtitle: '收藏第一件内容，或在收件箱里把待归类的内容成卡，\n它会自动安排明天的首次复习。',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (o.backlog > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, color: scheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '积压 ${o.backlog} 条：超过复习间隔没复习，曲线开始下滑',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('今日任务', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${o.due}',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '张到期卡片',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: o.due == 0
                            ? null
                            : () => _startReview(context, ref),
                        icon: const Icon(Icons.style),
                        label: Text(o.due == 0 ? '今日复习完成' : '开始复习'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    label: '今日已复习',
                    value: '${o.reviewedToday}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.workspace_premium_outlined,
                    label: '掌握率',
                    value: '${(o.masterRatio * 100).toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.show_chart, color: scheme.primary),
                title: const Text('遗忘曲线'),
                subtitle: const Text('个人复习质量 vs 理论曲线（周视图）'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CurveScreen()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startReview(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewSessionScreen()),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}