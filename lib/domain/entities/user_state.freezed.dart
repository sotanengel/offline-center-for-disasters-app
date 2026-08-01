// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserState {

 bool get injured; Mobility get mobility; int get groupSize; bool get hasInfant; bool get hasPet;
/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserStateCopyWith<UserState> get copyWith => _$UserStateCopyWithImpl<UserState>(this as UserState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserState&&(identical(other.injured, injured) || other.injured == injured)&&(identical(other.mobility, mobility) || other.mobility == mobility)&&(identical(other.groupSize, groupSize) || other.groupSize == groupSize)&&(identical(other.hasInfant, hasInfant) || other.hasInfant == hasInfant)&&(identical(other.hasPet, hasPet) || other.hasPet == hasPet));
}


@override
int get hashCode => Object.hash(runtimeType,injured,mobility,groupSize,hasInfant,hasPet);

@override
String toString() {
  return 'UserState(injured: $injured, mobility: $mobility, groupSize: $groupSize, hasInfant: $hasInfant, hasPet: $hasPet)';
}


}

/// @nodoc
abstract mixin class $UserStateCopyWith<$Res>  {
  factory $UserStateCopyWith(UserState value, $Res Function(UserState) _then) = _$UserStateCopyWithImpl;
@useResult
$Res call({
 bool injured, Mobility mobility, int groupSize, bool hasInfant, bool hasPet
});




}
/// @nodoc
class _$UserStateCopyWithImpl<$Res>
    implements $UserStateCopyWith<$Res> {
  _$UserStateCopyWithImpl(this._self, this._then);

  final UserState _self;
  final $Res Function(UserState) _then;

/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? injured = null,Object? mobility = null,Object? groupSize = null,Object? hasInfant = null,Object? hasPet = null,}) {
  return _then(_self.copyWith(
injured: null == injured ? _self.injured : injured // ignore: cast_nullable_to_non_nullable
as bool,mobility: null == mobility ? _self.mobility : mobility // ignore: cast_nullable_to_non_nullable
as Mobility,groupSize: null == groupSize ? _self.groupSize : groupSize // ignore: cast_nullable_to_non_nullable
as int,hasInfant: null == hasInfant ? _self.hasInfant : hasInfant // ignore: cast_nullable_to_non_nullable
as bool,hasPet: null == hasPet ? _self.hasPet : hasPet // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserState].
extension UserStatePatterns on UserState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserState value)  $default,){
final _that = this;
switch (_that) {
case _UserState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserState value)?  $default,){
final _that = this;
switch (_that) {
case _UserState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool injured,  Mobility mobility,  int groupSize,  bool hasInfant,  bool hasPet)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserState() when $default != null:
return $default(_that.injured,_that.mobility,_that.groupSize,_that.hasInfant,_that.hasPet);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool injured,  Mobility mobility,  int groupSize,  bool hasInfant,  bool hasPet)  $default,) {final _that = this;
switch (_that) {
case _UserState():
return $default(_that.injured,_that.mobility,_that.groupSize,_that.hasInfant,_that.hasPet);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool injured,  Mobility mobility,  int groupSize,  bool hasInfant,  bool hasPet)?  $default,) {final _that = this;
switch (_that) {
case _UserState() when $default != null:
return $default(_that.injured,_that.mobility,_that.groupSize,_that.hasInfant,_that.hasPet);case _:
  return null;

}
}

}

/// @nodoc


class _UserState implements UserState {
  const _UserState({this.injured = false, this.mobility = Mobility.normal, this.groupSize = 1, this.hasInfant = false, this.hasPet = false});


@override@JsonKey() final  bool injured;
@override@JsonKey() final  Mobility mobility;
@override@JsonKey() final  int groupSize;
@override@JsonKey() final  bool hasInfant;
@override@JsonKey() final  bool hasPet;

/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserStateCopyWith<_UserState> get copyWith => __$UserStateCopyWithImpl<_UserState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserState&&(identical(other.injured, injured) || other.injured == injured)&&(identical(other.mobility, mobility) || other.mobility == mobility)&&(identical(other.groupSize, groupSize) || other.groupSize == groupSize)&&(identical(other.hasInfant, hasInfant) || other.hasInfant == hasInfant)&&(identical(other.hasPet, hasPet) || other.hasPet == hasPet));
}


@override
int get hashCode => Object.hash(runtimeType,injured,mobility,groupSize,hasInfant,hasPet);

@override
String toString() {
  return 'UserState(injured: $injured, mobility: $mobility, groupSize: $groupSize, hasInfant: $hasInfant, hasPet: $hasPet)';
}


}

/// @nodoc
abstract mixin class _$UserStateCopyWith<$Res> implements $UserStateCopyWith<$Res> {
  factory _$UserStateCopyWith(_UserState value, $Res Function(_UserState) _then) = __$UserStateCopyWithImpl;
@override @useResult
$Res call({
 bool injured, Mobility mobility, int groupSize, bool hasInfant, bool hasPet
});




}
/// @nodoc
class __$UserStateCopyWithImpl<$Res>
    implements _$UserStateCopyWith<$Res> {
  __$UserStateCopyWithImpl(this._self, this._then);

  final _UserState _self;
  final $Res Function(_UserState) _then;

/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? injured = null,Object? mobility = null,Object? groupSize = null,Object? hasInfant = null,Object? hasPet = null,}) {
  return _then(_UserState(
injured: null == injured ? _self.injured : injured // ignore: cast_nullable_to_non_nullable
as bool,mobility: null == mobility ? _self.mobility : mobility // ignore: cast_nullable_to_non_nullable
as Mobility,groupSize: null == groupSize ? _self.groupSize : groupSize // ignore: cast_nullable_to_non_nullable
as int,hasInfant: null == hasInfant ? _self.hasInfant : hasInfant // ignore: cast_nullable_to_non_nullable
as bool,hasPet: null == hasPet ? _self.hasPet : hasPet // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
