// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: WorkerGenerator 9.3.2 (Squadron 7.4.4)
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'storage_service.dart';

void main() {
  /// Web entry point for StorageService
  run($StorageServiceInitializer);
}

EntryPoint $getStorageServiceActivator(SquadronPlatformType platform) {
  if (platform.isJs) {
    return Squadron.uri('~/workers/storage_service.web.g.dart.js');
  } else if (platform.isWasm) {
    return Squadron.uri('~/workers/storage_service.web.g.dart.wasm');
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
