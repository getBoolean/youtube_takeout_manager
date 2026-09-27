import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/youtube_links.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/interaction_result_tile.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';

/// Shows [items], newest first, in an [ImportItemsDialog].
Future<void> showImportItemsDialog(
  BuildContext context, {
  required String title,
  required List<Interaction> items,
}) => showDialog<void>(
  context: context,
  builder: (_) => ImportItemsDialog(title: title, items: items),
);

/// The comments or live chats an import adds or finds gone, listed as
/// search results are, each opening on YouTube to check it.
class ImportItemsDialog extends StatelessWidget {
  final String title;

  /// Newest first.
  final List<Interaction> items;

  /// Opens an item on YouTube; launches it externally when null.
  final void Function(Uri url)? onOpen;

  const ImportItemsDialog({
    super.key,
    required this.title,
    required this.items,
    this.onOpen,
  });

  void _open(Uri url) =>
      (onOpen ?? (url) => launchUrl(url, mode: LaunchMode.externalApplication))
          .call(url);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      title: Text(title),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: SizedBox(
        width: 560,
        // Fills the dialog's height, building rows as they scroll into view.
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) => _ItemTile(
            key: ValueKey(('import-item', items[i].id)),
            item: items[i],
            onOpen: _open,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

/// [item] with the channel its video is on, as far as it's known.
class _ItemTile extends ConsumerWidget {
  final Interaction item;
  final void Function(Uri url) onOpen;

  const _ItemTile({super.key, required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(
      videoMetadataProvider.select((v) => v.value?[item.videoId]),
    );
    final channel = video == null
        ? null
        : ref.watch(channelByIdProvider(video.channelId));
    final url = youtubeUrlOf(item);
    return InteractionResultTile(
      item: item,
      channelName:
          channel?.channelTitle ?? video?.channelTitle ?? 'Unknown channel',
      channelThumbnailUrl: channel?.thumbnailUrl,
      // Not dimmed as deleted: the review already says what happens to them.
      status: InteractionStatus.active,
      trailing: url == null
          ? const SizedBox.shrink()
          : const Icon(Icons.open_in_new),
      onTap: url == null ? () {} : () => onOpen(url),
    );
  }
}
