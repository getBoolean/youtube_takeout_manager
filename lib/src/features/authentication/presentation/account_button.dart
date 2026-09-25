import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_notifier.dart';
import 'account_avatar.dart';
import 'account_dialog.dart';

/// App bar button that opens the account dialog: the signed-in avatar, or an
/// outline account icon when signed out.
class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return IconButton(
      tooltip: 'Account',
      onPressed: () => showAccountDialog(context),
      icon: auth == null
          ? const Icon(Icons.account_circle_outlined)
          : AccountAvatar(auth: auth, radius: 16),
    );
  }
}
