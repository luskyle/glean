import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shiyi/app.dart';
import 'package:shiyi/data/database/database.dart';
import 'package:shiyi/data/settings/settings_store.dart';
import 'package:shiyi/providers.dart';

/// 测试环境公共搭建：内存库 + 关闭剪贴板监听的设置。
Future<ProviderContainer> buildTestContainer() async {
  SharedPreferences.setMockInitialValues({
    // 关闭剪贴板监听，避免测试中出现轮询 Timer
    'settings.clipboard_watch': false,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(AppDatabase.forTesting()),
      sharedPrefsProvider.overrideWithValue(prefs),
      settingsProvider.overrideWithValue(SettingsStore(prefs)),
    ],
  );
  // 触发一次数据库初始化（完成系统库种子）
  container.read(databaseProvider);
  return container;
}

void main() {
  testWidgets('三 Tab 导航与空态', (tester) async {
    final container = await buildTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ShiyiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 默认落点 = 复习页（设计原则 2）
    expect(find.text('今日复习'), findsOneWidget);
    expect(find.text('今天还没有复习任务'), findsOneWidget);

    // 切到收件箱
    await tester.tap(find.text('收件箱'));
    await tester.pumpAndSettle();
    expect(find.text('收件箱还空着'), findsOneWidget);

    // 切到记忆库
    await tester.tap(find.text('记忆库'));
    await tester.pumpAndSettle();
    expect(find.text('记忆库还空着'), findsOneWidget);
  });

  testWidgets('空库时复习页显示引导，且不显示开始按钮', (tester) async {
    final container = await buildTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ShiyiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '开始复习'), findsNothing);
    expect(find.text('今天还没有复习任务'), findsOneWidget);
  });

  testWidgets('宽屏显示 Cubox 式侧栏布局', (tester) async {
    final container = await buildTestContainer();
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ShiyiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 侧栏元素：Logo / 新建收藏 / 分组
    expect(find.text('新建收藏'), findsOneWidget);
    expect(find.text('今日复习'), findsOneWidget);
    expect(find.text('分组'), findsOneWidget);

    // 窄屏三 Tab 不再渲染
    expect(find.byType(NavigationBar), findsNothing);
    // 仍显示复习页默认落点内容
    expect(find.text('今天还没有复习任务'), findsOneWidget);

    // 侧栏切到记忆库
    await tester.tap(find.text('记忆库'));
    await tester.pumpAndSettle();
    expect(find.text('记忆库还空着'), findsOneWidget);
  });
}