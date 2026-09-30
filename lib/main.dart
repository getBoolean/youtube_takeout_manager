import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // appEffects restores saved sign-ins (via legacySignInMigration) once App
  // starts listening to it.
  runApp(const ProviderScope(child: App()));
}
