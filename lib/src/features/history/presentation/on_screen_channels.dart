import 'package:flutter/scheduler.dart';

/// Gathers the channels of the rows built during a frame, the rows on
/// screen or about to be, and hands them on together once it's drawn, in
/// the order they were built.
class OnScreenChannels {
  final void Function(List<String> channelIds) _onShown;
  final _channelIds = <String>{};
  var _scheduled = false;
  var _disposed = false;

  OnScreenChannels(this._onShown);

  /// Notes the channel of a row being built; rows without one are skipped.
  void add(String? channelId) {
    if (_disposed || channelId == null || !_channelIds.add(channelId)) return;
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final shown = _channelIds.toList();
      _channelIds.clear();
      if (!_disposed) _onShown(shown);
    });
  }

  void dispose() => _disposed = true;
}
