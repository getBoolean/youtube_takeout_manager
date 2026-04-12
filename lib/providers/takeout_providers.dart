import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/takeout_data.dart';
import '../services/takeout_import_service.dart';

part 'takeout_providers.g.dart';

@Riverpod(keepAlive: true)
class TakeoutNotifier extends _$TakeoutNotifier {
  @override
  TakeoutData? build() => null;

  Future<void> importFiles() async {
    final service = TakeoutImportService();
    final data = await service.pickAndImport();
    if (data != null) {
      state = data;
    }
  }

  void removeComments(Set<String> commentIds) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      comments:
          current.comments.where((c) => !commentIds.contains(c.commentId)).toList(),
    );
  }

  void removeLiveChats(Set<String> liveChatIds) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      liveChats:
          current.liveChats.where((c) => !liveChatIds.contains(c.liveChatId)).toList(),
    );
  }
}
