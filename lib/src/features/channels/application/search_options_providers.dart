import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/search_options_state.dart';

part 'search_options_providers.g.dart';

const _keyExpandMatchedVideos = 'search.expandMatchedVideos';
const _keyMatchGroupTitles = 'search.matchGroupTitles';

@Riverpod(keepAlive: true)
class SearchOptions extends _$SearchOptions {
  final _storage = KvStorageService();

  @override
  Future<SearchOptionsState> build() async {
    final expand = await _storage.getBoolean(_keyExpandMatchedVideos);
    final matchTitles = await _storage.getBoolean(_keyMatchGroupTitles);
    return SearchOptionsState(
      expandMatchedVideos: expand ?? false,
      matchGroupTitles: matchTitles ?? true,
    );
  }

  Future<void> setExpandMatchedVideos(bool value) async {
    await _storage.setBoolean(_keyExpandMatchedVideos, value);
    final current = await future;
    state = AsyncData(current.copyWith(expandMatchedVideos: value));
  }

  Future<void> setMatchGroupTitles(bool value) async {
    await _storage.setBoolean(_keyMatchGroupTitles, value);
    final current = await future;
    state = AsyncData(current.copyWith(matchGroupTitles: value));
  }
}
