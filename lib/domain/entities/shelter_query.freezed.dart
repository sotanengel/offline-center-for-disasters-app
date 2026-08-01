// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shelter_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShelterQuery {

 DisasterType get disasterType;/// 津波: 想定浸水深 + 5m（§4.2 required_elevation_m）
 double get minElevationM;/// 初期探索半径 [km]（§4.4: 0 件なら 10km に拡大）
 double get radiusKm;
/// Create a copy of ShelterQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShelterQueryCopyWith<ShelterQuery> get copyWith => _$ShelterQueryCopyWithImpl<ShelterQuery>(this as ShelterQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShelterQuery&&(identical(other.disasterType, disasterType) || other.disasterType == disasterType)&&(identical(other.minElevationM, minElevationM) || other.minElevationM == minElevationM)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm));
}


@override
int get hashCode => Object.hash(runtimeType,disasterType,minElevationM,radiusKm);

@override
String toString() {
  return 'ShelterQuery(disasterType: $disasterType, minElevationM: $minElevationM, radiusKm: $radiusKm)';
}


}

/// @nodoc
abstract mixin class $ShelterQueryCopyWith<$Res>  {
  factory $ShelterQueryCopyWith(ShelterQuery value, $Res Function(ShelterQuery) _then) = _$ShelterQueryCopyWithImpl;
@useResult
$Res call({
 DisasterType disasterType, double minElevationM, double radiusKm
});




}
/// @nodoc
class _$ShelterQueryCopyWithImpl<$Res>
    implements $ShelterQueryCopyWith<$Res> {
  _$ShelterQueryCopyWithImpl(this._self, this._then);

  final ShelterQuery _self;
  final $Res Function(ShelterQuery) _then;

/// Create a copy of ShelterQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? disasterType = null,Object? minElevationM = null,Object? radiusKm = null,}) {
  return _then(_self.copyWith(
disasterType: null == disasterType ? _self.disasterType : disasterType // ignore: cast_nullable_to_non_nullable
as DisasterType,minElevationM: null == minElevationM ? _self.minElevationM : minElevationM // ignore: cast_nullable_to_non_nullable
as double,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ShelterQuery].
extension ShelterQueryPatterns on ShelterQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShelterQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShelterQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShelterQuery value)  $default,){
final _that = this;
switch (_that) {
case _ShelterQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShelterQuery value)?  $default,){
final _that = this;
switch (_that) {
case _ShelterQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DisasterType disasterType,  double minElevationM,  double radiusKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShelterQuery() when $default != null:
return $default(_that.disasterType,_that.minElevationM,_that.radiusKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DisasterType disasterType,  double minElevationM,  double radiusKm)  $default,) {final _that = this;
switch (_that) {
case _ShelterQuery():
return $default(_that.disasterType,_that.minElevationM,_that.radiusKm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DisasterType disasterType,  double minElevationM,  double radiusKm)?  $default,) {final _that = this;
switch (_that) {
case _ShelterQuery() when $default != null:
return $default(_that.disasterType,_that.minElevationM,_that.radiusKm);case _:
  return null;

}
}

}

/// @nodoc


class _ShelterQuery extends ShelterQuery {
  const _ShelterQuery({required this.disasterType, this.minElevationM = 0, this.radiusKm = 3.0}): super._();
  

@override final  DisasterType disasterType;
/// 津波: 想定浸水深 + 5m（§4.2 required_elevation_m）
@override@JsonKey() final  double minElevationM;
/// 初期探索半径 [km]（§4.4: 0 件なら 10km に拡大）
@override@JsonKey() final  double radiusKm;

/// Create a copy of ShelterQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShelterQueryCopyWith<_ShelterQuery> get copyWith => __$ShelterQueryCopyWithImpl<_ShelterQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShelterQuery&&(identical(other.disasterType, disasterType) || other.disasterType == disasterType)&&(identical(other.minElevationM, minElevationM) || other.minElevationM == minElevationM)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm));
}


@override
int get hashCode => Object.hash(runtimeType,disasterType,minElevationM,radiusKm);

@override
String toString() {
  return 'ShelterQuery(disasterType: $disasterType, minElevationM: $minElevationM, radiusKm: $radiusKm)';
}


}

/// @nodoc
abstract mixin class _$ShelterQueryCopyWith<$Res> implements $ShelterQueryCopyWith<$Res> {
  factory _$ShelterQueryCopyWith(_ShelterQuery value, $Res Function(_ShelterQuery) _then) = __$ShelterQueryCopyWithImpl;
@override @useResult
$Res call({
 DisasterType disasterType, double minElevationM, double radiusKm
});




}
/// @nodoc
class __$ShelterQueryCopyWithImpl<$Res>
    implements _$ShelterQueryCopyWith<$Res> {
  __$ShelterQueryCopyWithImpl(this._self, this._then);

  final _ShelterQuery _self;
  final $Res Function(_ShelterQuery) _then;

/// Create a copy of ShelterQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? disasterType = null,Object? minElevationM = null,Object? radiusKm = null,}) {
  return _then(_ShelterQuery(
disasterType: null == disasterType ? _self.disasterType : disasterType // ignore: cast_nullable_to_non_nullable
as DisasterType,minElevationM: null == minElevationM ? _self.minElevationM : minElevationM // ignore: cast_nullable_to_non_nullable
as double,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
