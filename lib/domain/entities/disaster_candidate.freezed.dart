// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'disaster_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DisasterCandidate {

 DisasterType get type;/// §3.4-a のスコア式による事前確率スコア。
 int get score;/// スコア算出に使ったハザードコンテキスト。
 HazardContext get context;
/// Create a copy of DisasterCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DisasterCandidateCopyWith<DisasterCandidate> get copyWith => _$DisasterCandidateCopyWithImpl<DisasterCandidate>(this as DisasterCandidate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DisasterCandidate&&(identical(other.type, type) || other.type == type)&&(identical(other.score, score) || other.score == score)&&(identical(other.context, context) || other.context == context));
}


@override
int get hashCode => Object.hash(runtimeType,type,score,context);

@override
String toString() {
  return 'DisasterCandidate(type: $type, score: $score, context: $context)';
}


}

/// @nodoc
abstract mixin class $DisasterCandidateCopyWith<$Res>  {
  factory $DisasterCandidateCopyWith(DisasterCandidate value, $Res Function(DisasterCandidate) _then) = _$DisasterCandidateCopyWithImpl;
@useResult
$Res call({
 DisasterType type, int score, HazardContext context
});


$HazardContextCopyWith<$Res> get context;

}
/// @nodoc
class _$DisasterCandidateCopyWithImpl<$Res>
    implements $DisasterCandidateCopyWith<$Res> {
  _$DisasterCandidateCopyWithImpl(this._self, this._then);

  final DisasterCandidate _self;
  final $Res Function(DisasterCandidate) _then;

/// Create a copy of DisasterCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? score = null,Object? context = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DisasterType,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as HazardContext,
  ));
}
/// Create a copy of DisasterCandidate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HazardContextCopyWith<$Res> get context {
  
  return $HazardContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}


/// Adds pattern-matching-related methods to [DisasterCandidate].
extension DisasterCandidatePatterns on DisasterCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DisasterCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DisasterCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DisasterCandidate value)  $default,){
final _that = this;
switch (_that) {
case _DisasterCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DisasterCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _DisasterCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DisasterType type,  int score,  HazardContext context)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DisasterCandidate() when $default != null:
return $default(_that.type,_that.score,_that.context);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DisasterType type,  int score,  HazardContext context)  $default,) {final _that = this;
switch (_that) {
case _DisasterCandidate():
return $default(_that.type,_that.score,_that.context);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DisasterType type,  int score,  HazardContext context)?  $default,) {final _that = this;
switch (_that) {
case _DisasterCandidate() when $default != null:
return $default(_that.type,_that.score,_that.context);case _:
  return null;

}
}

}

/// @nodoc


class _DisasterCandidate implements DisasterCandidate {
  const _DisasterCandidate({required this.type, required this.score, required this.context});
  

@override final  DisasterType type;
/// §3.4-a のスコア式による事前確率スコア。
@override final  int score;
/// スコア算出に使ったハザードコンテキスト。
@override final  HazardContext context;

/// Create a copy of DisasterCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DisasterCandidateCopyWith<_DisasterCandidate> get copyWith => __$DisasterCandidateCopyWithImpl<_DisasterCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DisasterCandidate&&(identical(other.type, type) || other.type == type)&&(identical(other.score, score) || other.score == score)&&(identical(other.context, context) || other.context == context));
}


@override
int get hashCode => Object.hash(runtimeType,type,score,context);

@override
String toString() {
  return 'DisasterCandidate(type: $type, score: $score, context: $context)';
}


}

/// @nodoc
abstract mixin class _$DisasterCandidateCopyWith<$Res> implements $DisasterCandidateCopyWith<$Res> {
  factory _$DisasterCandidateCopyWith(_DisasterCandidate value, $Res Function(_DisasterCandidate) _then) = __$DisasterCandidateCopyWithImpl;
@override @useResult
$Res call({
 DisasterType type, int score, HazardContext context
});


@override $HazardContextCopyWith<$Res> get context;

}
/// @nodoc
class __$DisasterCandidateCopyWithImpl<$Res>
    implements _$DisasterCandidateCopyWith<$Res> {
  __$DisasterCandidateCopyWithImpl(this._self, this._then);

  final _DisasterCandidate _self;
  final $Res Function(_DisasterCandidate) _then;

/// Create a copy of DisasterCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? score = null,Object? context = null,}) {
  return _then(_DisasterCandidate(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DisasterType,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as HazardContext,
  ));
}

/// Create a copy of DisasterCandidate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HazardContextCopyWith<$Res> get context {
  
  return $HazardContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

// dart format on
