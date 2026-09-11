import 'package:flutter/material.dart';

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