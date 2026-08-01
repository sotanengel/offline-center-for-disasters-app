// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'situation_slots.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SituationSlots {

 Intent get intent; DisasterType get disasterType;/// 災害種別の根拠語句。空文字ならユーザー確認が必須（§3.7）
 String get disasterTypeEvidence; Urgency get urgency; UserState get userState; Environment get environment; List<String> get guideTags;/// tile / ai / rule / manual
 SlotSource get source;
/// Create a copy of SituationSlots
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SituationSlotsCopyWith<SituationSlots> get copyWith => _$SituationSlotsCopyWithImpl<SituationSlots>(this as SituationSlots, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SituationSlots&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.disasterType, disasterType) || other.disasterType == disasterType)&&(identical(other.disasterTypeEvidence, disasterTypeEvidence) || other.disasterTypeEvidence == disasterTypeEvidence)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.userState, userState) || other.userState == userState)&&(identical(other.environment, environment) || other.environment == environment)&&const DeepCollectionEquality().equals(other.guideTags, guideTags)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,intent,disasterType,disasterTypeEvidence,urgency,userState,environment,const DeepCollectionEquality().hash(guideTags),source);

@override
String toString() {
  return 'SituationSlots(intent: $intent, disasterType: $disasterType, disasterTypeEvidence: $disasterTypeEvidence, urgency: $urgency, userState: $userState, environment: $environment, guideTags: $guideTags, source: $source)';
}


}

/// @nodoc
abstract mixin class $SituationSlotsCopyWith<$Res>  {
  factory $SituationSlotsCopyWith(SituationSlots value, $Res Function(SituationSlots) _then) = _$SituationSlotsCopyWithImpl;
@useResult
$Res call({
 Intent intent, DisasterType disasterType, String disasterTypeEvidence, Urgency urgency, UserState userState, Environment environment, List<String> guideTags, SlotSource source
});


$UserStateCopyWith<$Res> get userState;$EnvironmentCopyWith<$Res> get environment;

}
/// @nodoc
class _$SituationSlotsCopyWithImpl<$Res>
    implements $SituationSlotsCopyWith<$Res> {
  _$SituationSlotsCopyWithImpl(this._self, this._then);

  final SituationSlots _self;
  final $Res Function(SituationSlots) _then;

/// Create a copy of SituationSlots
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intent = null,Object? disasterType = null,Object? disasterTypeEvidence = null,Object? urgency = null,Object? userState = null,Object? environment = null,Object? guideTags = null,Object? source = null,}) {
  return _then(_self.copyWith(
intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as Intent,disasterType: null == disasterType ? _self.disasterType : disasterType // ignore: cast_nullable_to_non_nullable
as DisasterType,disasterTypeEvidence: null == disasterTypeEvidence ? _self.disasterTypeEvidence : disasterTypeEvidence // ignore: cast_nullable_to_non_nullable
as String,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as Urgency,userState: null == userState ? _self.userState : userState // ignore: cast_nullable_to_non_nullable
as UserState,environment: null == environment ? _self.environment : environment // ignore: cast_nullable_to_non_nullable
as Environment,guideTags: null == guideTags ? _self.guideTags : guideTags // ignore: cast_nullable_to_non_nullable
as List<String>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SlotSource,
  ));
}
/// Create a copy of SituationSlots
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserStateCopyWith<$Res> get userState {
  
  return $UserStateCopyWith<$Res>(_self.userState, (value) {
    return _then(_self.copyWith(userState: value));
  });
}/// Create a copy of SituationSlots
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnvironmentCopyWith<$Res> get environment {
  
  return $EnvironmentCopyWith<$Res>(_self.environment, (value) {
    return _then(_self.copyWith(environment: value));
  });
}
}


/// Adds pattern-matching-related methods to [SituationSlots].
extension SituationSlotsPatterns on SituationSlots {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SituationSlots value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SituationSlots() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SituationSlots value)  $default,){
final _that = this;
switch (_that) {
case _SituationSlots():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SituationSlots value)?  $default,){
final _that = this;
switch (_that) {
case _SituationSlots() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Intent intent,  DisasterType disasterType,  String disasterTypeEvidence,  Urgency urgency,  UserState userState,  Environment environment,  List<String> guideTags,  SlotSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SituationSlots() when $default != null:
return $default(_that.intent,_that.disasterType,_that.disasterTypeEvidence,_that.urgency,_that.userState,_that.environment,_that.guideTags,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Intent intent,  DisasterType disasterType,  String disasterTypeEvidence,  Urgency urgency,  UserState userState,  Environment environment,  List<String> guideTags,  SlotSource source)  $default,) {final _that = this;
switch (_that) {
case _SituationSlots():
return $default(_that.intent,_that.disasterType,_that.disasterTypeEvidence,_that.urgency,_that.userState,_that.environment,_that.guideTags,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Intent intent,  DisasterType disasterType,  String disasterTypeEvidence,  Urgency urgency,  UserState userState,  Environment environment,  List<String> guideTags,  SlotSource source)?  $default,) {final _that = this;
switch (_that) {
case _SituationSlots() when $default != null:
return $default(_that.intent,_that.disasterType,_that.disasterTypeEvidence,_that.urgency,_that.userState,_that.environment,_that.guideTags,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _SituationSlots extends SituationSlots {
  const _SituationSlots({this.intent = Intent.unknown, this.disasterType = DisasterType.unknown, this.disasterTypeEvidence = '', this.urgency = Urgency.unknown, this.userState = const UserState(), this.environment = const Environment(), final  List<String> guideTags = const <String>[], this.source = SlotSource.tile}): _guideTags = guideTags,super._();
  

@override@JsonKey() final  Intent intent;
@override@JsonKey() final  DisasterType disasterType;
/// 災害種別の根拠語句。空文字ならユーザー確認が必須（§3.7）
@override@JsonKey() final  String disasterTypeEvidence;
@override@JsonKey() final  Urgency urgency;
@override@JsonKey() final  UserState userState;
@override@JsonKey() final  Environment environment;
 final  List<String> _guideTags;
@override@JsonKey() List<String> get guideTags {
  if (_guideTags is EqualUnmodifiableListView) return _guideTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guideTags);
}

/// tile / ai / rule / manual
@override@JsonKey() final  SlotSource source;

/// Create a copy of SituationSlots
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SituationSlotsCopyWith<_SituationSlots> get copyWith => __$SituationSlotsCopyWithImpl<_SituationSlots>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SituationSlots&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.disasterType, disasterType) || other.disasterType == disasterType)&&(identical(other.disasterTypeEvidence, disasterTypeEvidence) || other.disasterTypeEvidence == disasterTypeEvidence)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.userState, userState) || other.userState == userState)&&(identical(other.environment, environment) || other.environment == environment)&&const DeepCollectionEquality().equals(other._guideTags, _guideTags)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,intent,disasterType,disasterTypeEvidence,urgency,userState,environment,const DeepCollectionEquality().hash(_guideTags),source);

@override
String toString() {
  return 'SituationSlots(intent: $intent, disasterType: $disasterType, disasterTypeEvidence: $disasterTypeEvidence, urgency: $urgency, userState: $userState, environment: $environment, guideTags: $guideTags, source: $source)';
}


}

/// @nodoc
abstract mixin class _$SituationSlotsCopyWith<$Res> implements $SituationSlotsCopyWith<$Res> {
  factory _$SituationSlotsCopyWith(_SituationSlots value, $Res Function(_SituationSlots) _then) = __$SituationSlotsCopyWithImpl;
@override @useResult
$Res call({
 Intent intent, DisasterType disasterType, String disasterTypeEvidence, Urgency urgency, UserState userState, Environment environment, List<String> guideTags, SlotSource source
});


@override $UserStateCopyWith<$Res> get userState;@override $EnvironmentCopyWith<$Res> get environment;

}
/// @nodoc
class __$SituationSlotsCopyWithImpl<$Res>
    implements _$SituationSlotsCopyWith<$Res> {
  __$SituationSlotsCopyWithImpl(this._self, this._then);

  final _SituationSlots _self;
  final $Res Function(_SituationSlots) _then;

/// Create a copy of SituationSlots
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intent = null,Object? disasterType = null,Object? disasterTypeEvidence = null,Object? urgency = null,Object? userState = null,Object? environment = null,Object? guideTags = null,Object? source = null,}) {
  return _then(_SituationSlots(
intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as Intent,disasterType: null == disasterType ? _self.disasterType : disasterType // ignore: cast_nullable_to_non_nullable
as DisasterType,disasterTypeEvidence: null == disasterTypeEvidence ? _self.disasterTypeEvidence : disasterTypeEvidence // ignore: cast_nullable_to_non_nullable
as String,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as Urgency,userState: null == userState ? _self.userState : userState // ignore: cast_nullable_to_non_nullable
as UserState,environment: null == environment ? _self.environment : environment // ignore: cast_nullable_to_non_nullable
as Environment,guideTags: null == guideTags ? _self._guideTags : guideTags // ignore: cast_nullable_to_non_nullable
as List<String>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SlotSource,
  ));
}

/// Create a copy of SituationSlots
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserStateCopyWith<$Res> get userState {
  
  return $UserStateCopyWith<$Res>(_self.userState, (value) {
    return _then(_self.copyWith(userState: value));
  });
}/// Create a copy of SituationSlots
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnvironmentCopyWith<$Res> get environment {
  
  return $EnvironmentCopyWith<$Res>(_self.environment, (value) {
    return _then(_self.copyWith(environment: value));
  });
}
}

// dart format on
