// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'environment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Environment {

 PlaceType get place; int? get floor; BuildingType get buildingType; bool get trapped; WaterLevel get waterLevel; bool get canMove;
/// Create a copy of Environment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnvironmentCopyWith<Environment> get copyWith => _$EnvironmentCopyWithImpl<Environment>(this as Environment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Environment&&(identical(other.place, place) || other.place == place)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.buildingType, buildingType) || other.buildingType == buildingType)&&(identical(other.trapped, trapped) || other.trapped == trapped)&&(identical(other.waterLevel, waterLevel) || other.waterLevel == waterLevel)&&(identical(other.canMove, canMove) || other.canMove == canMove));
}


@override
int get hashCode => Object.hash(runtimeType,place,floor,buildingType,trapped,waterLevel,canMove);

@override
String toString() {
  return 'Environment(place: $place, floor: $floor, buildingType: $buildingType, trapped: $trapped, waterLevel: $waterLevel, canMove: $canMove)';
}


}

/// @nodoc
abstract mixin class $EnvironmentCopyWith<$Res>  {
  factory $EnvironmentCopyWith(Environment value, $Res Function(Environment) _then) = _$EnvironmentCopyWithImpl;
@useResult
$Res call({
 PlaceType place, int? floor, BuildingType buildingType, bool trapped, WaterLevel waterLevel, bool canMove
});




}
/// @nodoc
class _$EnvironmentCopyWithImpl<$Res>
    implements $EnvironmentCopyWith<$Res> {
  _$EnvironmentCopyWithImpl(this._self, this._then);

  final Environment _self;
  final $Res Function(Environment) _then;

/// Create a copy of Environment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? place = null,Object? floor = freezed,Object? buildingType = null,Object? trapped = null,Object? waterLevel = null,Object? canMove = null,}) {
  return _then(_self.copyWith(
place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as PlaceType,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as int?,buildingType: null == buildingType ? _self.buildingType : buildingType // ignore: cast_nullable_to_non_nullable
as BuildingType,trapped: null == trapped ? _self.trapped : trapped // ignore: cast_nullable_to_non_nullable
as bool,waterLevel: null == waterLevel ? _self.waterLevel : waterLevel // ignore: cast_nullable_to_non_nullable
as WaterLevel,canMove: null == canMove ? _self.canMove : canMove // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Environment].
extension EnvironmentPatterns on Environment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Environment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Environment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Environment value)  $default,){
final _that = this;
switch (_that) {
case _Environment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Environment value)?  $default,){
final _that = this;
switch (_that) {
case _Environment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlaceType place,  int? floor,  BuildingType buildingType,  bool trapped,  WaterLevel waterLevel,  bool canMove)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Environment() when $default != null:
return $default(_that.place,_that.floor,_that.buildingType,_that.trapped,_that.waterLevel,_that.canMove);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlaceType place,  int? floor,  BuildingType buildingType,  bool trapped,  WaterLevel waterLevel,  bool canMove)  $default,) {final _that = this;
switch (_that) {
case _Environment():
return $default(_that.place,_that.floor,_that.buildingType,_that.trapped,_that.waterLevel,_that.canMove);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlaceType place,  int? floor,  BuildingType buildingType,  bool trapped,  WaterLevel waterLevel,  bool canMove)?  $default,) {final _that = this;
switch (_that) {
case _Environment() when $default != null:
return $default(_that.place,_that.floor,_that.buildingType,_that.trapped,_that.waterLevel,_that.canMove);case _:
  return null;

}
}

}

/// @nodoc


class _Environment implements Environment {
  const _Environment({this.place = PlaceType.unknown, this.floor, this.buildingType = BuildingType.unknown, this.trapped = false, this.waterLevel = WaterLevel.unknown, this.canMove = true});


@override@JsonKey() final  PlaceType place;
@override final  int? floor;
@override@JsonKey() final  BuildingType buildingType;
@override@JsonKey() final  bool trapped;
@override@JsonKey() final  WaterLevel waterLevel;
@override@JsonKey() final  bool canMove;

/// Create a copy of Environment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnvironmentCopyWith<_Environment> get copyWith => __$EnvironmentCopyWithImpl<_Environment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Environment&&(identical(other.place, place) || other.place == place)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.buildingType, buildingType) || other.buildingType == buildingType)&&(identical(other.trapped, trapped) || other.trapped == trapped)&&(identical(other.waterLevel, waterLevel) || other.waterLevel == waterLevel)&&(identical(other.canMove, canMove) || other.canMove == canMove));
}


@override
int get hashCode => Object.hash(runtimeType,place,floor,buildingType,trapped,waterLevel,canMove);

@override
String toString() {
  return 'Environment(place: $place, floor: $floor, buildingType: $buildingType, trapped: $trapped, waterLevel: $waterLevel, canMove: $canMove)';
}


}

/// @nodoc
abstract mixin class _$EnvironmentCopyWith<$Res> implements $EnvironmentCopyWith<$Res> {
  factory _$EnvironmentCopyWith(_Environment value, $Res Function(_Environment) _then) = __$EnvironmentCopyWithImpl;
@override @useResult
$Res call({
 PlaceType place, int? floor, BuildingType buildingType, bool trapped, WaterLevel waterLevel, bool canMove
});




}
/// @nodoc
class __$EnvironmentCopyWithImpl<$Res>
    implements _$EnvironmentCopyWith<$Res> {
  __$EnvironmentCopyWithImpl(this._self, this._then);

  final _Environment _self;
  final $Res Function(_Environment) _then;

/// Create a copy of Environment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? place = null,Object? floor = freezed,Object? buildingType = null,Object? trapped = null,Object? waterLevel = null,Object? canMove = null,}) {
  return _then(_Environment(
place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as PlaceType,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as int?,buildingType: null == buildingType ? _self.buildingType : buildingType // ignore: cast_nullable_to_non_nullable
as BuildingType,trapped: null == trapped ? _self.trapped : trapped // ignore: cast_nullable_to_non_nullable
as bool,waterLevel: null == waterLevel ? _self.waterLevel : waterLevel // ignore: cast_nullable_to_non_nullable
as WaterLevel,canMove: null == canMove ? _self.canMove : canMove // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
