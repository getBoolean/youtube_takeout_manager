final _channelId = RegExp(r'^UC[A-Za-z0-9_-]{1,64}$');

/// Whether [id] looks like a YouTube channel ID: `UC` then letters, digits,
/// `-` and `_`. Takeouts are stored under their channel ID, so this keeps it
/// safe as a folder name (no `..`, no reserved names like `CON`) or key
/// prefix.
bool isChannelId(String id) => _channelId.hasMatch(id);
