import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/select_all_toggle_button.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';

class ChannelTabLabel extends StatelessWidget {
  final String prefix;
  final int count;

  const ChannelTabLabel({super.key, required this.prefix, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Text('$prefix ('), AnimatedCountText(count), const Text(')')],
    );
  }
}

/// The Comments and Live Chats tabs. Shows the full labels when they fit,
/// then icons with counts, then just icons, so both tabs always stay on
/// screen. A scrolling tab bar would hide one, and can't be scrolled with a
/// mouse.
class ChannelTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final int commentCount;
  final int liveChatCount;

  const ChannelTabBar({
    super.key,
    required this.controller,
    required this.commentCount,
    required this.liveChatCount,
  });

  static const _iconSize = 20.0;
  static const _iconGap = 6.0;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.comment_outlined, 'Comments', commentCount),
      (Icons.chat_bubble_outline, 'Live Chats', liveChatCount),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final style =
            TabBarTheme.of(context).labelStyle ??
            Theme.of(context).textTheme.titleSmall;
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        double textWidth(String text) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textScaler: scaler,
            textDirection: direction,
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        // Each tab gets half the bar, less its label padding.
        final room = constraints.maxWidth / 2 - kTabLabelPadding.horizontal;
        final labelsFit = tabs.every(
          (t) => textWidth('${t.$2} (${t.$3})') <= room,
        );
        final countsFit = tabs.every(
          (t) => _iconSize + _iconGap + textWidth('${t.$3}') <= room,
        );

        return TabBar(
          controller: controller,
          tabs: [
            for (final (icon, label, count) in tabs)
              Tab(
                child: labelsFit
                    ? ChannelTabLabel(prefix: label, count: count)
                    : Tooltip(
                        message: '$label ($count)',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: _iconSize),
                            if (countsFit) ...[
                              const SizedBox(width: _iconGap),
                              AnimatedCountText(count),
                            ],
                          ],
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}

/// The channel's avatar and name, with a globe when there's room, as one
/// button that offers to open the channel on YouTube. Without a channel page
/// (items whose channel is unknown) it's plain text beside a question mark.
class ChannelTitle extends StatelessWidget {
  final String channelName;
  final String? thumbnailUrl;

  /// The channel's page on YouTube, or null when there isn't one.
  final String? channelUrl;

  const ChannelTitle({
    super.key,
    required this.channelName,
    this.thumbnailUrl,
    required this.channelUrl,
  });

  // In a narrow window the name needs the room more.
  static const _avatarMinWidth = 100.0;
  static const _globeMinWidth = 180.0;

  Future<void> _confirmOpen(BuildContext context, String url) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open $channelName on YouTube?'),
        content: const Text('The channel opens in your browser.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (open == true) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = channelUrl;
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 8, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (constraints.maxWidth >= _avatarMinWidth) ...[
                ChannelAvatar(
                  name: channelName,
                  thumbnailUrl: thumbnailUrl,
                  radius: 16,
                  icon: url == null ? Icons.help_outline : null,
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(channelName, overflow: TextOverflow.ellipsis),
              ),
              // Shows the name can be clicked.
              if (url != null && constraints.maxWidth >= _globeMinWidth) ...[
                const SizedBox(width: 8),
                const Icon(Icons.language, size: 18),
              ],
            ],
          ),
        );
        return Row(
          children: [
            Flexible(
              child: url == null
                  ? content
                  : Tooltip(
                      message: 'Open on YouTube…',
                      child: InkWell(
                        onTap: () => _confirmOpen(context, url),
                        borderRadius: BorderRadius.circular(8),
                        child: content,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// "N selected", counting only this channel's comments and live chats.
class ChannelSelectionTitle extends ConsumerWidget {
  final String channelId;

  const ChannelSelectionTitle({super.key, required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(deletionSetProvider);
    final comments = ref.watch(channelCommentsProvider(channelId));
    final liveChats = ref.watch(channelLiveChatsProvider(channelId));
    final count =
        comments.where((c) => selected.contains(c.commentId)).length +
        liveChats.where((c) => selected.contains(c.liveChatId)).length;
    return Text('$count selected');
  }
}

/// Selects or deselects every item in the channel that can still be deleted.
class ChannelSelectAllAction extends ConsumerWidget {
  final String channelId;

  const ChannelSelectAllAction({super.key, required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(channelCommentsProvider(channelId));
    final liveChats = ref.watch(channelLiveChatsProvider(channelId));
    final skipCommentIds = ref.watch(excludedFromDeletionCommentIdsProvider);
    final skipLiveChatIds = ref.watch(excludedFromDeletionLiveChatIdsProvider);
    final selectableIds = {
      ...comments
          .where((c) => !skipCommentIds.contains(c.commentId))
          .map((c) => c.commentId),
      ...liveChats
          .where((c) => !skipLiveChatIds.contains(c.liveChatId))
          .map((c) => c.liveChatId),
    };
    return SelectAllToggleButton(selectableIds: selectableIds);
  }
}
