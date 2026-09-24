import 'package:dart_mappable/dart_mappable.dart';

part 'auth_state.mapper.dart';

@MappableClass()
class AuthState with AuthStateMappable {
  final String accessToken;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const AuthState({
    required this.accessToken,
    this.displayName,
    this.email,
    this.photoUrl,
  });
}
