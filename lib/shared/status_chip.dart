import 'package:flutter/material.dart';

import '../providers.dart';

/// 条目状态徽标（待归类/学习中/已掌握/冷置）。
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.leading});

  final String status;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 3)],
          Text(
            statusLabel(status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 语言徽标（日/英/中）。
class LanguageBadge extends StatelessWidget {
  const LanguageBadge({super.key, required this.lang});

  final String? lang;

  @override
  Widget build(BuildContext context) {
    final label = switch (lang) {
      'ja' => '日',
      'en' => '英',
      'zh' => '中',
      _ => '·',
    };
    final color = switch (lang) {
      'ja' => const Color(0xFFC62828),
      'en' => const Color(0xFF1565C0),
      'zh' => const Color(0xFF2E7D32),
      _ => Colors.blueGrey,
    };
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// 卡种图标（词条/语录/灵感/剪藏）。
IconData kindIcon(String kind) {
  return switch (kind) {
    'quote' => Icons.format_quote,
    'idea' => Icons.lightbulb_outline,
    'clip' => Icons.link,
    _ => Icons.translate,
  };
}

String kindLabel(String kind) {
  return switch (kind) {
    'quote' => '语录',
    'idea' => '灵感',
    'clip' => '剪藏',
    _ => '词条',
  };
}