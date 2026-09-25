import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFFFF0000); // YouTube red

  // Keeps the trailing account avatar off the window edge.
  static const _appBarTheme = AppBarTheme(
    actionsPadding: EdgeInsetsDirectional.only(end: 8),
  );

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    appBarTheme: _appBarTheme,
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: _appBarTheme,
  );
}
