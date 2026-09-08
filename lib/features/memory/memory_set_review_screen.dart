import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/analytics_service.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/settings/settings_store.dart';
import '../../domain/srs/sm2.dart';
import '../../providers.dart';
import '../review/flashcard.dart';

/// 记忆集复习会话：闪卡先猜后看 + 三键评级（SM-2）。
/// 与全局复习共用同一定级与落库逻辑，仅队列限定在本记忆集。
class MemorySetReviewSessionScreen extends ConsumerStatefulWidget {
  const MemorySetReviewSessionScreen({super.key, required this.setId});

  final int setId;

  @override
  ConsumerState<MemorySetReviewSessionScreen> createState() =>
      _MemorySetReviewSessionScreenState();
}

class _MemorySetReviewSessionScreenState
    extends ConsumerState<MemorySetReviewSessionScreen> {
  List<CardWithItem> _queue = const [];
  int _index = 0;
  int _answered = 0;
  int _qualitySum = 0;
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
    final cards = await repo.dueCards(memorySetId: widget.setId);

    var allowed = cards.length;
    if (!quota.isPro) {
      final remaining = math.max(0, Quota.maxDailyReviews - quota.reviewsToday);
      if (cards.length > remaining) {
        allowed = remaining;
      }
    }

    setState(() {
      _queue = cards.take(allowed).toList();
      _finished = allowed == 0;
      _loading = false;
    });
  }

  Future<void> _rate(ReviewRating rating) async {
    final card = _queue[_index].card;
    final quality = sm2QualityFor(rating);
    ref.read(analyticsProvider).track(
      AnalyticsEvents.reviewRating,
      props: {'quality': quality, 'memory_set': widget.setId},
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
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_finished || _queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _answered == 0 ? Icons.check_circle_outline : Icons.style,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _answered == 0 ? '本集暂时没有到期的复习卡' : '本集复习完成',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _answered == 0
                      ? '复习会按间隔重复自动排期'
                      : '本次复习 $_answered 张 · 掌握率 '
                          '${_answered == 0 ? 0 : (100 * _qualitySum ~/ (4 * _answered))}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final card = _queue[_index].card;
    return Scaffold(
      appBar: AppBar(
        title: Text('记忆集复习 · ${_index + 1}/${_queue.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LinearProgressIndicator(
                  value: _queue.isEmpty ? 0 : _index / _queue.length,
                  borderRadius: BorderRadius.circular(4)),
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
              const SizedBox(height: 16),
              if (!_flipped)
                const Text(
                  '点卡片显示答案',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _RateButton(
                        label: '忘了',
                        color: Theme.of(context).colorScheme.error,
                        onTap: () => _rate(ReviewRating.forgot),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RateButton(
                        label: '模糊',
                        color: Colors.orange,
                        onTap: () => _rate(ReviewRating.fuzzy),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RateButton(
                        label: '记得',
                        color: const Color(0xFF2F6BFF),
                        onTap: () => _rate(ReviewRating.remembered),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 56),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
