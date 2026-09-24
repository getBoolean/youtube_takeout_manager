// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'queue_item_kind.dart';

class QueueItemKindMapper extends EnumMapper<QueueItemKind> {
  QueueItemKindMapper._();

  static QueueItemKindMapper? _instance;
  static QueueItemKindMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = QueueItemKindMapper._());
    }
    return _instance!;
  }

  static QueueItemKind fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  QueueItemKind decode(dynamic value) {
    switch (value) {
      case r'comment':
        return QueueItemKind.comment;
      case r'liveChat':
        return QueueItemKind.liveChat;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(QueueItemKind self) {
    switch (self) {
      case QueueItemKind.comment:
        return r'comment';
      case QueueItemKind.liveChat:
        return r'liveChat';
    }
  }
}

extension QueueItemKindMapperExtension on QueueItemKind {
  String toValue() {
    QueueItemKindMapper.ensureInitialized();
    return MapperContainer.globals.toValue<QueueItemKind>(this) as String;
  }
}

