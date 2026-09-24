// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deletion_item_status.dart';

class DeletionItemStatusMapper extends EnumMapper<DeletionItemStatus> {
  DeletionItemStatusMapper._();

  static DeletionItemStatusMapper? _instance;
  static DeletionItemStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeletionItemStatusMapper._());
    }
    return _instance!;
  }

  static DeletionItemStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  DeletionItemStatus decode(dynamic value) {
    switch (value) {
      case r'pending':
        return DeletionItemStatus.pending;
      case r'inProgress':
        return DeletionItemStatus.inProgress;
      case r'succeeded':
        return DeletionItemStatus.succeeded;
      case r'failed':
        return DeletionItemStatus.failed;
      case r'quotaExceeded':
        return DeletionItemStatus.quotaExceeded;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(DeletionItemStatus self) {
    switch (self) {
      case DeletionItemStatus.pending:
        return r'pending';
      case DeletionItemStatus.inProgress:
        return r'inProgress';
      case DeletionItemStatus.succeeded:
        return r'succeeded';
      case DeletionItemStatus.failed:
        return r'failed';
      case DeletionItemStatus.quotaExceeded:
        return r'quotaExceeded';
    }
  }
}

extension DeletionItemStatusMapperExtension on DeletionItemStatus {
  String toValue() {
    DeletionItemStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<DeletionItemStatus>(this) as String;
  }
}

