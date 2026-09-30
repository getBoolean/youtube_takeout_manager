// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'channel_category.dart';

class CategorySourceMapper extends EnumMapper<CategorySource> {
  CategorySourceMapper._();

  static CategorySourceMapper? _instance;
  static CategorySourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CategorySourceMapper._());
    }
    return _instance!;
  }

  static CategorySource fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CategorySource decode(dynamic value) {
    switch (value) {
      case r'youtube':
        return CategorySource.youtube;
      case r'jev':
        return CategorySource.jev;
      case r'claude':
        return CategorySource.claude;
      default:
        return CategorySource.values[0];
    }
  }

  @override
  dynamic encode(CategorySource self) {
    switch (self) {
      case CategorySource.youtube:
        return r'youtube';
      case CategorySource.jev:
        return r'jev';
      case CategorySource.claude:
        return r'claude';
    }
  }
}

extension CategorySourceMapperExtension on CategorySource {
  String toValue() {
    CategorySourceMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CategorySource>(this) as String;
  }
}

class UserDecisionMapper extends EnumMapper<UserDecision> {
  UserDecisionMapper._();

  static UserDecisionMapper? _instance;
  static UserDecisionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = UserDecisionMapper._());
    }
    return _instance!;
  }

  static UserDecision fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  UserDecision decode(dynamic value) {
    switch (value) {
      case r'none':
        return UserDecision.none;
      case r'accepted':
        return UserDecision.accepted;
      case r'denied':
        return UserDecision.denied;
      default:
        return UserDecision.values[0];
    }
  }

  @override
  dynamic encode(UserDecision self) {
    switch (self) {
      case UserDecision.none:
        return r'none';
      case UserDecision.accepted:
        return r'accepted';
      case UserDecision.denied:
        return r'denied';
    }
  }
}

extension UserDecisionMapperExtension on UserDecision {
  String toValue() {
    UserDecisionMapper.ensureInitialized();
    return MapperContainer.globals.toValue<UserDecision>(this) as String;
  }
}

class CategorizationTierMapper extends EnumMapper<CategorizationTier> {
  CategorizationTierMapper._();

  static CategorizationTierMapper? _instance;
  static CategorizationTierMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CategorizationTierMapper._());
    }
    return _instance!;
  }

  static CategorizationTier fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CategorizationTier decode(dynamic value) {
    switch (value) {
      case r'youtube':
        return CategorizationTier.youtube;
      case r'jev':
        return CategorizationTier.jev;
      case r'claude':
        return CategorizationTier.claude;
      default:
        return CategorizationTier.values[0];
    }
  }

  @override
  dynamic encode(CategorizationTier self) {
    switch (self) {
      case CategorizationTier.youtube:
        return r'youtube';
      case CategorizationTier.jev:
        return r'jev';
      case CategorizationTier.claude:
        return r'claude';
    }
  }
}

extension CategorizationTierMapperExtension on CategorizationTier {
  String toValue() {
    CategorizationTierMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CategorizationTier>(this) as String;
  }
}

class ScoredPathMapper extends ClassMapperBase<ScoredPath> {
  ScoredPathMapper._();

  static ScoredPathMapper? _instance;
  static ScoredPathMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ScoredPathMapper._());
      CategoryPathMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ScoredPath';

  static CategoryPath _$path(ScoredPath v) => v.path;
  static const Field<ScoredPath, CategoryPath> _f$path = Field('path', _$path);
  static double _$score(ScoredPath v) => v.score;
  static const Field<ScoredPath, double> _f$score = Field('score', _$score);

  @override
  final MappableFields<ScoredPath> fields = const {
    #path: _f$path,
    #score: _f$score,
  };

  static ScoredPath _instantiate(DecodingData data) {
    return ScoredPath(path: data.dec(_f$path), score: data.dec(_f$score));
  }

  @override
  final Function instantiate = _instantiate;

  static ScoredPath fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ScoredPath>(map);
  }

  static ScoredPath fromJson(String json) {
    return ensureInitialized().decodeJson<ScoredPath>(json);
  }
}

mixin ScoredPathMappable {
  String toJson() {
    return ScoredPathMapper.ensureInitialized().encodeJson<ScoredPath>(
      this as ScoredPath,
    );
  }

  Map<String, dynamic> toMap() {
    return ScoredPathMapper.ensureInitialized().encodeMap<ScoredPath>(
      this as ScoredPath,
    );
  }

  ScoredPathCopyWith<ScoredPath, ScoredPath, ScoredPath> get copyWith =>
      _ScoredPathCopyWithImpl<ScoredPath, ScoredPath>(
        this as ScoredPath,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ScoredPathMapper.ensureInitialized().stringifyValue(
      this as ScoredPath,
    );
  }

  @override
  bool operator ==(Object other) {
    return ScoredPathMapper.ensureInitialized().equalsValue(
      this as ScoredPath,
      other,
    );
  }

  @override
  int get hashCode {
    return ScoredPathMapper.ensureInitialized().hashValue(this as ScoredPath);
  }
}

extension ScoredPathValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ScoredPath, $Out> {
  ScoredPathCopyWith<$R, ScoredPath, $Out> get $asScoredPath =>
      $base.as((v, t, t2) => _ScoredPathCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ScoredPathCopyWith<$R, $In extends ScoredPath, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  CategoryPathCopyWith<$R, CategoryPath, CategoryPath> get path;
  $R call({CategoryPath? path, double? score});
  ScoredPathCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ScoredPathCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ScoredPath, $Out>
    implements ScoredPathCopyWith<$R, ScoredPath, $Out> {
  _ScoredPathCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ScoredPath> $mapper =
      ScoredPathMapper.ensureInitialized();
  @override
  CategoryPathCopyWith<$R, CategoryPath, CategoryPath> get path =>
      $value.path.copyWith.$chain((v) => call(path: v));
  @override
  $R call({CategoryPath? path, double? score}) => $apply(
    FieldCopyWithData({
      if (path != null) #path: path,
      if (score != null) #score: score,
    }),
  );
  @override
  ScoredPath $make(CopyWithData data) => ScoredPath(
    path: data.get(#path, or: $value.path),
    score: data.get(#score, or: $value.score),
  );

  @override
  ScoredPathCopyWith<$R2, ScoredPath, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ScoredPathCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ChannelCategoryMapper extends ClassMapperBase<ChannelCategory> {
  ChannelCategoryMapper._();

  static ChannelCategoryMapper? _instance;
  static ChannelCategoryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChannelCategoryMapper._());
      CategoryPathMapper.ensureInitialized();
      CategorySourceMapper.ensureInitialized();
      ScoredPathMapper.ensureInitialized();
      CategorizationTierMapper.ensureInitialized();
      UserDecisionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ChannelCategory';

  static CategoryPath? _$path(ChannelCategory v) => v.path;
  static const Field<ChannelCategory, CategoryPath> _f$path = Field(
    'path',
    _$path,
    opt: true,
  );
  static CategorySource _$source(ChannelCategory v) => v.source;
  static const Field<ChannelCategory, CategorySource> _f$source = Field(
    'source',
    _$source,
    opt: true,
    def: CategorySource.youtube,
  );
  static double? _$jevAgreed(ChannelCategory v) => v.jevAgreed;
  static const Field<ChannelCategory, double> _f$jevAgreed = Field(
    'jevAgreed',
    _$jevAgreed,
    opt: true,
  );
  static double? _$confidence(ChannelCategory v) => v.confidence;
  static const Field<ChannelCategory, double> _f$confidence = Field(
    'confidence',
    _$confidence,
    opt: true,
  );
  static List<ScoredPath> _$runnersUp(ChannelCategory v) => v.runnersUp;
  static const Field<ChannelCategory, List<ScoredPath>> _f$runnersUp = Field(
    'runnersUp',
    _$runnersUp,
    opt: true,
    def: const [],
  );
  static String? _$reason(ChannelCategory v) => v.reason;
  static const Field<ChannelCategory, String> _f$reason = Field(
    'reason',
    _$reason,
    opt: true,
  );
  static Set<CategorizationTier> _$tried(ChannelCategory v) => v.tried;
  static const Field<ChannelCategory, Set<CategorizationTier>> _f$tried = Field(
    'tried',
    _$tried,
    opt: true,
    def: const {},
  );
  static bool _$hadTopics(ChannelCategory v) => v.hadTopics;
  static const Field<ChannelCategory, bool> _f$hadTopics = Field(
    'hadTopics',
    _$hadTopics,
    opt: true,
    def: false,
  );
  static UserDecision _$userDecision(ChannelCategory v) => v.userDecision;
  static const Field<ChannelCategory, UserDecision> _f$userDecision = Field(
    'userDecision',
    _$userDecision,
    opt: true,
    def: UserDecision.none,
  );
  static DateTime _$decidedAt(ChannelCategory v) => v.decidedAt;
  static const Field<ChannelCategory, DateTime> _f$decidedAt = Field(
    'decidedAt',
    _$decidedAt,
  );

  @override
  final MappableFields<ChannelCategory> fields = const {
    #path: _f$path,
    #source: _f$source,
    #jevAgreed: _f$jevAgreed,
    #confidence: _f$confidence,
    #runnersUp: _f$runnersUp,
    #reason: _f$reason,
    #tried: _f$tried,
    #hadTopics: _f$hadTopics,
    #userDecision: _f$userDecision,
    #decidedAt: _f$decidedAt,
  };

  static ChannelCategory _instantiate(DecodingData data) {
    return ChannelCategory(
      path: data.dec(_f$path),
      source: data.dec(_f$source),
      jevAgreed: data.dec(_f$jevAgreed),
      confidence: data.dec(_f$confidence),
      runnersUp: data.dec(_f$runnersUp),
      reason: data.dec(_f$reason),
      tried: data.dec(_f$tried),
      hadTopics: data.dec(_f$hadTopics),
      userDecision: data.dec(_f$userDecision),
      decidedAt: data.dec(_f$decidedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ChannelCategory fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChannelCategory>(map);
  }

  static ChannelCategory fromJson(String json) {
    return ensureInitialized().decodeJson<ChannelCategory>(json);
  }
}

mixin ChannelCategoryMappable {
  String toJson() {
    return ChannelCategoryMapper.ensureInitialized()
        .encodeJson<ChannelCategory>(this as ChannelCategory);
  }

  Map<String, dynamic> toMap() {
    return ChannelCategoryMapper.ensureInitialized().encodeMap<ChannelCategory>(
      this as ChannelCategory,
    );
  }

  ChannelCategoryCopyWith<ChannelCategory, ChannelCategory, ChannelCategory>
  get copyWith =>
      _ChannelCategoryCopyWithImpl<ChannelCategory, ChannelCategory>(
        this as ChannelCategory,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChannelCategoryMapper.ensureInitialized().stringifyValue(
      this as ChannelCategory,
    );
  }

  @override
  bool operator ==(Object other) {
    return ChannelCategoryMapper.ensureInitialized().equalsValue(
      this as ChannelCategory,
      other,
    );
  }

  @override
  int get hashCode {
    return ChannelCategoryMapper.ensureInitialized().hashValue(
      this as ChannelCategory,
    );
  }
}

extension ChannelCategoryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChannelCategory, $Out> {
  ChannelCategoryCopyWith<$R, ChannelCategory, $Out> get $asChannelCategory =>
      $base.as((v, t, t2) => _ChannelCategoryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChannelCategoryCopyWith<$R, $In extends ChannelCategory, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  CategoryPathCopyWith<$R, CategoryPath, CategoryPath>? get path;
  ListCopyWith<$R, ScoredPath, ScoredPathCopyWith<$R, ScoredPath, ScoredPath>>
  get runnersUp;
  $R call({
    CategoryPath? path,
    CategorySource? source,
    double? jevAgreed,
    double? confidence,
    List<ScoredPath>? runnersUp,
    String? reason,
    Set<CategorizationTier>? tried,
    bool? hadTopics,
    UserDecision? userDecision,
    DateTime? decidedAt,
  });
  ChannelCategoryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ChannelCategoryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChannelCategory, $Out>
    implements ChannelCategoryCopyWith<$R, ChannelCategory, $Out> {
  _ChannelCategoryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChannelCategory> $mapper =
      ChannelCategoryMapper.ensureInitialized();
  @override
  CategoryPathCopyWith<$R, CategoryPath, CategoryPath>? get path =>
      $value.path?.copyWith.$chain((v) => call(path: v));
  @override
  ListCopyWith<$R, ScoredPath, ScoredPathCopyWith<$R, ScoredPath, ScoredPath>>
  get runnersUp => ListCopyWith(
    $value.runnersUp,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(runnersUp: v),
  );
  @override
  $R call({
    Object? path = $none,
    CategorySource? source,
    Object? jevAgreed = $none,
    Object? confidence = $none,
    List<ScoredPath>? runnersUp,
    Object? reason = $none,
    Set<CategorizationTier>? tried,
    bool? hadTopics,
    UserDecision? userDecision,
    DateTime? decidedAt,
  }) => $apply(
    FieldCopyWithData({
      if (path != $none) #path: path,
      if (source != null) #source: source,
      if (jevAgreed != $none) #jevAgreed: jevAgreed,
      if (confidence != $none) #confidence: confidence,
      if (runnersUp != null) #runnersUp: runnersUp,
      if (reason != $none) #reason: reason,
      if (tried != null) #tried: tried,
      if (hadTopics != null) #hadTopics: hadTopics,
      if (userDecision != null) #userDecision: userDecision,
      if (decidedAt != null) #decidedAt: decidedAt,
    }),
  );
  @override
  ChannelCategory $make(CopyWithData data) => ChannelCategory(
    path: data.get(#path, or: $value.path),
    source: data.get(#source, or: $value.source),
    jevAgreed: data.get(#jevAgreed, or: $value.jevAgreed),
    confidence: data.get(#confidence, or: $value.confidence),
    runnersUp: data.get(#runnersUp, or: $value.runnersUp),
    reason: data.get(#reason, or: $value.reason),
    tried: data.get(#tried, or: $value.tried),
    hadTopics: data.get(#hadTopics, or: $value.hadTopics),
    userDecision: data.get(#userDecision, or: $value.userDecision),
    decidedAt: data.get(#decidedAt, or: $value.decidedAt),
  );

  @override
  ChannelCategoryCopyWith<$R2, ChannelCategory, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ChannelCategoryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

