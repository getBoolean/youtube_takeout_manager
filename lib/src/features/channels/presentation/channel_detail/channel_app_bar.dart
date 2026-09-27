import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';

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
