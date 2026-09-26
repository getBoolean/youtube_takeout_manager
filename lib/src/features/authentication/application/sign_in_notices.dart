import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/sign_in_notice.dart';
import '../domain/sign_in_outcome.dart';
import 'lost_sign_in.dart';
import 'saved_sign_ins.dart';
import 'sign_in_service.dart';

part 'sign_in_notices.g.dart';

/// Why channels signed in from the Takeouts dialog didn't end up signed in,
/// by channel ID, until dismissed. Shown through [SignInNotices].
@riverpod
class SignInAttemptNotices extends _$SignInAttemptNotices {
  @override
  Map<String, SignInNotice> build() => const {};

  void note(String channelId, SignInNotice notice) =>
      state = {...state, channelId: notice};

  void dismiss(String channelId) {
    if (!state.containsKey(channelId)) return;
    state = {...state}..remove(channelId);
  }
}

/// Each channel's notice for its row in the Takeouts dialog, by channel ID:
/// why signing it in from there didn't work, or that its saved sign-in
/// stopped working. Also signs channels in from there.
@riverpod
class SignInNotices extends _$SignInNotices {
  @override
  Map<String, SignInNotice> build() {
    final lost = ref.watch(lostSignInProvider)?.profile.channelId;
    final signedIn = ref.watch(savedSignInsProvider).value ?? const {};
    return {
      if (lost != null && !signedIn.containsKey(lost))
        lost: const SignInStoppedWorking(),
      ...ref.watch(signInAttemptNoticesProvider),
    };
  }

  /// Signs [channelId] in, noting it if another channel was chosen, the
  /// account has none, or it failed.
  Future<void> signIn(String channelId) async {
    ref.read(signInAttemptNoticesProvider.notifier).dismiss(channelId);
    SignInNotice? notice;
    try {
      final outcome = await ref
          .read(signInServiceProvider.notifier)
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
      ref.read(signInAttemptNoticesProvider.notifier).note(channelId, notice);
    }
  }

  /// Dismisses [channelId]'s notice.
  void dismiss(String channelId) => switch (state[channelId]) {
    SignInStoppedWorking() => ref.read(lostSignInProvider.notifier).dismiss(),
    _ => ref.read(signInAttemptNoticesProvider.notifier).dismiss(channelId),
  };
}
