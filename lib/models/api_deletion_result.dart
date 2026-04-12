import 'package:dart_mappable/dart_mappable.dart';

part 'api_deletion_result.mapper.dart';

@MappableClass()
class ApiDeletionResult with ApiDeletionResultMappable {
  final int total;
  final int succeeded;
  final int failed;
  final int remaining;
  final List<String> failedIds;
  final String? errorMessage;

  const ApiDeletionResult({
    required this.total,
    required this.succeeded,
    required this.failed,
    required this.remaining,
    this.failedIds = const [],
    this.errorMessage,
  });
}
