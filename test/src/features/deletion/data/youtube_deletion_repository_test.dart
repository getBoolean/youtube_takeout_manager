import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/features/deletion/data/youtube_deletion_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_outcome.dart';

/// YouTube answering with [status] and an API error saying [message], for
/// [reason].
http.Client _answering(int status, {String? message, String? reason}) =>
    MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {
            'code': status,
            'message': ?message,
            'errors': [
              {'reason': ?reason, 'message': ?message},
            ],
          },
        }),
        status,
        headers: {'content-type': 'application/json; charset=UTF-8'},
      ),
    );

void main() {
  final repository = YoutubeDeletionRepository();

  test('deletes the item asked for', () async {
    http.Request? sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response('', 204);
    });

    final outcome = await repository.deleteItem(client, 'Ugx123');

    expect(outcome, isA<Deleted>());
    expect(sent!.method, 'DELETE');
    expect(sent!.url.queryParameters['id'], 'Ugx123');
  });

  group('out of quota', () {
    test('says so when YouTube gives quota as the reason', () async {
      for (final reason in ['quotaExceeded', 'dailyLimitExceeded']) {
        final outcome = await repository.deleteItem(
          _answering(403, message: 'Request denied.', reason: reason),
          'c1',
        );

        expect(outcome, isA<QuotaExceeded>(), reason: reason);
        expect((outcome as QuotaExceeded).message, isNotEmpty);
      }
    });

    test('says so when YouTube mentions quota in the message', () async {
      final outcome = await repository.deleteItem(
        _answering(403, message: 'You have exceeded your quota.'),
        'c1',
      );

      expect(outcome, isA<QuotaExceeded>());
    });
  });

  test('a refusal that isn’t about quota fails the item, saying why', () async {
    final outcome = await repository.deleteItem(
      _answering(
        403,
        message: 'The comment could not be deleted.',
        reason: 'forbidden',
      ),
      'c1',
    );

    expect(outcome, isA<Failed>());
    expect(
      (outcome as Failed).message,
      contains('The comment could not be deleted.'),
    );
  });

  test('a comment that isn’t found fails the item', () async {
    final outcome = await repository.deleteItem(
      _answering(404, message: 'Comment not found.', reason: 'notFound'),
      'c1',
    );

    expect(outcome, isA<Failed>());
  });

  group('a sign-in that stops working', () {
    test('as YouTube refusing the credentials', () async {
      final outcome = await repository.deleteItem(
        _answering(401, message: 'Invalid Credentials', reason: 'authError'),
        'c1',
      );

      expect(outcome, isA<SignInFailed>());
    });

    test('as access being revoked before the request is sent', () async {
      final client = MockClient(
        (_) => Future.error(AccessDeniedException('revoked')),
      );

      expect(await repository.deleteItem(client, 'c1'), isA<SignInFailed>());
    });
  });

  test('any other error fails the item, saying why', () async {
    final client = MockClient(
      (_) => Future.error(http.ClientException('network is down')),
    );

    final outcome = await repository.deleteItem(client, 'c1');

    expect(outcome, isA<Failed>());
    expect((outcome as Failed).message, contains('network is down'));
  });
}
