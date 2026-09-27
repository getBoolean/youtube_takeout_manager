import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/interaction_result_tile.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/channel_providers.dart';
import '../../application/selection_providers.dart';
import '../../domain/search_result_item.dart';

class CrossChannelResultTile extends ConsumerWidget {
  final SearchResultItem result;
  final String query;

  const CrossChannelResultTile({
    super.key,
    required this.result,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = result.item;
    final channel = ref.watch(channelByIdProvider(result.channelId));
    final status = ref
        .watch(interactionStatusesProvider(item.kind))
        .of(item.id);
    final isSelected = ref.watch(
      deletionSetProvider.select((s) => s.contains(item.id)),
    );
    final selectionMode = selectionModeProvider();
    final selecting = ref.watch(selectionMode);

    void toggleSelection() {
      ref.read(deletionSetProvider.notifier).toggle(item.id);
    }

    void navigateToDetail() {
      // Clear any stale channel search query so the target item
      // isn't filtered out on the detail screen.
      ref.read(channelContentSearchQueryProvider.notifier).update('');
      context.router.push(
        ChannelDetailRoute(
          channelId: result.channelId,
          targetKind: item.kind.name,
          targetId: item.id,
        ),
      );
    }

    return InteractionResultTile(
      item: item,
      channelName: channel?.channelTitle ?? result.channelId,
      channelThumbnailUrl: channel?.thumbnailUrl,
      status: status,
      query: query,
      isSelected: isSelected,
      selectionMode: selecting,
      onTap: selecting
          ? (status.isSelectable ? toggleSelection : () {})
          : navigateToDetail,
      onLongPress: status.isSelectable
          ? () {
              ref.read(selectionMode.notifier).enter();
              toggleSelection();
            }
          : null,
    );
  }
}
