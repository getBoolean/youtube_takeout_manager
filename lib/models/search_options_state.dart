import 'package:dart_mappable/dart_mappable.dart';

part 'search_options_state.mapper.dart';

@MappableClass()
class SearchOptionsState with SearchOptionsStateMappable {
  final bool expandMatchedVideos;
  final bool matchGroupTitles;

  const SearchOptionsState({
    this.expandMatchedVideos = false,
    this.matchGroupTitles = true,
  });

  bool get isDefault => !expandMatchedVideos && matchGroupTitles;
}
