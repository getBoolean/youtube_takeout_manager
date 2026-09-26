import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';

/// Why items are under the unknown channel: signed out, video details can't
/// be loaded; signed in, what's left is on posts or videos that are gone.
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
    final signedIn = ref.watch(isAuthenticatedProvider);
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
