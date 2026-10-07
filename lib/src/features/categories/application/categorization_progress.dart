import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categorization_progress.g.dart';

/// How far along a categorizing run is: whether one is [running], whether
/// it asks AI ([ai], one the user started) or only YouTube, whether it's
/// doing some again because the prompts changed ([redo]), whether it was
/// told to stop and is waiting for answers already asked for ([stopping]),
/// and whether the last AI run ended before every channel ([interrupted]).
typedef RunProgress = ({
  bool running,
  bool ai,
  int done,
  int total,
  bool redo,
  bool stopping,
  bool interrupted,
});

/// How far along categorizing channels is.
@Riverpod(keepAlive: true)
class CategorizationProgress extends _$CategorizationProgress {
  @override
  RunProgress build() => (
    running: false,
    ai: false,
    done: 0,
    total: 0,
    redo: false,
    stopping: false,
    interrupted: false,
  );

  void start(int total, {bool redo = false, bool ai = false}) => state = (
    running: true,
    ai: ai,
    done: 0,
    total: total,
    redo: redo,
    stopping: false,
    interrupted: false,
  );

  void update(int done) => state = (
    running: true,
    ai: state.ai,
    done: done,
    total: state.total,
    redo: state.redo,
    stopping: state.stopping,
    interrupted: false,
  );

  /// The user stopped the run: nothing more is asked, and the answers
  /// already asked for are still coming.
  void stopping() {
    if (!state.running) return;
    state = (
      running: true,
      ai: state.ai,
      done: state.done,
      total: state.total,
      redo: state.redo,
      stopping: true,
      interrupted: false,
    );
  }

  /// The run ended: through every channel, or, [interrupted], an AI run
  /// stopped before it was.
  void complete({bool interrupted = false}) => state = (
    running: false,
    ai: state.ai,
    done: interrupted ? state.done : state.total,
    total: state.total,
    redo: state.redo,
    stopping: false,
    interrupted: interrupted && state.ai,
  );

  /// An AI run that ended before it started on any channel, such as one
  /// stopped while its videos' descriptions were coming.
  void interrupt() => state = (
    running: false,
    ai: true,
    done: state.done,
    total: state.total,
    redo: state.redo,
    stopping: false,
    interrupted: true,
  );
}

/// The tokens Claude's answers used in the user's run, the one under way or
/// the last: what it cost.
@Riverpod(keepAlive: true)
class ClaudeUsage extends _$ClaudeUsage {
  @override
  ({int input, int output}) build() => (input: 0, output: 0);

  /// A new run, from nothing.
  void reset() => state = (input: 0, output: 0);

  void add(int input, int output) =>
      state = (input: state.input + input, output: state.output + output);
}
