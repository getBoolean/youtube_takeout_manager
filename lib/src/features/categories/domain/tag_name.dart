import 'package:dart_mappable/dart_mappable.dart';

import 'channel_category.dart';
import 'name_key.dart';
import 'sub_category.dart';

part 'tag_name.mapper.dart';

/// The longest a tag's meaning can be.
const maxTagMeaning = 160;

/// A tag's name and, when known, what it means.
typedef NamedTag = ({String name, String? meaning});

/// A tag as first spelled, and who made it: whoever first did keeps it,
/// whoever adds it to another channel. Its [meaning] says what it's for, so
/// AI can tell where it fits; a tag the user [deleted] is kept, so no
/// answer brings it back.
@MappableClass()
class TagName with TagNameMappable {
  final String name;
  final NameOrigin origin;

  /// What the tag means, in a line: written by Claude when it named it, or
  /// by the user.
  final String? meaning;

  /// When the user defined it, or changed its meaning: channels checked
  /// before are checked again.
  final DateTime? changedAt;
  final bool deleted;

  const TagName({
    required this.name,
    this.origin = NameOrigin.ai,
    this.meaning,
    this.changedAt,
    this.deleted = false,
  });

  /// Whether AI may give it to channels: one AI named, or one the user
  /// said the meaning of; never one deleted.
  bool get offeredToAi =>
      !deleted && (origin == NameOrigin.ai || meaning != null);
}

/// [tags] named by [origin], merged into the tags there are, [names]: each
/// tidied and spelled as the tag there is with the same folded name
/// ([nameKey]), the rest added as made by [origin], with their meanings;
/// in order, each once, blanks and deleted tags left out, at most
/// [maxTags]. A tag AI named without a meaning takes the one AI gives; no
/// meaning is ever replaced, and the user's tags get none from AI. [names]
/// itself comes back when nothing changed.
({Map<String, TagName> names, List<String> resolved}) mergeNamedTags(
  Map<String, TagName> names,
  Iterable<NamedTag> tags,
  NameOrigin origin,
) {
  var updated = names;
  void change(String key, TagName tag) {
    if (identical(updated, names)) updated = {...names};
    updated[key] = tag;
  }

  final resolved = <String>[];
  final keys = <String>{};
  for (final (:name, :meaning) in tags) {
    if (resolved.length == maxTags) break;
    final tidy = tidyTagName(name);
    if (tidy == null) continue;
    final key = nameKey(tidy);
    if (!keys.add(key)) continue;
    final said = tidyTagMeaning(meaning);
    if (updated[key] case final known?) {
      if (known.deleted) continue;
      if (said != null &&
          known.meaning == null &&
          known.origin == NameOrigin.ai &&
          origin == NameOrigin.ai) {
        change(key, known.copyWith(meaning: said));
      }
      resolved.add(known.name);
      continue;
    }
    change(key, TagName(name: tidy, origin: origin, meaning: said));
    resolved.add(tidy);
  }
  return (names: updated, resolved: resolved);
}

/// [name] trimmed, with single spaces, at most [maxTagName] long; null when
/// blank.
String? tidyTagName(String name) {
  final tidy = name.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (tidy.isEmpty) return null;
  return tidy.length <= maxTagName
      ? tidy
      : tidy.substring(0, maxTagName).trimRight();
}

/// [meaning] trimmed, with single spaces, at most [maxTagMeaning] long;
/// null when blank.
String? tidyTagMeaning(String? meaning) {
  final tidy = (meaning ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (tidy.isEmpty) return null;
  return tidy.length <= maxTagMeaning
      ? tidy
      : tidy.substring(0, maxTagMeaning).trimRight();
}
