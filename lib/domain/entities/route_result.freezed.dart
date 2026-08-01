// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TurnInstruction {

 TurnKind get kind;/// 直進系指示での距離 [m]。
 double get distanceM;/// §9.3: 曲がり角のランドマーク（あれば文言に使う）
 String? get landmarkName;/// 表示・読み上げ用テキスト（例: "300m 直進", "〇〇神社を右折"）
 String get text;
/// Create a copy of TurnInstruction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnInstructionCopyWith<TurnInstruction> get copyWith => _$TurnInstructionCopyWithImpl<TurnInstruction>(this as TurnInstruction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnInstruction&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.landmarkName, landmarkName) || other.landmarkName == landmarkName)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,kind,distanceM,landmarkName,text);

@override
String toString() {
  return 'TurnInstruction(kind: $kind, distanceM: $distanceM, landmarkName: $landmarkName, text: $text)';
}


}

/// @nodoc
abstract mixin class $TurnInstructionCopyWith<$Res>  {
  factory $TurnInstructionCopyWith(TurnInstruction value, $Res Function(TurnInstruction) _then) = _$TurnInstructionCopyWithImpl;
@useResult
$Res call({
 TurnKind kind, double distanceM, String? landmarkName, String text
});




}
/// @nodoc
class _$TurnInstructionCopyWithImpl<$Res>
    implements $TurnInstructionCopyWith<$Res> {
  _$TurnInstructionCopyWithImpl(this._self, this._then);

  final TurnInstruction _self;
  final $Res Function(TurnInstruction) _then;

/// Create a copy of TurnInstruction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? distanceM = null,Object? landmarkName = freezed,Object? text = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TurnKind,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as double,landmarkName: freezed == landmarkName ? _self.landmarkName : landmarkName // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TurnInstruction].
extension TurnInstructionPatterns on TurnInstruction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TurnInstruction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TurnInstruction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TurnInstruction value)  $default,){
final _that = this;
switch (_that) {
case _TurnInstruction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TurnInstruction value)?  $default,){
final _that = this;
switch (_that) {
case _TurnInstruction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TurnKind kind,  double distanceM,  String? landmarkName,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TurnInstruction() when $default != null:
return $default(_that.kind,_that.distanceM,_that.landmarkName,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TurnKind kind,  double distanceM,  String? landmarkName,  String text)  $default,) {final _that = this;
switch (_that) {
case _TurnInstruction():
return $default(_that.kind,_that.distanceM,_that.landmarkName,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TurnKind kind,  double distanceM,  String? landmarkName,  String text)?  $default,) {final _that = this;
switch (_that) {
case _TurnInstruction() when $default != null:
return $default(_that.kind,_that.distanceM,_that.landmarkName,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _TurnInstruction implements TurnInstruction {
  const _TurnInstruction({required this.kind, this.distanceM = 0, this.landmarkName, required this.text});
  

@override final  TurnKind kind;
/// 直進系指示での距離 [m]。
@override@JsonKey() final  double distanceM;
/// §9.3: 曲がり角のランドマーク（あれば文言に使う）
@override final  String? landmarkName;
/// 表示・読み上げ用テキスト（例: "300m 直進", "〇〇神社を右折"）
@override final  String text;

/// Create a copy of TurnInstruction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TurnInstructionCopyWith<_TurnInstruction> get copyWith => __$TurnInstructionCopyWithImpl<_TurnInstruction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TurnInstruction&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.landmarkName, landmarkName) || other.landmarkName == landmarkName)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,kind,distanceM,landmarkName,text);

@override
String toString() {
  return 'TurnInstruction(kind: $kind, distanceM: $distanceM, landmarkName: $landmarkName, text: $text)';
}


}

/// @nodoc
abstract mixin class _$TurnInstructionCopyWith<$Res> implements $TurnInstructionCopyWith<$Res> {
  factory _$TurnInstructionCopyWith(_TurnInstruction value, $Res Function(_TurnInstruction) _then) = __$TurnInstructionCopyWithImpl;
@override @useResult
$Res call({
 TurnKind kind, double distanceM, String? landmarkName, String text
});




}
/// @nodoc
class __$TurnInstructionCopyWithImpl<$Res>
    implements _$TurnInstructionCopyWith<$Res> {
  __$TurnInstructionCopyWithImpl(this._self, this._then);

  final _TurnInstruction _self;
  final $Res Function(_TurnInstruction) _then;

/// Create a copy of TurnInstruction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? distanceM = null,Object? landmarkName = freezed,Object? text = null,}) {
  return _then(_TurnInstruction(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TurnKind,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as double,landmarkName: freezed == landmarkName ? _self.landmarkName : landmarkName // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RouteResult {

/// 避難所 ID（Shelter.id）
 String get targetId;/// §9.2 コスト式による到達コスト [秒]
 double get costSeconds; double get distanceM;/// 経路ポリライン（開始地点→避難所、向き済み）
 List<GeoPoint> get polyline; List<TurnInstruction> get instructions;
/// Create a copy of RouteResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteResultCopyWith<RouteResult> get copyWith => _$RouteResultCopyWithImpl<RouteResult>(this as RouteResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteResult&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.costSeconds, costSeconds) || other.costSeconds == costSeconds)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&const DeepCollectionEquality().equals(other.polyline, polyline)&&const DeepCollectionEquality().equals(other.instructions, instructions));
}


@override
int get hashCode => Object.hash(runtimeType,targetId,costSeconds,distanceM,const DeepCollectionEquality().hash(polyline),const DeepCollectionEquality().hash(instructions));

@override
String toString() {
  return 'RouteResult(targetId: $targetId, costSeconds: $costSeconds, distanceM: $distanceM, polyline: $polyline, instructions: $instructions)';
}


}

/// @nodoc
abstract mixin class $RouteResultCopyWith<$Res>  {
  factory $RouteResultCopyWith(RouteResult value, $Res Function(RouteResult) _then) = _$RouteResultCopyWithImpl;
@useResult
$Res call({
 String targetId, double costSeconds, double distanceM, List<GeoPoint> polyline, List<TurnInstruction> instructions
});




}
/// @nodoc
class _$RouteResultCopyWithImpl<$Res>
    implements $RouteResultCopyWith<$Res> {
  _$RouteResultCopyWithImpl(this._self, this._then);

  final RouteResult _self;
  final $Res Function(RouteResult) _then;

/// Create a copy of RouteResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetId = null,Object? costSeconds = null,Object? distanceM = null,Object? polyline = null,Object? instructions = null,}) {
  return _then(_self.copyWith(
targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,costSeconds: null == costSeconds ? _self.costSeconds : costSeconds // ignore: cast_nullable_to_non_nullable
as double,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as double,polyline: null == polyline ? _self.polyline : polyline // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as List<TurnInstruction>,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteResult].
extension RouteResultPatterns on RouteResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteResult value)  $default,){
final _that = this;
switch (_that) {
case _RouteResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteResult value)?  $default,){
final _that = this;
switch (_that) {
case _RouteResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String targetId,  double costSeconds,  double distanceM,  List<GeoPoint> polyline,  List<TurnInstruction> instructions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteResult() when $default != null:
return $default(_that.targetId,_that.costSeconds,_that.distanceM,_that.polyline,_that.instructions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String targetId,  double costSeconds,  double distanceM,  List<GeoPoint> polyline,  List<TurnInstruction> instructions)  $default,) {final _that = this;
switch (_that) {
case _RouteResult():
return $default(_that.targetId,_that.costSeconds,_that.distanceM,_that.polyline,_that.instructions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String targetId,  double costSeconds,  double distanceM,  List<GeoPoint> polyline,  List<TurnInstruction> instructions)?  $default,) {final _that = this;
switch (_that) {
case _RouteResult() when $default != null:
return $default(_that.targetId,_that.costSeconds,_that.distanceM,_that.polyline,_that.instructions);case _:
  return null;

}
}

}

/// @nodoc


class _RouteResult implements RouteResult {
  const _RouteResult({required this.targetId, required this.costSeconds, required this.distanceM, final  List<GeoPoint> polyline = const <GeoPoint>[], final  List<TurnInstruction> instructions = const <TurnInstruction>[]}): _polyline = polyline,_instructions = instructions;
  

/// 避難所 ID（Shelter.id）
@override final  String targetId;
/// §9.2 コスト式による到達コスト [秒]
@override final  double costSeconds;
@override final  double distanceM;
/// 経路ポリライン（開始地点→避難所、向き済み）
 final  List<GeoPoint> _polyline;
/// 経路ポリライン（開始地点→避難所、向き済み）
@override@JsonKey() List<GeoPoint> get polyline {
  if (_polyline is EqualUnmodifiableListView) return _polyline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_polyline);
}

 final  List<TurnInstruction> _instructions;
@override@JsonKey() List<TurnInstruction> get instructions {
  if (_instructions is EqualUnmodifiableListView) return _instructions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instructions);
}


/// Create a copy of RouteResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteResultCopyWith<_RouteResult> get copyWith => __$RouteResultCopyWithImpl<_RouteResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteResult&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.costSeconds, costSeconds) || other.costSeconds == costSeconds)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&const DeepCollectionEquality().equals(other._polyline, _polyline)&&const DeepCollectionEquality().equals(other._instructions, _instructions));
}


@override
int get hashCode => Object.hash(runtimeType,targetId,costSeconds,distanceM,const DeepCollectionEquality().hash(_polyline),const DeepCollectionEquality().hash(_instructions));

@override
String toString() {
  return 'RouteResult(targetId: $targetId, costSeconds: $costSeconds, distanceM: $distanceM, polyline: $polyline, instructions: $instructions)';
}


}

/// @nodoc
abstract mixin class _$RouteResultCopyWith<$Res> implements $RouteResultCopyWith<$Res> {
  factory _$RouteResultCopyWith(_RouteResult value, $Res Function(_RouteResult) _then) = __$RouteResultCopyWithImpl;
@override @useResult
$Res call({
 String targetId, double costSeconds, double distanceM, List<GeoPoint> polyline, List<TurnInstruction> instructions
});




}
/// @nodoc
class __$RouteResultCopyWithImpl<$Res>
    implements _$RouteResultCopyWith<$Res> {
  __$RouteResultCopyWithImpl(this._self, this._then);

  final _RouteResult _self;
  final $Res Function(_RouteResult) _then;

/// Create a copy of RouteResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetId = null,Object? costSeconds = null,Object? distanceM = null,Object? polyline = null,Object? instructions = null,}) {
  return _then(_RouteResult(
targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,costSeconds: null == costSeconds ? _self.costSeconds : costSeconds // ignore: cast_nullable_to_non_nullable
as double,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as double,polyline: null == polyline ? _self._polyline : polyline // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,instructions: null == instructions ? _self._instructions : instructions // ignore: cast_nullable_to_non_nullable
as List<TurnInstruction>,
  ));
}


}

// dart format on
