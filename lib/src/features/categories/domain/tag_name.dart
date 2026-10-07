import 'package:dart_mappable/dart_mappable.dart';

import 'channel_category.dart';
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
