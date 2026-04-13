// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deletion_item_type.dart';

class DeletionItemTypeMapper extends EnumMapper<DeletionItemType> {
  DeletionItemTypeMapper._();

  static DeletionItemTypeMapper? _instance;
  static DeletionItemTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeletionItemTypeMapper._());
    }
    return _instance!;
  }

  static DeletionItemType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  DeletionItemType decode(dynamic value) {
    switch (value) {
      case r'comment':
        return DeletionItemType.comment;
      case r'liveChat':
        return DeletionItemType.liveChat;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(DeletionItemType self) {
    switch (self) {
      case DeletionItemType.comment:
        return r'comment';
      case DeletionItemType.liveChat:
        return r'liveChat';
    }
  }
}

extension DeletionItemTypeMapperExtension on DeletionItemType {
  String toValue() {
    DeletionItemTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<DeletionItemType>(this) as String;
  }
}

