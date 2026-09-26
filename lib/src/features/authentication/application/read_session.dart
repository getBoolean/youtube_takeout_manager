import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/google_auth_repository.dart';
import 'auth_notifier.dart';
import 'saved_sign_ins.dart';

part 'read_session.g.dart';

/// The channel whose sign-in loads public details like video titles and
/// channel avatars: the viewed channel's, else any saved one, else null.
///
/// These reads don't act on any channel, so a signed-out or deleted channel
/// still gets titles while any sign-in is saved. Deleting only ever uses the
/// viewed channel's own sign-in.
@Riverpod(keepAlive: true)
String? readSessionChannelId(Ref ref) {
  if (ref.watch(authProvider) case final auth?) return auth.channelId;
  final repository = ref.watch(googleAuthRepositoryProvider);
  final saved = ref.watch(savedSignInsProvider).value ?? const {};
  for (final channelId in saved.keys) {
    if (repository.hasSession(channelId)) return channelId;
  }
  return null;
}
