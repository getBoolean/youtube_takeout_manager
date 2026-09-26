import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/sign_in_profile.dart';

part 'credential_store.g.dart';

typedef SavedSignIn = ({SignInProfile profile, AccessCredentials credentials});

@Riverpod(keepAlive: true)
CredentialStore credentialStore(Ref ref) =>
    CredentialStore(const FlutterSecureStorage());

/// Saves each YouTube channel's Google sign-in in secure storage, one key per
/// channel.
///
/// Runs one operation at a time: on Windows every write rewrites a single
/// encrypted file, so overlapping writes could lose each other.
class CredentialStore {
  /// Where the one sign-in was saved before there was one per channel.
  static const legacyKey = 'google_auth_credentials';
  static const _keyPrefix = 'google_auth_credentials:';

  final FlutterSecureStorage _storage;
  Future<void> _last = Future.value();

  CredentialStore(this._storage);

  /// Every channel's saved sign-in. Ones that can't be read are skipped.
  Future<List<SavedSignIn>> loadAll() => _run(() async {
    final all = await _storage.readAll();
    return [
      for (final MapEntry(:key, :value) in all.entries)
        if (key.startsWith(_keyPrefix)) ?_decodeSignIn(value),
    ];
  });

  Future<void> save(SignInProfile profile, AccessCredentials credentials) =>
      _run(
        () => _storage.write(
          key: _key(profile.channelId),
          value: jsonEncode({
            'profile': profile.toMap(),
            'credentials': _encodeCredentials(credentials),
          }),
        ),
      );

  /// Replaces [channelId]'s token after a refresh. Does nothing if its
  /// sign-in was removed meanwhile, so a late refresh can't bring it back.
  Future<void> updateCredentials(
    String channelId,
    AccessCredentials credentials,
  ) => _run(() async {
    final raw = await _storage.read(key: _key(channelId));
    final signIn = raw != null ? _decodeSignIn(raw) : null;
    if (signIn == null) return;
    await _storage.write(
      key: _key(channelId),
      value: jsonEncode({
        'profile': signIn.profile.toMap(),
        'credentials': _encodeCredentials(credentials),
      }),
    );
  });

  Future<void> delete(String channelId) =>
      _run(() => _storage.delete(key: _key(channelId)));

  /// The sign-in saved before there was one per channel, if it's readable.
  Future<AccessCredentials?> loadLegacy() => _run(() async {
    final raw = await _storage.read(key: legacyKey);
    if (raw == null) return null;
    try {
      return _decodeCredentials(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  });

  Future<void> deleteLegacy() => _run(() => _storage.delete(key: legacyKey));

  Future<T> _run<T>(Future<T> Function() operation) {
    final result = _last.then((_) => operation());
    _last = result.then((_) {}, onError: (_) {});
    return result;
  }

  static String _key(String channelId) => '$_keyPrefix$channelId';

  static SavedSignIn? _decodeSignIn(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        profile: SignInProfileMapper.fromMap(
          map['profile'] as Map<String, dynamic>,
        ),
        credentials: _decodeCredentials(
          map['credentials'] as Map<String, dynamic>,
        ),
      );
    } on Object {
      return null;
    }
  }

  static Map<String, Object?> _encodeCredentials(AccessCredentials c) => {
    'accessToken': {
      'type': c.accessToken.type,
      'data': c.accessToken.data,
      'expiry': c.accessToken.expiry.toIso8601String(),
    },
    'refreshToken': c.refreshToken,
    'scopes': c.scopes,
  };

  static AccessCredentials _decodeCredentials(Map<String, dynamic> map) {
    final token = map['accessToken'] as Map<String, dynamic>;
    return AccessCredentials(
      AccessToken(
        token['type'] as String,
        token['data'] as String,
        DateTime.parse(token['expiry'] as String),
      ),
      map['refreshToken'] as String?,
      (map['scopes'] as List).cast<String>(),
    );
  }
}
