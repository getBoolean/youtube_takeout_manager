// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: WorkerGenerator 9.3.2 (Squadron 7.4.4)
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'history_service.dart';

void _start$HistoryService(WorkerRequest command) {
  /// VM entry point for HistoryService
  run($HistoryServiceInitializer, command);
}

EntryPoint $getHistoryServiceActivator(SquadronPlatformType platform) {
  if (platform.isVm) {
    return _start$HistoryService;
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
