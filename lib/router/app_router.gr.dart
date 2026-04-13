// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [ChannelDetailScreen]
class ChannelDetailRoute extends PageRouteInfo<ChannelDetailRouteArgs> {
  ChannelDetailRoute({
    Key? key,
    required String channelId,
    List<PageRouteInfo>? children,
  }) : super(
         ChannelDetailRoute.name,
         args: ChannelDetailRouteArgs(key: key, channelId: channelId),
         rawPathParams: {'channelId': channelId},
         initialChildren: children,
       );

  static const String name = 'ChannelDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ChannelDetailRouteArgs>(
        orElse: () => ChannelDetailRouteArgs(
          channelId: pathParams.getString('channelId'),
        ),
      );
      return ChannelDetailScreen(key: args.key, channelId: args.channelId);
    },
  );
}

class ChannelDetailRouteArgs {
  const ChannelDetailRouteArgs({this.key, required this.channelId});

  final Key? key;

  final String channelId;

  @override
  String toString() {
    return 'ChannelDetailRouteArgs{key: $key, channelId: $channelId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChannelDetailRouteArgs) return false;
    return key == other.key && channelId == other.channelId;
  }

  @override
  int get hashCode => key.hashCode ^ channelId.hashCode;
}

/// generated route for
/// [ChannelListScreen]
class ChannelListRoute extends PageRouteInfo<void> {
  const ChannelListRoute({List<PageRouteInfo>? children})
    : super(ChannelListRoute.name, initialChildren: children);

  static const String name = 'ChannelListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChannelListScreen();
    },
  );
}

/// generated route for
/// [DeletionQueueScreen]
class DeletionQueueRoute extends PageRouteInfo<void> {
  const DeletionQueueRoute({List<PageRouteInfo>? children})
    : super(DeletionQueueRoute.name, initialChildren: children);

  static const String name = 'DeletionQueueRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DeletionQueueScreen();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [ScriptDeletionScreen]
class ScriptDeletionRoute extends PageRouteInfo<void> {
  const ScriptDeletionRoute({List<PageRouteInfo>? children})
    : super(ScriptDeletionRoute.name, initialChildren: children);

  static const String name = 'ScriptDeletionRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ScriptDeletionScreen();
    },
  );
}
