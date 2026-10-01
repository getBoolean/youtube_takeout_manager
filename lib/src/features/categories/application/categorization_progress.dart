import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categorization_progress.g.dart';

/// How far along categorizing channels is, and whether it's doing some
/// again because the prompts changed.
@Riverpod(keepAlive: true)
class CategorizationProgress extends _$CategorizationProgress {
  @override
  ({bool running, int done, int total, bool redo}) build() =>
      (running: false, done: 0, total: 0, redo: false);

  void start(int total, {bool redo = false}) =>
      state = (running: true, done: 0, total: total, redo: redo);

  void update(int done) =>
      state = (running: true, done: done, total: state.total, redo: state.redo);

  void complete() => state = (
    running: false,
    done: state.total,
    total: state.total,
    redo: state.redo,
  );
}
