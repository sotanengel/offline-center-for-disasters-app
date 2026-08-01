// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteSearchResult {

/// Shelter.id → 経路。到達不能・タイムアウトで未発見のものは含まない。
 Map<String, RouteResult> get routes;/// タイムアウトで打ち切られたか。true でも routes は途中経過を含む。
 bool get timedOut;
/// Create a copy of RouteSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteSearchResultCopyWith<RouteSearchResult> get copyWith => _$RouteSearchResultCopyWithImpl<RouteSearchResult>(this as RouteSearchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteSearchResult&&const DeepCollectionEquality().equals(other.routes, routes)&&(identical(other.timedOut, timedOut) || other.timedOut == timedOut));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(routes),timedOut);

@override
String toString() {
  return 'RouteSearchResult(routes: $routes, timedOut: $timedOut)';
}


}

/// @nodoc
abstract mixin class $RouteSearchResultCopyWith<$Res>  {
  factory $RouteSearchResultCopyWith(RouteSearchResult value, $Res Function(RouteSearchResult) _then) = _$RouteSearchResultCopyWithImpl;
@useResult
$Res call({
 Map<String, RouteResult> routes, bool timedOut
});




}
/// @nodoc
class _$RouteSearchResultCopyWithImpl<$Res>
    implements $RouteSearchResultCopyWith<$Res> {
  _$RouteSearchResultCopyWithImpl(this._self, this._then);

  final RouteSearchResult _self;
  final $Res Function(RouteSearchResult) _then;

/// Create a copy of RouteSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? routes = null,Object? timedOut = null,}) {
  return _then(_self.copyWith(
routes: null == routes ? _self.routes : routes // ignore: cast_nullable_to_non_nullable
as Map<String, RouteResult>,timedOut: null == timedOut ? _self.timedOut : timedOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteSearchResult].
extension RouteSearchResultPatterns on RouteSearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteSearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteSearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteSearchResult value)  $default,){
final _that = this;
switch (_that) {
case _RouteSearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteSearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _RouteSearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, RouteResult> routes,  bool timedOut)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteSearchResult() when $default != null:
return $default(_that.routes,_that.timedOut);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, RouteResult> routes,  bool timedOut)  $default,) {final _that = this;
switch (_that) {
case _RouteSearchResult():
return $default(_that.routes,_that.timedOut);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, RouteResult> routes,  bool timedOut)?  $default,) {final _that = this;
switch (_that) {
case _RouteSearchResult() when $default != null:
return $default(_that.routes,_that.timedOut);case _:
  return null;

}
}

}

/// @nodoc


class _RouteSearchResult extends RouteSearchResult {
  const _RouteSearchResult({final  Map<String, RouteResult> routes = const <String, RouteResult>{}, this.timedOut = false}): _routes = routes,super._();
  

/// Shelter.id → 経路。到達不能・タイムアウトで未発見のものは含まない。
 final  Map<String, RouteResult> _routes;
/// Shelter.id → 経路。到達不能・タイムアウトで未発見のものは含まない。
@override@JsonKey() Map<String, RouteResult> get routes {
  if (_routes is EqualUnmodifiableMapView) return _routes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_routes);
}

/// タイムアウトで打ち切られたか。true でも routes は途中経過を含む。
@override@JsonKey() final  bool timedOut;

/// Create a copy of RouteSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteSearchResultCopyWith<_RouteSearchResult> get copyWith => __$RouteSearchResultCopyWithImpl<_RouteSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteSearchResult&&const DeepCollectionEquality().equals(other._routes, _routes)&&(identical(other.timedOut, timedOut) || other.timedOut == timedOut));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_routes),timedOut);

@override
String toString() {
  return 'RouteSearchResult(routes: $routes, timedOut: $timedOut)';
}


}

/// @nodoc
abstract mixin class _$RouteSearchResultCopyWith<$Res> implements $RouteSearchResultCopyWith<$Res> {
  factory _$RouteSearchResultCopyWith(_RouteSearchResult value, $Res Function(_RouteSearchResult) _then) = __$RouteSearchResultCopyWithImpl;
@override @useResult
$Res call({
 Map<String, RouteResult> routes, bool timedOut
});




}
/// @nodoc
class __$RouteSearchResultCopyWithImpl<$Res>
    implements _$RouteSearchResultCopyWith<$Res> {
  __$RouteSearchResultCopyWithImpl(this._self, this._then);

  final _RouteSearchResult _self;
  final $Res Function(_RouteSearchResult) _then;

/// Create a copy of RouteSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? routes = null,Object? timedOut = null,}) {
  return _then(_RouteSearchResult(
routes: null == routes ? _self._routes : routes // ignore: cast_nullable_to_non_nullable
as Map<String, RouteResult>,timedOut: null == timedOut ? _self.timedOut : timedOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
