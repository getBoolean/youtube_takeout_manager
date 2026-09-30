import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_shown.g.dart';

/// Whether the history screen was opened this session. History loads when
/// first looked at; background work on it waits for this rather than
/// loading it at startup.
@Riverpod(keepAlive: true)
class HistoryShown extends _$HistoryShown {
  @override
  bool build() => false;

  void markShown() {
    if (!state) state = true;
  }
}
