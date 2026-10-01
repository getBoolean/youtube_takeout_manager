import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import '../data/ai_errors.dart';

part 'ai_tiers.g.dart';

/// The AI services turned off this session, e.g. for a rejected key, and a
/// notice saying why categorizing changed, until dismissed.
typedef AiTierState = ({Set<AiService> disabled, String? notice});

/// Which AI services categorizing uses this session, and what to say about
/// it. A service is turned back on when its key changes.
@Riverpod(keepAlive: true)
class AiTierStatus extends _$AiTierStatus {
  @override
  AiTierState build() => (disabled: const {}, notice: null);

  /// Turns [service] off for the session, saying [notice].
  void disable(AiService service, String notice) =>
      state = (disabled: {...state.disabled, service}, notice: notice);

  /// Says [notice], e.g. that categorizing stopped for now.
  void note(String notice) =>
      state = (disabled: state.disabled, notice: notice);

  /// Turns [service] back on, e.g. with a new key.
  void enable(AiService service) => state = (
    disabled: {...state.disabled}..remove(service),
    notice: state.notice,
  );

  void dismiss() => state = (disabled: state.disabled, notice: null);
}

/// When [failure] says its service can be asked again, if it says.
DateTime? resumeAtOf(AiFailure failure) => switch (failure) {
  AiRateLimited(:final resumeAt) || AiOverloaded(:final resumeAt) => resumeAt,
  _ => null,
};

/// [time] as a time of day where the user is, e.g. to say when a service
/// can be asked again.
String timeOfDay(DateTime time) => DateFormat.jm().format(time.toLocal());

/// An AI step that failed, and which service it was.
class AiTierFailure implements Exception {
  final AiService service;
  final AiFailure failure;

  const AiTierFailure(this.service, this.failure);

  @override
  String toString() => '${service.name}: $failure';
}
