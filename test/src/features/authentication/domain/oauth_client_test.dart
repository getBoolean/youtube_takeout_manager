import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/domain/oauth_client.dart';

void main() {
  group('a pasted client ID', () {
    test('is fine with spaces around it', () {
      expect(
        clientIdProblem('  123-abc.apps.googleusercontent.com \n'),
        isNull,
      );
    });

    test('is missing when blank', () {
      expect(clientIdProblem('   '), ClientIdProblem.missing);
    });

    test("isn't a client ID when it's the secret or anything else", () {
      expect(clientIdProblem('GOCSPX-abc123'), ClientIdProblem.notAClientId);
      expect(
        clientIdProblem('123-abc.apps.googleusercontent.com.evil'),
        ClientIdProblem.notAClientId,
      );
    });
  });

  group('a client from what was pasted', () {
    test('trims the ID and secret', () {
      final client = OAuthClient.fromInput(
        ' 123-abc.apps.googleusercontent.com ',
        secret: ' GOCSPX-abc\n',
      );

      expect(client.id, '123-abc.apps.googleusercontent.com');
      expect(client.secret, 'GOCSPX-abc');
    });

    test('has no secret when none was given', () {
      expect(
        OAuthClient.fromInput('123-abc.apps.googleusercontent.com').secret,
        isNull,
      );
      expect(
        OAuthClient.fromInput(
          '123-abc.apps.googleusercontent.com',
          secret: '  ',
        ).secret,
        isNull,
      );
    });
  });
}
