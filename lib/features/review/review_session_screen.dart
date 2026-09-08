import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/analytics_service.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/settings/settings_store.dart';
import '../../domain/srs/sm2.dart';
import '../../providers.dart';
import '../settings/paywall_sheet.dart';
import 'curve_screen.dart';
import 'flashcard.dart';

/// 复习会话：闪卡先猜后看 + 三键评级（忘了/模糊/记得）。
///
/// - 评级即时落库（SM-2 更新 + review_log 追加），中途退出自动保存进度；
/// - 免费额度：非 Pro 每日 30 次评级，超限引导订阅（不打断复习中，结束时提示）。
class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  List<CardWithItem> _queue = const [];
  int _index = 0;
  int _answered = 0;
  int _qualitySum = 0;
  int _limitHit = 0; // 因免费额度被截断的卡片数
  bool _loading = true;
  bool _finished = false;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(reviewRepositoryProvider);
    final quota = await ref.read(quotaProvider.future);
    final cards = await repo.dueCards();

    var allowed = cards.length;
    var truncated = 0;
    if (!quota.isPro) {
      final remaining = math.max(0, Quota.maxDailyReviews - quota.reviewsToday);
      if (cards.length > remaining) {
        truncated = cards.length - remaining;
        allowed = remaining;
      }
    }

    setState(() {
      _queue = cards.take(allowed).toList();
      _limitHit = truncated;
      _finished = allowed == 0;
      _loading = false;
    });
  }

  Future<void> _rate(ReviewRating rating) async {
    final card = _queue[_index].card;
    final quality = sm2QualityFor(rating);
    ref.read(analyticsProvider).track(
      AnalyticsEvents.reviewRating,
      props: {'quality': quality},
    );
    await ref.read(reviewRepositoryProvider).reviewCard(
          cardId: card.id,
          rating: rating,
        );
    setState(() {
      _answered += 1;
      _qualitySum += quality;
      if (_index + 1 >= _queue.length) {
        _finished = true;
      } else {
        _index += 1;
        _flipped = false;
      }
    });
    if (_finished) {
      ref.read(analyticsProvider).track(
        AnalyticsEvents.reviewSessionCompleted,
        props: {'count': _answered},
      );
      ref.invalidate(dueCardsProvider);
      ref.invalidate(reviewOverviewProvider);
      ref.invalidate(quotaProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_finished) {
      return _buildCompletion();
    }

    final card = _queue[_index].card;
    final progress = _queue.isEmpty ? 0.0 : _index / _queue.length;

    return Scaffold(
      appBar: AppBar(title: Text('复习 · ${_index + 1}/${_queue.length}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LinearProgressIndicator(
                  value: progress, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 16),
              Expanded(
                child: Flashcard(
                  key: ValueKey(card.id),
                  front: CardFace(
                    hint: '点按翻面，先回忆再看答案',
                    child: Text(
                      card.prompt,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  back: CardFace(
                    child: SelectableText(
                      card.answer.isEmpty ? '（无答案）' : card.answer,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  onFlip: () => setState(() => _flipped = !_flipped),
                ),
              ),
              const SizedBox(height: 20),
              if (_flipped)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RatingButton(
                      label: '忘了',
                      icon: Icons.sentiment_very_dissatisfied,
                      color: Colors.redAccent,
                      onPressed: () => _rate(ReviewRating.forgot),
                    ),
                    _RatingButton(
                      label: '模糊',
                      icon: Icons.sentiment_neutral,
                      color: Colors.amber.shade700,
                      onPressed: () => _rate(ReviewRating.fuzzy),
                    ),
                    _RatingButton(
                      label: '记得',
                      icon: Icons.sentiment_satisfied_alt,
                      color: Colors.green.shade600,
                      onPressed: () => _rate(ReviewRating.remembered),
                    ),
                  ],
                )
              else
                Text(
                  '先回忆，再点卡片看答案',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletion() {
    final avgQuality = _answered == 0 ? 0.0 : _qualitySum / _answered;
    final summary = _answered == 0
        ? '今天没有到期的卡片'
        : '完成 $_answered 张 · 平均评级 ${avgQuality.toStringAsFixed(1)}/5';

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.task_alt, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                _answered == 0 ? '暂无任务' : '今日复习完成',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(summary, textAlign: TextAlign.center),
              if (_limitHit > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '还有 $_limitHit 张因免费额度未复习',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.tertiary),
                ),
                TextButton(
                  onPressed: () =>
                      PaywallSheet.show(context: context, reason: '解锁每日无限复习'),
                  child: const Text('了解付费方案'),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CurveScreen()),
                  );
                },
                icon: const Icon(Icons.show_chart),
                label: const Text('查看遗忘曲线'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // 整列可点：按钮 + 标签一起响应评级
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.large(
            heroTag: label,
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            onPressed: onPressed,
            child: Icon(icon),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
