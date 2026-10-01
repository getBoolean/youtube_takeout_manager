import 'package:dart_mappable/dart_mappable.dart';

part 'sub_category.mapper.dart';

/// Who made a name: AI, or the user, typing it.
@MappableEnum(defaultValue: NameOrigin.ai)
enum NameOrigin { ai, user }

/// A sub-category made for channels YouTube's don't fit: its name, who made
/// it, and its emoji, when one was picked.
@MappableClass()
class SubCategory with SubCategoryMappable {
  final String name;
  final NameOrigin origin;
  final String? emoji;

  const SubCategory({
    required this.name,
    this.origin = NameOrigin.ai,
    this.emoji,
  });

  /// As kept: a record, or, from before records, just its name, which AI
  /// made then.
  static SubCategory fromStored(Object? json) => json is String
      ? SubCategory(name: json)
      : SubCategoryMapper.fromMap(json! as Map<String, dynamic>);
}

/// [custom]'s names alone, by category.
Map<String, List<String>> subCategoryNames(
  Map<String, List<SubCategory>> custom,
) => {
  for (final MapEntry(:key, :value) in custom.entries)
    key: [for (final sub in value) sub.name],
};
