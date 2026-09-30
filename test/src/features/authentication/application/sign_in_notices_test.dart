import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/lost_sign_in.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_notices.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_notice.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_outcome.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';

const _other = SignInProfile(channelId: 'UCx', channelTitle: 'Someone Else');
const _lost = SignInProfile(channelId: 'UCa');

class _Auth extends SignInService {
  final Future<SignInOutcome> Function() next;
  final targets = <String?>[];

  _Auth(this.next);

  @override
  void build() {}

  @override
  Future<SignInOutcome> signIn({String? targetChannelId}) {
    targets.add(targetChannelId);
    return next();
  }
}

class _SignIns extends SavedSignIns {
  final Map<String, SignInProfile> profiles;

  _SignIns(this.profiles);

  @override
  Future<Map<String, SignInProfile>> build() async => profiles;
}

void main() {
  late _Auth auth;

  ProviderContainer container(
    Future<SignInOutcome> Function() next, {
    Map<String, SignInProfile> signIns = const {},
  }) {
    auth = _Auth(next);
    final c = ProviderContainer(
      overrides: [
        signInServiceProvider.overrideWith(() => auth),
        savedSignInsProvider.overrideWith(() => _SignIns(signIns)),
      ],
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

  test("notes a Google Cloud client Google doesn't accept", () async {
    final c = container(
      () async => throw ServerRequestFailedException(
        'Failed to obtain access credentials.',
        statusCode: 401,
        responseContent: {'error': 'invalid_client'},
      ),
    );

    await c.read(signInNoticesProvider.notifier).signIn('UCalt');

    expect(c.read(signInNoticesProvider)['UCalt'], isA<ClientRejected>());
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

  test('a sign-in that stopped working shows on its channel until '
      'dismissed', () async {
    final c = container(() async => const SignInNoChannel());
    await c.read(signInNoticesProvider.notifier).signIn('UCb');

    c.read(lostSignInProvider.notifier).report(_lost);

    expect(c.read(signInNoticesProvider)['UCa'], isA<SignInStoppedWorking>());

    c.read(signInNoticesProvider.notifier).dismiss('UCa');

    expect(c.read(lostSignInProvider), isNull);
    expect(c.read(signInNoticesProvider).keys, ['UCb']);
  });

  test('a lost sign-in shows nothing once the channel is signed in '
      'again', () async {
    final c = container(
      () async => const SignInCancelled(),
      signIns: const {'UCa': _lost},
    );
    await c.read(savedSignInsProvider.future);

    c.read(lostSignInProvider.notifier).report(_lost);

    expect(c.read(signInNoticesProvider), isEmpty);
  });
}
