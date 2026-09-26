import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/channel_detail_screen.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/channel_list_screen.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/script_deletion_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: ChannelListRoute.page, path: '/channels', initial: true),
    AutoRoute(page: ChannelDetailRoute.page, path: '/channels/:channelId'),
    // The queue now lives beside the channel lists.
    RedirectRoute(path: '/deletion-queue', redirectTo: '/channels'),
    AutoRoute(page: ScriptDeletionRoute.page, path: '/script-deletion'),
  ];
}
