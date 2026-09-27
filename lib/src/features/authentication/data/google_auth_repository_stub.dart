import 'google_auth_repository.dart';

class GoogleAuthRepositoryImpl implements GoogleAuthRepository {
  GoogleAuthRepositoryImpl() {
    throw UnsupportedError(
      'No platform implementation for GoogleAuthRepository',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
