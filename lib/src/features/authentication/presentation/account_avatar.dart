import 'package:flutter/material.dart';

import '../domain/auth_state.dart';

/// The signed-in account's photo, falling back to its initial, or a person
/// icon when [auth] is null.
class AccountAvatar extends StatelessWidget {
  final AuthState? auth;
  final double radius;

  const AccountAvatar({super.key, required this.auth, required this.radius});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = _fallback(scheme);
    final photoUrl = auth?.photoUrl;

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: photoUrl == null
          ? fallback
          : ClipOval(
              child: Image.network(
                photoUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => Center(child: fallback),
              ),
            ),
    );
  }

  Widget _fallback(ColorScheme scheme) {
    final name = auth?.displayName ?? auth?.email;
    if (name == null || name.isEmpty) {
      return Icon(Icons.person_outline, size: radius);
    }
    return Text(
      name[0].toUpperCase(),
      style: TextStyle(fontSize: radius * 0.9, color: scheme.onPrimaryContainer),
    );
  }
}
