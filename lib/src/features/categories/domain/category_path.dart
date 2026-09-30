import 'package:dart_mappable/dart_mappable.dart';

part 'category_path.mapper.dart';

/// A category, and the sub-category within it when there is one, e.g.
/// Gaming › Speedruns.
@MappableClass()
class CategoryPath with CategoryPathMappable {
  final String parent;
  final String? child;

  const CategoryPath(this.parent, [this.child]);

  /// "Parent › Child", or the parent alone.
  String get label => child == null ? parent : '$parent › $child';
}
