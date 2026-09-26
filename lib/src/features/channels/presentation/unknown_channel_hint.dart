import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';

/// Why items are under the unknown channel: with no sign-in, video details
/// can't be loaded; with one, what's left is on posts or videos that are
/// gone.
class UnknownChannelHint extends ConsumerWidget {
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;

  const UnknownChannelHint({
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Any sign-in loads video details, not just the viewed channel's.
    final signedIn = ref.watch(readSessionChannelIdProvider) != null;
    return Text(
      signedIn
          ? 'On posts, or videos that are private or gone'
          : 'Sign in to sort these by channel',
      style: style,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      textAlign: textAlign,
    );
  }
}
