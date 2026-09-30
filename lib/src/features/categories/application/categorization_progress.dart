import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categorization_progress.g.dart';

/// How far along categorizing channels is.
@Riverpod(keepAlive: true)
class CategorizationProgress extends _$CategorizationProgress {
  @override
  ({bool running, int done, int total}) build() =>
      (running: false, done: 0, total: 0);

  void start(int total) => state = (running: true, done: 0, total: total);

  void update(int done) =>
      state = (running: true, done: done, total: state.total);

  void complete() =>
      state = (running: false, done: state.total, total: state.total);
}
