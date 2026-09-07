import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'features/home/home_shell.dart';

/// 拾忆 App 根组件。
class ShiyiApp extends StatelessWidget {
  const ShiyiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '拾忆',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
        Locale('ja'),
      ],
      locale: const Locale('zh'),
      home: const HomeShell(),
    );
  }
}