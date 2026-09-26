import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/sign_in_notice.dart';
import '../domain/sign_in_outcome.dart';
import 'auth_notifier.dart';

part 'sign_in_notices.g.dart';

/// Signs channels in from the account dialog, keeping why one didn't end up
/// signed in, by channel ID, to show on its row until dismissed.
@riverpod
class SignInNotices extends _$SignInNotices {
  @override
  Map<String, SignInNotice> build() => const {};

  /// Signs [channelId] in, noting it if another channel was chosen, the
  /// account has none, or it failed.
  Future<void> signIn(String channelId) async {
    dismiss(channelId);
    SignInNotice? notice;
    try {
      final outcome = await ref
          .read(authProvider.notifier)
          .signIn(targetChannelId: channelId);
      notice = switch (outcome) {
        SignedInOtherChannel(:final profile) => OtherChannelChosen(profile),
        SignInNoChannel() => const NoYouTubeChannel(),
        SignedIn() || SignInCancelled() => null,
      };
    } catch (e) {
      notice = SignInFailed('$e');
    }
    if (notice != null && ref.mounted) {
      state = {...state, channelId: notice};
    }
  }

  void dismiss(String channelId) {
    if (!state.containsKey(channelId)) return;
    state = {...state}..remove(channelId);
  }
}
