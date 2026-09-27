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
    String? targetKind,
    String? targetId,
    List<PageRouteInfo>? children,
  }) : super(
         ChannelDetailRoute.name,
         args: ChannelDetailRouteArgs(
           key: key,
           channelId: channelId,
           targetKind: targetKind,
           targetId: targetId,
         ),
         rawPathParams: {'channelId': channelId},
         rawQueryParams: {'targetKind': targetKind, 'targetId': targetId},
         initialChildren: children,
       );

  static const String name = 'ChannelDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<ChannelDetailRouteArgs>(
        orElse: () => ChannelDetailRouteArgs(
          channelId: pathParams.getString('channelId'),
          targetKind: queryParams.optString('targetKind'),
          targetId: queryParams.optString('targetId'),
        ),
      );
      return ChannelDetailScreen(
        key: args.key,
        channelId: args.channelId,
        targetKind: args.targetKind,
        targetId: args.targetId,
      );
    },
  );
}

class ChannelDetailRouteArgs {
  const ChannelDetailRouteArgs({
    this.key,
    required this.channelId,
    this.targetKind,
    this.targetId,
  });

  final Key? key;

  final String channelId;

  final String? targetKind;

  final String? targetId;

  @override
  String toString() {
    return 'ChannelDetailRouteArgs{key: $key, channelId: $channelId, targetKind: $targetKind, targetId: $targetId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChannelDetailRouteArgs) return false;
    return key == other.key &&
        channelId == other.channelId &&
        targetKind == other.targetKind &&
        targetId == other.targetId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      channelId.hashCode ^
      targetKind.hashCode ^
      targetId.hashCode;
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
/// [HistoryScreen]
class HistoryRoute extends PageRouteInfo<void> {
  const HistoryRoute({List<PageRouteInfo>? children})
    : super(HistoryRoute.name, initialChildren: children);

  static const String name = 'HistoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HistoryScreen();
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
