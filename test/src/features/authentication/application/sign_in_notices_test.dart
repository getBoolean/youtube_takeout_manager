import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_notices.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/auth_state.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_notice.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_outcome.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';

const _other = SignInProfile(channelId: 'UCx', channelTitle: 'Someone Else');

class _Auth extends AuthNotifier {
  final Future<SignInOutcome> Function() next;
  final targets = <String?>[];

  _Auth(this.next);

  @override
  AuthState? build() => null;

  @override
  Future<SignInOutcome> signIn({String? targetChannelId}) {
    targets.add(targetChannelId);
    return next();
  }
}

void main() {
  late _Auth auth;

  ProviderContainer container(Future<SignInOutcome> Function() next) {
    auth = _Auth(next);
    final c = ProviderContainer(
      overrides: [authProvider.overrideWith(() => auth)],
    );
    addTearDown(c.dispose);
    c.listen(signInNoticesProvider, (_, _) {});
    return c;
  }

  test('signs in for the channel, with no notice when it was chosen', () async {
    final c = container(
      () async => const SignedIn(SignInProfile(channelId: 'UCalt')),
    );

    await c.read(signInNoticesProvider.notifier).signIn('UCalt');

    expect(auth.targets, ['UCalt']);
    expect(c.read(signInNoticesProvider), isEmpty);
  });

  test(
    'notes another channel was chosen, on the channel signed in for',
    () async {
      final c = container(
        () async =>
            const SignedInOtherChannel(_other, targetChannelId: 'UCalt'),
      );

      await c.read(signInNoticesProvider.notifier).signIn('UCalt');

      final notice = c.read(signInNoticesProvider)['UCalt'];
      expect(notice, isA<OtherChannelChosen>());
      expect((notice! as OtherChannelChosen).chosen, _other);
    },
  );

  test('notes an account without a YouTube channel', () async {
    final c = container(() async => const SignInNoChannel());

    await c.read(signInNoticesProvider.notifier).signIn('UCalt');

    expect(c.read(signInNoticesProvider)['UCalt'], isA<NoYouTubeChannel>());
  });

  test('notes a sign-in that failed', () async {
    final c = container(() async => throw Exception('offline'));

    await c.read(signInNoticesProvider.notifier).signIn('UCalt');

    final notice = c.read(signInNoticesProvider)['UCalt'];
    expect(notice, isA<SignInFailed>());
    expect((notice! as SignInFailed).message, contains('offline'));
  });

  test('signing in again clears the last notice first', () async {
    var outcome = const SignInNoChannel() as SignInOutcome;
    final c = container(() async => outcome);
    final notices = c.read(signInNoticesProvider.notifier);
    await notices.signIn('UCalt');

    outcome = const SignInCancelled();
    await notices.signIn('UCalt');

    expect(c.read(signInNoticesProvider), isEmpty);
  });

  test("dismissing removes only that channel's notice", () async {
    final c = container(() async => const SignInNoChannel());
    final notices = c.read(signInNoticesProvider.notifier);
    await notices.signIn('UCa');
    await notices.signIn('UCb');

    notices.dismiss('UCa');

    expect(c.read(signInNoticesProvider).keys, ['UCb']);
  });
}
