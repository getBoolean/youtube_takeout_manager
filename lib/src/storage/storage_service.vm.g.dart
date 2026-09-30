// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: WorkerGenerator 9.3.2 (Squadron 7.4.4)
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'storage_service.dart';

void _start$StorageService(WorkerRequest command) {
  /// VM entry point for StorageService
  run($StorageServiceInitializer, command);
}

EntryPoint $getStorageServiceActivator(SquadronPlatformType platform) {
  if (platform.isVm) {
    return _start$StorageService;
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
