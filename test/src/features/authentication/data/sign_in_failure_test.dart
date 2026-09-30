import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/youtube/v3.dart' show DetailedApiRequestError;
import 'package:googleapis_auth/googleapis_auth.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';

ServerRequestFailedException _refresh(int? status, Object? content) =>
    ServerRequestFailedException(
      'Failed',
      statusCode: status,
      responseContent: content,
    );

void main() {
  test('a refused refresh is a lost sign-in', () {
    expect(isSignInFailure(_refresh(400, {'error': 'invalid_grant'})), isTrue);
    expect(
      isSignInFailure(_refresh(401, {'error': 'unauthorized_client'})),
      isTrue,
    );
  });

  test('a rejected token is a lost sign-in', () {
    expect(isSignInFailure(DetailedApiRequestError(401, 'Invalid')), isTrue);
    expect(isSignInFailure(AccessDeniedException('denied')), isTrue);
  });

  test("Google being down or a captive portal isn't", () {
    expect(isSignInFailure(_refresh(503, 'Service Unavailable')), isFalse);
    expect(isSignInFailure(_refresh(429, {'error': 'rate_limit'})), isFalse);
    // A hotel Wi-Fi login page instead of JSON.
    expect(isSignInFailure(_refresh(null, '<html>Log in</html>')), isFalse);
    expect(
      isSignInFailure(_refresh(400, {'error': 'invalid_request'})),
      isFalse,
    );
  });

  test("being offline isn't", () {
    expect(isSignInFailure(const SocketException('offline')), isFalse);
    expect(isSignInFailure(DetailedApiRequestError(500, 'Backend')), isFalse);
  });

  test('Google refusing the client ID or secret, or a deleted client, is a '
      'rejected client', () {
    expect(
      isClientRejected(_refresh(401, {'error': 'invalid_client'})),
      isTrue,
    );
    expect(
      isClientRejected(_refresh(401, {'error': 'deleted_client'})),
      isTrue,
    );
  });

  test('a lost sign-in or a bad connection is not a rejected client', () {
    expect(
      isClientRejected(_refresh(400, {'error': 'invalid_grant'})),
      isFalse,
    );
    expect(isClientRejected(_refresh(null, '<html>Log in</html>')), isFalse);
    expect(isClientRejected(const SocketException('offline')), isFalse);
  });
}
