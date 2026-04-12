// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'api_deletion_result.dart';

class ApiDeletionResultMapper extends ClassMapperBase<ApiDeletionResult> {
  ApiDeletionResultMapper._();

  static ApiDeletionResultMapper? _instance;
  static ApiDeletionResultMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ApiDeletionResultMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ApiDeletionResult';

  static int _$total(ApiDeletionResult v) => v.total;
  static const Field<ApiDeletionResult, int> _f$total = Field('total', _$total);
  static int _$succeeded(ApiDeletionResult v) => v.succeeded;
  static const Field<ApiDeletionResult, int> _f$succeeded = Field(
    'succeeded',
    _$succeeded,
  );
  static int _$failed(ApiDeletionResult v) => v.failed;
  static const Field<ApiDeletionResult, int> _f$failed = Field(
    'failed',
    _$failed,
  );
  static int _$remaining(ApiDeletionResult v) => v.remaining;
  static const Field<ApiDeletionResult, int> _f$remaining = Field(
    'remaining',
    _$remaining,
  );
  static List<String> _$failedIds(ApiDeletionResult v) => v.failedIds;
  static const Field<ApiDeletionResult, List<String>> _f$failedIds = Field(
    'failedIds',
    _$failedIds,
    opt: true,
    def: const [],
  );
  static String? _$errorMessage(ApiDeletionResult v) => v.errorMessage;
  static const Field<ApiDeletionResult, String> _f$errorMessage = Field(
    'errorMessage',
    _$errorMessage,
    opt: true,
  );

  @override
  final MappableFields<ApiDeletionResult> fields = const {
    #total: _f$total,
    #succeeded: _f$succeeded,
    #failed: _f$failed,
    #remaining: _f$remaining,
    #failedIds: _f$failedIds,
    #errorMessage: _f$errorMessage,
  };

  static ApiDeletionResult _instantiate(DecodingData data) {
    return ApiDeletionResult(
      total: data.dec(_f$total),
      succeeded: data.dec(_f$succeeded),
      failed: data.dec(_f$failed),
      remaining: data.dec(_f$remaining),
      failedIds: data.dec(_f$failedIds),
      errorMessage: data.dec(_f$errorMessage),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ApiDeletionResult fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ApiDeletionResult>(map);
  }

  static ApiDeletionResult fromJson(String json) {
    return ensureInitialized().decodeJson<ApiDeletionResult>(json);
  }
}

mixin ApiDeletionResultMappable {
  String toJson() {
    return ApiDeletionResultMapper.ensureInitialized()
        .encodeJson<ApiDeletionResult>(this as ApiDeletionResult);
  }

  Map<String, dynamic> toMap() {
    return ApiDeletionResultMapper.ensureInitialized()
        .encodeMap<ApiDeletionResult>(this as ApiDeletionResult);
  }

  ApiDeletionResultCopyWith<
    ApiDeletionResult,
    ApiDeletionResult,
    ApiDeletionResult
  >
  get copyWith =>
      _ApiDeletionResultCopyWithImpl<ApiDeletionResult, ApiDeletionResult>(
        this as ApiDeletionResult,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ApiDeletionResultMapper.ensureInitialized().stringifyValue(
      this as ApiDeletionResult,
    );
  }

  @override
  bool operator ==(Object other) {
    return ApiDeletionResultMapper.ensureInitialized().equalsValue(
      this as ApiDeletionResult,
      other,
    );
  }

  @override
  int get hashCode {
    return ApiDeletionResultMapper.ensureInitialized().hashValue(
      this as ApiDeletionResult,
    );
  }
}

extension ApiDeletionResultValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ApiDeletionResult, $Out> {
  ApiDeletionResultCopyWith<$R, ApiDeletionResult, $Out>
  get $asApiDeletionResult => $base.as(
    (v, t, t2) => _ApiDeletionResultCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ApiDeletionResultCopyWith<
  $R,
  $In extends ApiDeletionResult,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get failedIds;
  $R call({
    int? total,
    int? succeeded,
    int? failed,
    int? remaining,
    List<String>? failedIds,
    String? errorMessage,
  });
  ApiDeletionResultCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ApiDeletionResultCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ApiDeletionResult, $Out>
    implements ApiDeletionResultCopyWith<$R, ApiDeletionResult, $Out> {
  _ApiDeletionResultCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ApiDeletionResult> $mapper =
      ApiDeletionResultMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get failedIds =>
      ListCopyWith(
        $value.failedIds,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(failedIds: v),
      );
  @override
  $R call({
    int? total,
    int? succeeded,
    int? failed,
    int? remaining,
    List<String>? failedIds,
    Object? errorMessage = $none,
  }) => $apply(
    FieldCopyWithData({
      if (total != null) #total: total,
      if (succeeded != null) #succeeded: succeeded,
      if (failed != null) #failed: failed,
      if (remaining != null) #remaining: remaining,
      if (failedIds != null) #failedIds: failedIds,
      if (errorMessage != $none) #errorMessage: errorMessage,
    }),
  );
  @override
  ApiDeletionResult $make(CopyWithData data) => ApiDeletionResult(
    total: data.get(#total, or: $value.total),
    succeeded: data.get(#succeeded, or: $value.succeeded),
    failed: data.get(#failed, or: $value.failed),
    remaining: data.get(#remaining, or: $value.remaining),
    failedIds: data.get(#failedIds, or: $value.failedIds),
    errorMessage: data.get(#errorMessage, or: $value.errorMessage),
  );

  @override
  ApiDeletionResultCopyWith<$R2, ApiDeletionResult, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ApiDeletionResultCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

