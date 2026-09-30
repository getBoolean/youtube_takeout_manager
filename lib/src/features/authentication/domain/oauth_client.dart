import 'package:dart_mappable/dart_mappable.dart';

part 'oauth_client.mapper.dart';

/// A Google Cloud OAuth client that signs in and pays the YouTube API quota
/// of its project. On web it's a "Web application" client, which needs no
/// secret; elsewhere a "Desktop app" client with its secret.
@MappableClass()
class OAuthClient with OAuthClientMappable {
  final String id;
  final String? secret;

  const OAuthClient({required this.id, this.secret});

  /// The client from a pasted [id] and [secret], trimmed. A blank secret is
  /// none.
  factory OAuthClient.fromInput(String id, {String? secret}) {
    final trimmed = secret?.trim();
    return OAuthClient(
      id: id.trim(),
      secret: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  }
}

enum ClientIdProblem { missing, notAClientId }

/// What's wrong with a pasted client ID, or null if nothing is.
ClientIdProblem? clientIdProblem(String input) {
  final id = input.trim();
  if (id.isEmpty) return ClientIdProblem.missing;
  if (!id.endsWith('.apps.googleusercontent.com')) {
    return ClientIdProblem.notAClientId;
  }
  return null;
}
