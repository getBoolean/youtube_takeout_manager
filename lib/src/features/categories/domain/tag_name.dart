import 'package:dart_mappable/dart_mappable.dart';

import 'channel_category.dart';
import 'sub_category.dart';

part 'tag_name.mapper.dart';

/// A tag as first spelled, and who made it: whoever first did keeps it,
/// whoever adds it to another channel.
@MappableClass()
class TagName with TagNameMappable {
  final String name;
  final NameOrigin origin;

  const TagName({required this.name, this.origin = NameOrigin.ai});
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
