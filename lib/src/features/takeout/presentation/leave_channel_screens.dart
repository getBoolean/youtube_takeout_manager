import 'package:auto_route/auto_route.dart';

import 'package:youtube_takeout_manager/src/routing/app_router.dart';

/// Leaves screens tied to the previous channel, after another channel or
/// takeout is shown: a channel's page or its deletion script may not be in
/// it, so those go back to the channel list.
void leaveChannelScreens(StackRouter? router) {
  if (router == null) return;
  if (router.isRouteActive(ChannelDetailRoute.name) ||
      router.isRouteActive(ScriptDeletionRoute.name)) {
    router.replaceAll([const ChannelListRoute()]);
  }
}
