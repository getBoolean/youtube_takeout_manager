import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/run_estimate.dart';

part 'pending_ai_work.g.dart';

/// What a run with AI would do now, as the categorizer last worked it out:
/// a moment after what it depends on changes, held while a run goes, and
/// once more when it ends. None before the history is shown.
@Riverpod(keepAlive: true)
class PendingAiWork extends _$PendingAiWork {
  @override
  AiWorkSummary? build() => null;

  void set(AiWorkSummary? summary) => state = summary;
}
