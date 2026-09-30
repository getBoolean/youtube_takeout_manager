import '../domain/oauth_client.dart';
import 'google_auth_repository.dart';

class GoogleAuthRepositoryImpl implements GoogleAuthRepository {
  GoogleAuthRepositoryImpl(OAuthClient? client) {
    throw UnsupportedError(
      'No platform implementation for GoogleAuthRepository',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
