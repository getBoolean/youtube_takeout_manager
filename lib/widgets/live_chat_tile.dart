import 'package:flutter/material.dart';

import '../models/live_chat.dart';
import '../utils/date_formatter.dart';

class LiveChatTile extends StatelessWidget {
  final LiveChat liveChat;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LiveChatTile({
    super.key,
    required this.liveChat,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: selectionMode
          ? Checkbox(value: isSelected, onChanged: (_) => onTap())
          : Icon(
              Icons.chat_bubble_outline,
              color: Theme.of(context).colorScheme.secondary,
            ),
      title: Text(
        liveChat.displayText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${formatDateTime(liveChat.createdAt)}'
        '${liveChat.videoId != null ? ' • Stream: ${liveChat.videoId}' : ''}',
      ),
      selected: isSelected,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
