const _youtubeDir = 'Takeout/YouTube and YouTube Music';

/// The files of a takeout the app reads: Google's, and its own that hold
/// what those can't.
enum TakeoutFile {
  /// Comments, split across numbered files: `comments.csv`,
  /// `comments(1).csv`, …
  comments('$_youtubeDir/comments/comments.csv'),

  /// Live chats, numbered like [comments].
  liveChats('$_youtubeDir/live chats/live chats.csv'),

  subscriptions('$_youtubeDir/subscriptions/subscriptions.csv'),

  /// The Google account's channels and their titles.
  channels('$_youtubeDir/channels/channel.csv'),

  /// The channels' vanity URL names.
  channelUrlConfigs('$_youtubeDir/channels/channel URL configs.csv'),

  /// The app's own: the export times and skipped row counts.
  meta('_meta/takeout_meta.csv'),

  /// The app's own: how many comments and live chats each channel wrote,
  /// so the takeout switcher needn't load them all.
  channelCounts('_meta/takeout_channels.csv');

  /// Where the app saves it in a takeout's folder.
  final String path;

  const TakeoutFile(this.path);

  /// Whether Google's takeouts have it, so it's taken from picked zips.
  bool get fromGoogle => this != meta && this != channelCounts;

  /// Whether a saved takeout's summary is read from it, rather than its
  /// comments, live chats or subscriptions.
  bool get forSummary => switch (this) {
    channels || channelUrlConfigs || meta || channelCounts => true,
    comments || liveChats || subscriptions => false,
  };

  /// Which file [path] is, in a zip or a saved takeout's folder, or null if
  /// the app doesn't read it. Case doesn't matter.
  static TakeoutFile? classify(String path) {
    final lower = path.toLowerCase();
    if (!lower.endsWith('.csv')) return null;
    for (final file in [meta, channelCounts, channels, channelUrlConfigs]) {
      if (lower.endsWith(file._suffix)) return file;
    }
    for (final file in [comments, liveChats, subscriptions]) {
      if (lower.contains(file._stem)) return file;
    }
    return null;
  }

  /// How its path ends, lowercased, from its folder on.
  String get _suffix {
    final parts = path.toLowerCase().split('/');
    return parts.sublist(parts.length - 2).join('/');
  }

  /// [_suffix] without `.csv`, which numbered files add to.
  String get _stem => _suffix.substring(0, _suffix.length - '.csv'.length);
}
