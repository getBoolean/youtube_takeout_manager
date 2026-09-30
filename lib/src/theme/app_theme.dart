import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';

class AppTheme {
  static const _seedColor = Color(0xFFFF0000); // YouTube red

  // Keeps the trailing account avatar off the window edge.
  static const _appBarTheme = AppBarTheme(
    actionsPadding: EdgeInsetsDirectional.only(end: 8),
  );

  static const _modalTheme = WoltModalSheetThemeData(
    modalTypeBuilder: adaptiveModalType,
  );

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    appBarTheme: _appBarTheme,
    extensions: const [_modalTheme],
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: _appBarTheme,
    extensions: const [_modalTheme],
  );
}
