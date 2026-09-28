import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/app_effects.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/lost_sign_in.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  static final _appRouter = AppRouter();
  static final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Background work, such as fetching video titles, runs while the app
    // does.
    ref.listen(appEffectsProvider, (_, _) {});

    // A sign-in can stop working on any screen, e.g. while loading video
    // titles, so this reports it wherever the user is.
    ref.listen(lostSignInProvider, (_, lost) {
      if (lost == null) return;
      final profile = lost.profile;
      final name = profile.channelTitle ?? profile.email ?? profile.channelId;
      _messenger.currentState
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Sign-in for $name stopped working. Sign in again to delete.',
            ),
          ),
        );
    });

    return MaterialApp.router(
      title: 'Takeout Manager for YouTube',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: _messenger,
      routerConfig: _appRouter.config(),
    );
  }
}
