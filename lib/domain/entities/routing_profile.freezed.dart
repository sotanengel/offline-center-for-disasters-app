// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routing_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoutingProfile {

/// mobility = normal / slow / assisted / wheelchair → 1.25 / 0.8 / 0.6 / 0.7
 double get speedMps;/// どの hz_* 属性を「該当災害の想定区域内」とみなすか
 HazardEdgeKind get hazardField;/// 想定区域内ペナルティ（既定 4.0 = 実質回避）
 double get hazardZonePenalty;/// 土砂災害特別警戒区域を通行不可（999）にする
 bool get landslideSpecialForbidden;/// アンダーパス・地下道を禁止（浸水系: 999）
 bool get forbidUnderpass;/// アンダーパス・地下道のペナルティ（その他: 2.0）
 double get underpassPenalty;/// 河川隣接 20m 以内（浸水系: 0.5）
 double get riverNearPenalty;/// 幅員 < 4m（earthquake 時: 0.8）
 double get narrowPenalty;/// 階段エッジ禁止（mobility ≠ normal: 999）
 bool get forbidSteps;/// 幅員 < 1.5m 禁止（mobility = wheelchair: 999）
 bool get forbidNarrowWheelchair;/// 日没後かどうか（街灯なしエッジに nightPenalty を適用）
 bool get isNight; double get nightPenalty;
/// Create a copy of RoutingProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingProfileCopyWith<RoutingProfile> get copyWith => _$RoutingProfileCopyWithImpl<RoutingProfile>(this as RoutingProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingProfile&&(identical(other.speedMps, speedMps) || other.speedMps == speedMps)&&(identical(other.hazardField, hazardField) || other.hazardField == hazardField)&&(identical(other.hazardZonePenalty, hazardZonePenalty) || other.hazardZonePenalty == hazardZonePenalty)&&(identical(other.landslideSpecialForbidden, landslideSpecialForbidden) || other.landslideSpecialForbidden == landslideSpecialForbidden)&&(identical(other.forbidUnderpass, forbidUnderpass) || other.forbidUnderpass == forbidUnderpass)&&(identical(other.underpassPenalty, underpassPenalty) || other.underpassPenalty == underpassPenalty)&&(identical(other.riverNearPenalty, riverNearPenalty) || other.riverNearPenalty == riverNearPenalty)&&(identical(other.narrowPenalty, narrowPenalty) || other.narrowPenalty == narrowPenalty)&&(identical(other.forbidSteps, forbidSteps) || other.forbidSteps == forbidSteps)&&(identical(other.forbidNarrowWheelchair, forbidNarrowWheelchair) || other.forbidNarrowWheelchair == forbidNarrowWheelchair)&&(identical(other.isNight, isNight) || other.isNight == isNight)&&(identical(other.nightPenalty, nightPenalty) || other.nightPenalty == nightPenalty));
}


@override
int get hashCode => Object.hash(runtimeType,speedMps,hazardField,hazardZonePenalty,landslideSpecialForbidden,forbidUnderpass,underpassPenalty,riverNearPenalty,narrowPenalty,forbidSteps,forbidNarrowWheelchair,isNight,nightPenalty);

@override
String toString() {
  return 'RoutingProfile(speedMps: $speedMps, hazardField: $hazardField, hazardZonePenalty: $hazardZonePenalty, landslideSpecialForbidden: $landslideSpecialForbidden, forbidUnderpass: $forbidUnderpass, underpassPenalty: $underpassPenalty, riverNearPenalty: $riverNearPenalty, narrowPenalty: $narrowPenalty, forbidSteps: $forbidSteps, forbidNarrowWheelchair: $forbidNarrowWheelchair, isNight: $isNight, nightPenalty: $nightPenalty)';
}


}

/// @nodoc
abstract mixin class $RoutingProfileCopyWith<$Res>  {
  factory $RoutingProfileCopyWith(RoutingProfile value, $Res Function(RoutingProfile) _then) = _$RoutingProfileCopyWithImpl;
@useResult
$Res call({
 double speedMps, HazardEdgeKind hazardField, double hazardZonePenalty, bool landslideSpecialForbidden, bool forbidUnderpass, double underpassPenalty, double riverNearPenalty, double narrowPenalty, bool forbidSteps, bool forbidNarrowWheelchair, bool isNight, double nightPenalty
});




}
/// @nodoc
class _$RoutingProfileCopyWithImpl<$Res>
    implements $RoutingProfileCopyWith<$Res> {
  _$RoutingProfileCopyWithImpl(this._self, this._then);

  final RoutingProfile _self;
  final $Res Function(RoutingProfile) _then;

/// Create a copy of RoutingProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? speedMps = null,Object? hazardField = null,Object? hazardZonePenalty = null,Object? landslideSpecialForbidden = null,Object? forbidUnderpass = null,Object? underpassPenalty = null,Object? riverNearPenalty = null,Object? narrowPenalty = null,Object? forbidSteps = null,Object? forbidNarrowWheelchair = null,Object? isNight = null,Object? nightPenalty = null,}) {
  return _then(_self.copyWith(
speedMps: null == speedMps ? _self.speedMps : speedMps // ignore: cast_nullable_to_non_nullable
as double,hazardField: null == hazardField ? _self.hazardField : hazardField // ignore: cast_nullable_to_non_nullable
as HazardEdgeKind,hazardZonePenalty: null == hazardZonePenalty ? _self.hazardZonePenalty : hazardZonePenalty // ignore: cast_nullable_to_non_nullable
as double,landslideSpecialForbidden: null == landslideSpecialForbidden ? _self.landslideSpecialForbidden : landslideSpecialForbidden // ignore: cast_nullable_to_non_nullable
as bool,forbidUnderpass: null == forbidUnderpass ? _self.forbidUnderpass : forbidUnderpass // ignore: cast_nullable_to_non_nullable
as bool,underpassPenalty: null == underpassPenalty ? _self.underpassPenalty : underpassPenalty // ignore: cast_nullable_to_non_nullable
as double,riverNearPenalty: null == riverNearPenalty ? _self.riverNearPenalty : riverNearPenalty // ignore: cast_nullable_to_non_nullable
as double,narrowPenalty: null == narrowPenalty ? _self.narrowPenalty : narrowPenalty // ignore: cast_nullable_to_non_nullable
as double,forbidSteps: null == forbidSteps ? _self.forbidSteps : forbidSteps // ignore: cast_nullable_to_non_nullable
as bool,forbidNarrowWheelchair: null == forbidNarrowWheelchair ? _self.forbidNarrowWheelchair : forbidNarrowWheelchair // ignore: cast_nullable_to_non_nullable
as bool,isNight: null == isNight ? _self.isNight : isNight // ignore: cast_nullable_to_non_nullable
as bool,nightPenalty: null == nightPenalty ? _self.nightPenalty : nightPenalty // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [RoutingProfile].
extension RoutingProfilePatterns on RoutingProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutingProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutingProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutingProfile value)  $default,){
final _that = this;
switch (_that) {
case _RoutingProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutingProfile value)?  $default,){
final _that = this;
switch (_that) {
case _RoutingProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double speedMps,  HazardEdgeKind hazardField,  double hazardZonePenalty,  bool landslideSpecialForbidden,  bool forbidUnderpass,  double underpassPenalty,  double riverNearPenalty,  double narrowPenalty,  bool forbidSteps,  bool forbidNarrowWheelchair,  bool isNight,  double nightPenalty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutingProfile() when $default != null:
return $default(_that.speedMps,_that.hazardField,_that.hazardZonePenalty,_that.landslideSpecialForbidden,_that.forbidUnderpass,_that.underpassPenalty,_that.riverNearPenalty,_that.narrowPenalty,_that.forbidSteps,_that.forbidNarrowWheelchair,_that.isNight,_that.nightPenalty);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double speedMps,  HazardEdgeKind hazardField,  double hazardZonePenalty,  bool landslideSpecialForbidden,  bool forbidUnderpass,  double underpassPenalty,  double riverNearPenalty,  double narrowPenalty,  bool forbidSteps,  bool forbidNarrowWheelchair,  bool isNight,  double nightPenalty)  $default,) {final _that = this;
switch (_that) {
case _RoutingProfile():
return $default(_that.speedMps,_that.hazardField,_that.hazardZonePenalty,_that.landslideSpecialForbidden,_that.forbidUnderpass,_that.underpassPenalty,_that.riverNearPenalty,_that.narrowPenalty,_that.forbidSteps,_that.forbidNarrowWheelchair,_that.isNight,_that.nightPenalty);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double speedMps,  HazardEdgeKind hazardField,  double hazardZonePenalty,  bool landslideSpecialForbidden,  bool forbidUnderpass,  double underpassPenalty,  double riverNearPenalty,  double narrowPenalty,  bool forbidSteps,  bool forbidNarrowWheelchair,  bool isNight,  double nightPenalty)?  $default,) {final _that = this;
switch (_that) {
case _RoutingProfile() when $default != null:
return $default(_that.speedMps,_that.hazardField,_that.hazardZonePenalty,_that.landslideSpecialForbidden,_that.forbidUnderpass,_that.underpassPenalty,_that.riverNearPenalty,_that.narrowPenalty,_that.forbidSteps,_that.forbidNarrowWheelchair,_that.isNight,_that.nightPenalty);case _:
  return null;

}
}

}

/// @nodoc


class _RoutingProfile implements RoutingProfile {
  const _RoutingProfile({this.speedMps = 1.25, this.hazardField = HazardEdgeKind.none, this.hazardZonePenalty = 4.0, this.landslideSpecialForbidden = false, this.forbidUnderpass = false, this.underpassPenalty = 0, this.riverNearPenalty = 0, this.narrowPenalty = 0, this.forbidSteps = false, this.forbidNarrowWheelchair = false, this.isNight = false, this.nightPenalty = 0.3});


/// mobility = normal / slow / assisted / wheelchair → 1.25 / 0.8 / 0.6 / 0.7
@override@JsonKey() final  double speedMps;
/// どの hz_* 属性を「該当災害の想定区域内」とみなすか
@override@JsonKey() final  HazardEdgeKind hazardField;
/// 想定区域内ペナルティ（既定 4.0 = 実質回避）
@override@JsonKey() final  double hazardZonePenalty;
/// 土砂災害特別警戒区域を通行不可（999）にする
@override@JsonKey() final  bool landslideSpecialForbidden;
/// アンダーパス・地下道を禁止（浸水系: 999）
@override@JsonKey() final  bool forbidUnderpass;
/// アンダーパス・地下道のペナルティ（その他: 2.0）
@override@JsonKey() final  double underpassPenalty;
/// 河川隣接 20m 以内（浸水系: 0.5）
@override@JsonKey() final  double riverNearPenalty;
/// 幅員 < 4m（earthquake 時: 0.8）
@override@JsonKey() final  double narrowPenalty;
/// 階段エッジ禁止（mobility ≠ normal: 999）
@override@JsonKey() final  bool forbidSteps;
/// 幅員 < 1.5m 禁止（mobility = wheelchair: 999）
@override@JsonKey() final  bool forbidNarrowWheelchair;
/// 日没後かどうか（街灯なしエッジに nightPenalty を適用）
@override@JsonKey() final  bool isNight;
@override@JsonKey() final  double nightPenalty;

/// Create a copy of RoutingProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutingProfileCopyWith<_RoutingProfile> get copyWith => __$RoutingProfileCopyWithImpl<_RoutingProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutingProfile&&(identical(other.speedMps, speedMps) || other.speedMps == speedMps)&&(identical(other.hazardField, hazardField) || other.hazardField == hazardField)&&(identical(other.hazardZonePenalty, hazardZonePenalty) || other.hazardZonePenalty == hazardZonePenalty)&&(identical(other.landslideSpecialForbidden, landslideSpecialForbidden) || other.landslideSpecialForbidden == landslideSpecialForbidden)&&(identical(other.forbidUnderpass, forbidUnderpass) || other.forbidUnderpass == forbidUnderpass)&&(identical(other.underpassPenalty, underpassPenalty) || other.underpassPenalty == underpassPenalty)&&(identical(other.riverNearPenalty, riverNearPenalty) || other.riverNearPenalty == riverNearPenalty)&&(identical(other.narrowPenalty, narrowPenalty) || other.narrowPenalty == narrowPenalty)&&(identical(other.forbidSteps, forbidSteps) || other.forbidSteps == forbidSteps)&&(identical(other.forbidNarrowWheelchair, forbidNarrowWheelchair) || other.forbidNarrowWheelchair == forbidNarrowWheelchair)&&(identical(other.isNight, isNight) || other.isNight == isNight)&&(identical(other.nightPenalty, nightPenalty) || other.nightPenalty == nightPenalty));
}


@override
int get hashCode => Object.hash(runtimeType,speedMps,hazardField,hazardZonePenalty,landslideSpecialForbidden,forbidUnderpass,underpassPenalty,riverNearPenalty,narrowPenalty,forbidSteps,forbidNarrowWheelchair,isNight,nightPenalty);

@override
String toString() {
  return 'RoutingProfile(speedMps: $speedMps, hazardField: $hazardField, hazardZonePenalty: $hazardZonePenalty, landslideSpecialForbidden: $landslideSpecialForbidden, forbidUnderpass: $forbidUnderpass, underpassPenalty: $underpassPenalty, riverNearPenalty: $riverNearPenalty, narrowPenalty: $narrowPenalty, forbidSteps: $forbidSteps, forbidNarrowWheelchair: $forbidNarrowWheelchair, isNight: $isNight, nightPenalty: $nightPenalty)';
}


}

/// @nodoc
abstract mixin class _$RoutingProfileCopyWith<$Res> implements $RoutingProfileCopyWith<$Res> {
  factory _$RoutingProfileCopyWith(_RoutingProfile value, $Res Function(_RoutingProfile) _then) = __$RoutingProfileCopyWithImpl;
@override @useResult
$Res call({
 double speedMps, HazardEdgeKind hazardField, double hazardZonePenalty, bool landslideSpecialForbidden, bool forbidUnderpass, double underpassPenalty, double riverNearPenalty, double narrowPenalty, bool forbidSteps, bool forbidNarrowWheelchair, bool isNight, double nightPenalty
});




}
/// @nodoc
class __$RoutingProfileCopyWithImpl<$Res>
    implements _$RoutingProfileCopyWith<$Res> {
  __$RoutingProfileCopyWithImpl(this._self, this._then);

  final _RoutingProfile _self;
  final $Res Function(_RoutingProfile) _then;

/// Create a copy of RoutingProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? speedMps = null,Object? hazardField = null,Object? hazardZonePenalty = null,Object? landslideSpecialForbidden = null,Object? forbidUnderpass = null,Object? underpassPenalty = null,Object? riverNearPenalty = null,Object? narrowPenalty = null,Object? forbidSteps = null,Object? forbidNarrowWheelchair = null,Object? isNight = null,Object? nightPenalty = null,}) {
  return _then(_RoutingProfile(
speedMps: null == speedMps ? _self.speedMps : speedMps // ignore: cast_nullable_to_non_nullable
as double,hazardField: null == hazardField ? _self.hazardField : hazardField // ignore: cast_nullable_to_non_nullable
as HazardEdgeKind,hazardZonePenalty: null == hazardZonePenalty ? _self.hazardZonePenalty : hazardZonePenalty // ignore: cast_nullable_to_non_nullable
as double,landslideSpecialForbidden: null == landslideSpecialForbidden ? _self.landslideSpecialForbidden : landslideSpecialForbidden // ignore: cast_nullable_to_non_nullable
as bool,forbidUnderpass: null == forbidUnderpass ? _self.forbidUnderpass : forbidUnderpass // ignore: cast_nullable_to_non_nullable
as bool,underpassPenalty: null == underpassPenalty ? _self.underpassPenalty : underpassPenalty // ignore: cast_nullable_to_non_nullable
as double,riverNearPenalty: null == riverNearPenalty ? _self.riverNearPenalty : riverNearPenalty // ignore: cast_nullable_to_non_nullable
as double,narrowPenalty: null == narrowPenalty ? _self.narrowPenalty : narrowPenalty // ignore: cast_nullable_to_non_nullable
as double,forbidSteps: null == forbidSteps ? _self.forbidSteps : forbidSteps // ignore: cast_nullable_to_non_nullable
as bool,forbidNarrowWheelchair: null == forbidNarrowWheelchair ? _self.forbidNarrowWheelchair : forbidNarrowWheelchair // ignore: cast_nullable_to_non_nullable
as bool,isNight: null == isNight ? _self.isNight : isNight // ignore: cast_nullable_to_non_nullable
as bool,nightPenalty: null == nightPenalty ? _self.nightPenalty : nightPenalty // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
