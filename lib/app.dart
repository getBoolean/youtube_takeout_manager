import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'YouTube Takeout Manager',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.config(),
    );
  }
}
