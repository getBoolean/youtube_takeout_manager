import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/features/channels/data/youtube_channel_repository.dart';

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('fetchMyChannelId', () {
    test(
      "asks for the signed-in account's channel and returns its ID",
      () async {
        late Uri requested;
        final client = MockClient((request) async {
          requested = request.url;
          return _json({
            'items': [
              {'id': 'UCNvbaa8lnkDE7-qc3zcePLA'},
            ],
          });
        });

        final id = await YoutubeChannelRepository().fetchMyChannelId(client);

        expect(id, 'UCNvbaa8lnkDE7-qc3zcePLA');
        expect(requested.path, endsWith('/youtube/v3/channels'));
        expect(requested.queryParameters['mine'], 'true');
      },
    );

    test('returns null when the account has no channel', () async {
      final client = MockClient((_) async => _json({'items': <Object>[]}));

      expect(await YoutubeChannelRepository().fetchMyChannelId(client), isNull);
    });

    test('lets request failures through', () async {
      final client = MockClient((_) async => http.Response('', 500));

      expect(
        YoutubeChannelRepository().fetchMyChannelId(client),
        throwsA(anything),
      );
    });
  });
}
