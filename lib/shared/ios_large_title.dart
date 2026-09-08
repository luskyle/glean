import 'package:flutter/material.dart';

/// iOS Large Title（宽屏内容区标题，HIG 大标题层级）。
/// 窄屏下由 AppBar/Tab 承担标题职责，不重复渲染。
class IOSLargeTitle extends StatelessWidget {
  const IOSLargeTitle(this.title, {super.key, this.padding});

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: padding ??
              const EdgeInsets.fromLTRB(4, 20, 4, 12),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }
}