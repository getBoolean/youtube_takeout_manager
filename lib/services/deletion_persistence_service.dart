import 'package:shared_preferences/shared_preferences.dart';

const _deletedCommentIdsKey = 'deleted_comment_ids';
const _deletedLiveChatIdsKey = 'deleted_live_chat_ids';

/// Persists deleted comment and live chat IDs to local storage
/// so they survive app restarts.
class DeletionPersistenceService {
  Future<Set<String>> loadDeletedCommentIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_deletedCommentIdsKey) ?? []).toSet();
  }

  Future<Set<String>> loadDeletedLiveChatIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_deletedLiveChatIdsKey) ?? []).toSet();
  }

  Future<void> addDeletedCommentIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getStringList(_deletedCommentIdsKey) ?? []).toSet();
    existing.addAll(ids);
    await prefs.setStringList(_deletedCommentIdsKey, existing.toList());
  }

  Future<void> addDeletedLiveChatIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final existing =
        (prefs.getStringList(_deletedLiveChatIdsKey) ?? []).toSet();
    existing.addAll(ids);
    await prefs.setStringList(_deletedLiveChatIdsKey, existing.toList());
  }
}
