// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hazard_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HazardContext {

 bool get inFloodZone; double get floodDepthM; bool get inTsunamiZone; double get tsunamiDepthM;/// 0: 区域外 1: 警戒区域 2: 特別警戒区域
 int get landslideClass; bool get inStormSurgeZone; double get stormSurgeM; int get volcanoClass; int? get distCoastM; int? get distRiverM; bool get denseWood; double? get currentElevationM;/// 猶予時間（津波到達想定時間等）。不明なら null。
 Duration? get graceTime;
/// Create a copy of HazardContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HazardContextCopyWith<HazardContext> get copyWith => _$HazardContextCopyWithImpl<HazardContext>(this as HazardContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HazardContext&&(identical(other.inFloodZone, inFloodZone) || other.inFloodZone == inFloodZone)&&(identical(other.floodDepthM, floodDepthM) || other.floodDepthM == floodDepthM)&&(identical(other.inTsunamiZone, inTsunamiZone) || other.inTsunamiZone == inTsunamiZone)&&(identical(other.tsunamiDepthM, tsunamiDepthM) || other.tsunamiDepthM == tsunamiDepthM)&&(identical(other.landslideClass, landslideClass) || other.landslideClass == landslideClass)&&(identical(other.inStormSurgeZone, inStormSurgeZone) || other.inStormSurgeZone == inStormSurgeZone)&&(identical(other.stormSurgeM, stormSurgeM) || other.stormSurgeM == stormSurgeM)&&(identical(other.volcanoClass, volcanoClass) || other.volcanoClass == volcanoClass)&&(identical(other.distCoastM, distCoastM) || other.distCoastM == distCoastM)&&(identical(other.distRiverM, distRiverM) || other.distRiverM == distRiverM)&&(identical(other.denseWood, denseWood) || other.denseWood == denseWood)&&(identical(other.currentElevationM, currentElevationM) || other.currentElevationM == currentElevationM)&&(identical(other.graceTime, graceTime) || other.graceTime == graceTime));
}


@override
int get hashCode => Object.hash(runtimeType,inFloodZone,floodDepthM,inTsunamiZone,tsunamiDepthM,landslideClass,inStormSurgeZone,stormSurgeM,volcanoClass,distCoastM,distRiverM,denseWood,currentElevationM,graceTime);

@override
String toString() {
  return 'HazardContext(inFloodZone: $inFloodZone, floodDepthM: $floodDepthM, inTsunamiZone: $inTsunamiZone, tsunamiDepthM: $tsunamiDepthM, landslideClass: $landslideClass, inStormSurgeZone: $inStormSurgeZone, stormSurgeM: $stormSurgeM, volcanoClass: $volcanoClass, distCoastM: $distCoastM, distRiverM: $distRiverM, denseWood: $denseWood, currentElevationM: $currentElevationM, graceTime: $graceTime)';
}


}

/// @nodoc
abstract mixin class $HazardContextCopyWith<$Res>  {
  factory $HazardContextCopyWith(HazardContext value, $Res Function(HazardContext) _then) = _$HazardContextCopyWithImpl;
@useResult
$Res call({
 bool inFloodZone, double floodDepthM, bool inTsunamiZone, double tsunamiDepthM, int landslideClass, bool inStormSurgeZone, double stormSurgeM, int volcanoClass, int? distCoastM, int? distRiverM, bool denseWood, double? currentElevationM, Duration? graceTime
});




}
/// @nodoc
class _$HazardContextCopyWithImpl<$Res>
    implements $HazardContextCopyWith<$Res> {
  _$HazardContextCopyWithImpl(this._self, this._then);

  final HazardContext _self;
  final $Res Function(HazardContext) _then;

/// Create a copy of HazardContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inFloodZone = null,Object? floodDepthM = null,Object? inTsunamiZone = null,Object? tsunamiDepthM = null,Object? landslideClass = null,Object? inStormSurgeZone = null,Object? stormSurgeM = null,Object? volcanoClass = null,Object? distCoastM = freezed,Object? distRiverM = freezed,Object? denseWood = null,Object? currentElevationM = freezed,Object? graceTime = freezed,}) {
  return _then(_self.copyWith(
inFloodZone: null == inFloodZone ? _self.inFloodZone : inFloodZone // ignore: cast_nullable_to_non_nullable
as bool,floodDepthM: null == floodDepthM ? _self.floodDepthM : floodDepthM // ignore: cast_nullable_to_non_nullable
as double,inTsunamiZone: null == inTsunamiZone ? _self.inTsunamiZone : inTsunamiZone // ignore: cast_nullable_to_non_nullable
as bool,tsunamiDepthM: null == tsunamiDepthM ? _self.tsunamiDepthM : tsunamiDepthM // ignore: cast_nullable_to_non_nullable
as double,landslideClass: null == landslideClass ? _self.landslideClass : landslideClass // ignore: cast_nullable_to_non_nullable
as int,inStormSurgeZone: null == inStormSurgeZone ? _self.inStormSurgeZone : inStormSurgeZone // ignore: cast_nullable_to_non_nullable
as bool,stormSurgeM: null == stormSurgeM ? _self.stormSurgeM : stormSurgeM // ignore: cast_nullable_to_non_nullable
as double,volcanoClass: null == volcanoClass ? _self.volcanoClass : volcanoClass // ignore: cast_nullable_to_non_nullable
as int,distCoastM: freezed == distCoastM ? _self.distCoastM : distCoastM // ignore: cast_nullable_to_non_nullable
as int?,distRiverM: freezed == distRiverM ? _self.distRiverM : distRiverM // ignore: cast_nullable_to_non_nullable
as int?,denseWood: null == denseWood ? _self.denseWood : denseWood // ignore: cast_nullable_to_non_nullable
as bool,currentElevationM: freezed == currentElevationM ? _self.currentElevationM : currentElevationM // ignore: cast_nullable_to_non_nullable
as double?,graceTime: freezed == graceTime ? _self.graceTime : graceTime // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [HazardContext].
extension HazardContextPatterns on HazardContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HazardContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HazardContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HazardContext value)  $default,){
final _that = this;
switch (_that) {
case _HazardContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HazardContext value)?  $default,){
final _that = this;
switch (_that) {
case _HazardContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool inFloodZone,  double floodDepthM,  bool inTsunamiZone,  double tsunamiDepthM,  int landslideClass,  bool inStormSurgeZone,  double stormSurgeM,  int volcanoClass,  int? distCoastM,  int? distRiverM,  bool denseWood,  double? currentElevationM,  Duration? graceTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HazardContext() when $default != null:
return $default(_that.inFloodZone,_that.floodDepthM,_that.inTsunamiZone,_that.tsunamiDepthM,_that.landslideClass,_that.inStormSurgeZone,_that.stormSurgeM,_that.volcanoClass,_that.distCoastM,_that.distRiverM,_that.denseWood,_that.currentElevationM,_that.graceTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool inFloodZone,  double floodDepthM,  bool inTsunamiZone,  double tsunamiDepthM,  int landslideClass,  bool inStormSurgeZone,  double stormSurgeM,  int volcanoClass,  int? distCoastM,  int? distRiverM,  bool denseWood,  double? currentElevationM,  Duration? graceTime)  $default,) {final _that = this;
switch (_that) {
case _HazardContext():
return $default(_that.inFloodZone,_that.floodDepthM,_that.inTsunamiZone,_that.tsunamiDepthM,_that.landslideClass,_that.inStormSurgeZone,_that.stormSurgeM,_that.volcanoClass,_that.distCoastM,_that.distRiverM,_that.denseWood,_that.currentElevationM,_that.graceTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool inFloodZone,  double floodDepthM,  bool inTsunamiZone,  double tsunamiDepthM,  int landslideClass,  bool inStormSurgeZone,  double stormSurgeM,  int volcanoClass,  int? distCoastM,  int? distRiverM,  bool denseWood,  double? currentElevationM,  Duration? graceTime)?  $default,) {final _that = this;
switch (_that) {
case _HazardContext() when $default != null:
return $default(_that.inFloodZone,_that.floodDepthM,_that.inTsunamiZone,_that.tsunamiDepthM,_that.landslideClass,_that.inStormSurgeZone,_that.stormSurgeM,_that.volcanoClass,_that.distCoastM,_that.distRiverM,_that.denseWood,_that.currentElevationM,_that.graceTime);case _:
  return null;

}
}

}

/// @nodoc


class _HazardContext implements HazardContext {
  const _HazardContext({this.inFloodZone = false, this.floodDepthM = 0, this.inTsunamiZone = false, this.tsunamiDepthM = 0, this.landslideClass = 0, this.inStormSurgeZone = false, this.stormSurgeM = 0, this.volcanoClass = 0, this.distCoastM, this.distRiverM, this.denseWood = false, this.currentElevationM, this.graceTime});
  

@override@JsonKey() final  bool inFloodZone;
@override@JsonKey() final  double floodDepthM;
@override@JsonKey() final  bool inTsunamiZone;
@override@JsonKey() final  double tsunamiDepthM;
/// 0: 区域外 1: 警戒区域 2: 特別警戒区域
@override@JsonKey() final  int landslideClass;
@override@JsonKey() final  bool inStormSurgeZone;
@override@JsonKey() final  double stormSurgeM;
@override@JsonKey() final  int volcanoClass;
@override final  int? distCoastM;
@override final  int? distRiverM;
@override@JsonKey() final  bool denseWood;
@override final  double? currentElevationM;
/// 猶予時間（津波到達想定時間等）。不明なら null。
@override final  Duration? graceTime;

/// Create a copy of HazardContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HazardContextCopyWith<_HazardContext> get copyWith => __$HazardContextCopyWithImpl<_HazardContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HazardContext&&(identical(other.inFloodZone, inFloodZone) || other.inFloodZone == inFloodZone)&&(identical(other.floodDepthM, floodDepthM) || other.floodDepthM == floodDepthM)&&(identical(other.inTsunamiZone, inTsunamiZone) || other.inTsunamiZone == inTsunamiZone)&&(identical(other.tsunamiDepthM, tsunamiDepthM) || other.tsunamiDepthM == tsunamiDepthM)&&(identical(other.landslideClass, landslideClass) || other.landslideClass == landslideClass)&&(identical(other.inStormSurgeZone, inStormSurgeZone) || other.inStormSurgeZone == inStormSurgeZone)&&(identical(other.stormSurgeM, stormSurgeM) || other.stormSurgeM == stormSurgeM)&&(identical(other.volcanoClass, volcanoClass) || other.volcanoClass == volcanoClass)&&(identical(other.distCoastM, distCoastM) || other.distCoastM == distCoastM)&&(identical(other.distRiverM, distRiverM) || other.distRiverM == distRiverM)&&(identical(other.denseWood, denseWood) || other.denseWood == denseWood)&&(identical(other.currentElevationM, currentElevationM) || other.currentElevationM == currentElevationM)&&(identical(other.graceTime, graceTime) || other.graceTime == graceTime));
}


@override
int get hashCode => Object.hash(runtimeType,inFloodZone,floodDepthM,inTsunamiZone,tsunamiDepthM,landslideClass,inStormSurgeZone,stormSurgeM,volcanoClass,distCoastM,distRiverM,denseWood,currentElevationM,graceTime);

@override
String toString() {
  return 'HazardContext(inFloodZone: $inFloodZone, floodDepthM: $floodDepthM, inTsunamiZone: $inTsunamiZone, tsunamiDepthM: $tsunamiDepthM, landslideClass: $landslideClass, inStormSurgeZone: $inStormSurgeZone, stormSurgeM: $stormSurgeM, volcanoClass: $volcanoClass, distCoastM: $distCoastM, distRiverM: $distRiverM, denseWood: $denseWood, currentElevationM: $currentElevationM, graceTime: $graceTime)';
}


}

/// @nodoc
abstract mixin class _$HazardContextCopyWith<$Res> implements $HazardContextCopyWith<$Res> {
  factory _$HazardContextCopyWith(_HazardContext value, $Res Function(_HazardContext) _then) = __$HazardContextCopyWithImpl;
@override @useResult
$Res call({
 bool inFloodZone, double floodDepthM, bool inTsunamiZone, double tsunamiDepthM, int landslideClass, bool inStormSurgeZone, double stormSurgeM, int volcanoClass, int? distCoastM, int? distRiverM, bool denseWood, double? currentElevationM, Duration? graceTime
});




}
/// @nodoc
class __$HazardContextCopyWithImpl<$Res>
    implements _$HazardContextCopyWith<$Res> {
  __$HazardContextCopyWithImpl(this._self, this._then);

  final _HazardContext _self;
  final $Res Function(_HazardContext) _then;

/// Create a copy of HazardContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inFloodZone = null,Object? floodDepthM = null,Object? inTsunamiZone = null,Object? tsunamiDepthM = null,Object? landslideClass = null,Object? inStormSurgeZone = null,Object? stormSurgeM = null,Object? volcanoClass = null,Object? distCoastM = freezed,Object? distRiverM = freezed,Object? denseWood = null,Object? currentElevationM = freezed,Object? graceTime = freezed,}) {
  return _then(_HazardContext(
inFloodZone: null == inFloodZone ? _self.inFloodZone : inFloodZone // ignore: cast_nullable_to_non_nullable
as bool,floodDepthM: null == floodDepthM ? _self.floodDepthM : floodDepthM // ignore: cast_nullable_to_non_nullable
as double,inTsunamiZone: null == inTsunamiZone ? _self.inTsunamiZone : inTsunamiZone // ignore: cast_nullable_to_non_nullable
as bool,tsunamiDepthM: null == tsunamiDepthM ? _self.tsunamiDepthM : tsunamiDepthM // ignore: cast_nullable_to_non_nullable
as double,landslideClass: null == landslideClass ? _self.landslideClass : landslideClass // ignore: cast_nullable_to_non_nullable
as int,inStormSurgeZone: null == inStormSurgeZone ? _self.inStormSurgeZone : inStormSurgeZone // ignore: cast_nullable_to_non_nullable
as bool,stormSurgeM: null == stormSurgeM ? _self.stormSurgeM : stormSurgeM // ignore: cast_nullable_to_non_nullable
as double,volcanoClass: null == volcanoClass ? _self.volcanoClass : volcanoClass // ignore: cast_nullable_to_non_nullable
as int,distCoastM: freezed == distCoastM ? _self.distCoastM : distCoastM // ignore: cast_nullable_to_non_nullable
as int?,distRiverM: freezed == distRiverM ? _self.distRiverM : distRiverM // ignore: cast_nullable_to_non_nullable
as int?,denseWood: null == denseWood ? _self.denseWood : denseWood // ignore: cast_nullable_to_non_nullable
as bool,currentElevationM: freezed == currentElevationM ? _self.currentElevationM : currentElevationM // ignore: cast_nullable_to_non_nullable
as double?,graceTime: freezed == graceTime ? _self.graceTime : graceTime // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
