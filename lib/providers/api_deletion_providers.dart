import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/api_deletion_result.dart';
import '../services/google_auth_service.dart';
import '../services/youtube_comment_service.dart';
import '../services/youtube_live_chat_service.dart';
import 'auth_providers.dart';
import 'deleted_ids_providers.dart';
import 'takeout_providers.dart';

part 'api_deletion_providers.g.dart';

@riverpod
class CommentApiDeletion extends _$CommentApiDeletion {
  @override
  ApiDeletionResult? build() => null;

  Future<void> deleteComments(Set<String> commentIds) async {
    final authState = ref.read(authProvider);
    if (authState == null) return;

    final authService = GoogleAuthService();
    final client = authService.getAuthenticatedClient(authState.accessToken);
    final service = YoutubeCommentService();

    await for (final result
        in service.deleteCommentsBatch(client, commentIds.toList())) {
      state = result;
    }

    // Persist successfully deleted IDs and remove from local state
    final deletedIds =
        commentIds.difference(state?.failedIds.toSet() ?? {});
    if (deletedIds.isNotEmpty) {
      await ref
          .read(deletedCommentIdsProvider.notifier)
          .markDeleted(deletedIds);
      ref.read(takeoutProvider.notifier).removeComments(deletedIds);
    }

    client.close();
  }
}

@riverpod
class LiveChatApiDeletion extends _$LiveChatApiDeletion {
  @override
  ApiDeletionResult? build() => null;

  Future<void> deleteLiveChats(Set<String> liveChatIds) async {
    final authState = ref.read(authProvider);
    if (authState == null) return;

    final authService = GoogleAuthService();
    final client = authService.getAuthenticatedClient(authState.accessToken);
    final service = YoutubeLiveChatService();

    await for (final result
        in service.deleteLiveChatMessagesBatch(client, liveChatIds.toList())) {
      state = result;
    }

    // Persist successfully deleted IDs and remove from local state
    final deletedIds =
        liveChatIds.difference(state?.failedIds.toSet() ?? {});
    if (deletedIds.isNotEmpty) {
      await ref
          .read(deletedLiveChatIdsProvider.notifier)
          .markDeleted(deletedIds);
      ref.read(takeoutProvider.notifier).removeLiveChats(deletedIds);
    }

    client.close();
  }
}
