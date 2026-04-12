import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(const ProviderScope(child: _AppWrapper()));
}

class _AppWrapper extends StatelessWidget {
  const _AppWrapper();

  @override
  Widget build(BuildContext context) {
    return App();
  }
}
