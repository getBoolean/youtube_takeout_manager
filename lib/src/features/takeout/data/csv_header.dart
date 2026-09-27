import '../domain/takeout_import_plan.dart';

/// A CSV file's header: where each column is, by name.
class CsvHeader {
  /// Column index by lowercased, trimmed name.
  final Map<String, int> _index;

  /// What the file holds, for errors.
  final String _file;

  CsvHeader(List<dynamic> row, this._file)
    : _index = {
        for (var i = 0; i < row.length; i++)
          row[i].toString().toLowerCase().trim(): i,
      };

  /// The index of the column called [name] or one of [otherNames], or null
  /// if there's none.
  int? optional(String name, [List<String> otherNames = const []]) {
    for (final n in [name, ...otherNames]) {
      if (_index[n.toLowerCase()] case final i?) return i;
    }
    return null;
  }

  /// The index of [column], which the file can't be read without, also
  /// trying [otherNames]. Throws when the header has none of them.
  int required(String column, [List<String> otherNames = const []]) =>
      optional(column, otherNames) ??
      (throw TakeoutImportException(
        "The takeout's $_file file has no \"$column\" column, so it "
        "couldn't be read. Google may have changed the takeout's format.",
      ));
}
