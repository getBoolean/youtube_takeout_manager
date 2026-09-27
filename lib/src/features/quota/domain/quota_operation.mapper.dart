// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'quota_operation.dart';

class QuotaOperationMapper extends EnumMapper<QuotaOperation> {
  QuotaOperationMapper._();

  static QuotaOperationMapper? _instance;
  static QuotaOperationMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = QuotaOperationMapper._());
    }
    return _instance!;
  }

  static QuotaOperation fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  QuotaOperation decode(dynamic value) {
    switch (value) {
      case r'deleteComment':
        return QuotaOperation.deleteComment;
      case r'deleteLiveChat':
        return QuotaOperation.deleteLiveChat;
      case r'videosList':
        return QuotaOperation.videosList;
      case r'channelsList':
        return QuotaOperation.channelsList;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(QuotaOperation self) {
    switch (self) {
      case QuotaOperation.deleteComment:
        return r'deleteComment';
      case QuotaOperation.deleteLiveChat:
        return r'deleteLiveChat';
      case QuotaOperation.videosList:
        return r'videosList';
      case QuotaOperation.channelsList:
        return r'channelsList';
    }
  }
}

extension QuotaOperationMapperExtension on QuotaOperation {
  String toValue() {
    QuotaOperationMapper.ensureInitialized();
    return MapperContainer.globals.toValue<QuotaOperation>(this) as String;
  }
}

