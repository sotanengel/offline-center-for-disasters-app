// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guide_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GuideCard {

 String get id; String get title;/// 対象災害種別（複数可）。
 List<DisasterType> get disasterTypes;/// タグ（意図・状況キーワード）。
 List<String> get tags;/// 表示順（小さいほど優先。§11.1 の一次スコアリング後の並び用）。
 int get priority;/// マッチ条件（例: waterLevel: knee, mobility: wheelchair）。
/// 実装依存の文字列 → 文字列マップ。空なら条件なし。
 Map<String, String> get conditions;/// 手順本文（最大 5 ステップ推奨、§15.2）。
 List<String> get steps;/// 注意書き（オプション）。表示時は視覚的に区別する。
 String? get warning;/// §11 MUST: 出典（気象庁/内閣府/消防庁 等）。空文字禁止。
 String get source;/// 出典の更新日（YYYY-MM-DD 等）。
 String? get sourceUpdated;
/// Create a copy of GuideCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuideCardCopyWith<GuideCard> get copyWith => _$GuideCardCopyWithImpl<GuideCard>(this as GuideCard, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuideCard&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.disasterTypes, disasterTypes)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other.conditions, conditions)&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.warning, warning) || other.warning == warning)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceUpdated, sourceUpdated) || other.sourceUpdated == sourceUpdated));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(disasterTypes),const DeepCollectionEquality().hash(tags),priority,const DeepCollectionEquality().hash(conditions),const DeepCollectionEquality().hash(steps),warning,source,sourceUpdated);

@override
String toString() {
  return 'GuideCard(id: $id, title: $title, disasterTypes: $disasterTypes, tags: $tags, priority: $priority, conditions: $conditions, steps: $steps, warning: $warning, source: $source, sourceUpdated: $sourceUpdated)';
}


}

/// @nodoc
abstract mixin class $GuideCardCopyWith<$Res>  {
  factory $GuideCardCopyWith(GuideCard value, $Res Function(GuideCard) _then) = _$GuideCardCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<DisasterType> disasterTypes, List<String> tags, int priority, Map<String, String> conditions, List<String> steps, String? warning, String source, String? sourceUpdated
});




}
/// @nodoc
class _$GuideCardCopyWithImpl<$Res>
    implements $GuideCardCopyWith<$Res> {
  _$GuideCardCopyWithImpl(this._self, this._then);

  final GuideCard _self;
  final $Res Function(GuideCard) _then;

/// Create a copy of GuideCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? disasterTypes = null,Object? tags = null,Object? priority = null,Object? conditions = null,Object? steps = null,Object? warning = freezed,Object? source = null,Object? sourceUpdated = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,disasterTypes: null == disasterTypes ? _self.disasterTypes : disasterTypes // ignore: cast_nullable_to_non_nullable
as List<DisasterType>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,warning: freezed == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sourceUpdated: freezed == sourceUpdated ? _self.sourceUpdated : sourceUpdated // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GuideCard].
extension GuideCardPatterns on GuideCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuideCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuideCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuideCard value)  $default,){
final _that = this;
switch (_that) {
case _GuideCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuideCard value)?  $default,){
final _that = this;
switch (_that) {
case _GuideCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<DisasterType> disasterTypes,  List<String> tags,  int priority,  Map<String, String> conditions,  List<String> steps,  String? warning,  String source,  String? sourceUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuideCard() when $default != null:
return $default(_that.id,_that.title,_that.disasterTypes,_that.tags,_that.priority,_that.conditions,_that.steps,_that.warning,_that.source,_that.sourceUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<DisasterType> disasterTypes,  List<String> tags,  int priority,  Map<String, String> conditions,  List<String> steps,  String? warning,  String source,  String? sourceUpdated)  $default,) {final _that = this;
switch (_that) {
case _GuideCard():
return $default(_that.id,_that.title,_that.disasterTypes,_that.tags,_that.priority,_that.conditions,_that.steps,_that.warning,_that.source,_that.sourceUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<DisasterType> disasterTypes,  List<String> tags,  int priority,  Map<String, String> conditions,  List<String> steps,  String? warning,  String source,  String? sourceUpdated)?  $default,) {final _that = this;
switch (_that) {
case _GuideCard() when $default != null:
return $default(_that.id,_that.title,_that.disasterTypes,_that.tags,_that.priority,_that.conditions,_that.steps,_that.warning,_that.source,_that.sourceUpdated);case _:
  return null;

}
}

}

/// @nodoc


class _GuideCard implements GuideCard {
  const _GuideCard({required this.id, required this.title, final  List<DisasterType> disasterTypes = const <DisasterType>[], final  List<String> tags = const <String>[], this.priority = 0, final  Map<String, String> conditions = const <String, String>{}, final  List<String> steps = const <String>[], this.warning, required this.source, this.sourceUpdated}): _disasterTypes = disasterTypes,_tags = tags,_conditions = conditions,_steps = steps;
  

@override final  String id;
@override final  String title;
/// 対象災害種別（複数可）。
 final  List<DisasterType> _disasterTypes;
/// 対象災害種別（複数可）。
@override@JsonKey() List<DisasterType> get disasterTypes {
  if (_disasterTypes is EqualUnmodifiableListView) return _disasterTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_disasterTypes);
}

/// タグ（意図・状況キーワード）。
 final  List<String> _tags;
/// タグ（意図・状況キーワード）。
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// 表示順（小さいほど優先。§11.1 の一次スコアリング後の並び用）。
@override@JsonKey() final  int priority;
/// マッチ条件（例: waterLevel: knee, mobility: wheelchair）。
/// 実装依存の文字列 → 文字列マップ。空なら条件なし。
 final  Map<String, String> _conditions;
/// マッチ条件（例: waterLevel: knee, mobility: wheelchair）。
/// 実装依存の文字列 → 文字列マップ。空なら条件なし。
@override@JsonKey() Map<String, String> get conditions {
  if (_conditions is EqualUnmodifiableMapView) return _conditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_conditions);
}

/// 手順本文（最大 5 ステップ推奨、§15.2）。
 final  List<String> _steps;
/// 手順本文（最大 5 ステップ推奨、§15.2）。
@override@JsonKey() List<String> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

/// 注意書き（オプション）。表示時は視覚的に区別する。
@override final  String? warning;
/// §11 MUST: 出典（気象庁/内閣府/消防庁 等）。空文字禁止。
@override final  String source;
/// 出典の更新日（YYYY-MM-DD 等）。
@override final  String? sourceUpdated;

/// Create a copy of GuideCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuideCardCopyWith<_GuideCard> get copyWith => __$GuideCardCopyWithImpl<_GuideCard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuideCard&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._disasterTypes, _disasterTypes)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other._conditions, _conditions)&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.warning, warning) || other.warning == warning)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceUpdated, sourceUpdated) || other.sourceUpdated == sourceUpdated));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_disasterTypes),const DeepCollectionEquality().hash(_tags),priority,const DeepCollectionEquality().hash(_conditions),const DeepCollectionEquality().hash(_steps),warning,source,sourceUpdated);

@override
String toString() {
  return 'GuideCard(id: $id, title: $title, disasterTypes: $disasterTypes, tags: $tags, priority: $priority, conditions: $conditions, steps: $steps, warning: $warning, source: $source, sourceUpdated: $sourceUpdated)';
}


}

/// @nodoc
abstract mixin class _$GuideCardCopyWith<$Res> implements $GuideCardCopyWith<$Res> {
  factory _$GuideCardCopyWith(_GuideCard value, $Res Function(_GuideCard) _then) = __$GuideCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<DisasterType> disasterTypes, List<String> tags, int priority, Map<String, String> conditions, List<String> steps, String? warning, String source, String? sourceUpdated
});




}
/// @nodoc
class __$GuideCardCopyWithImpl<$Res>
    implements _$GuideCardCopyWith<$Res> {
  __$GuideCardCopyWithImpl(this._self, this._then);

  final _GuideCard _self;
  final $Res Function(_GuideCard) _then;

/// Create a copy of GuideCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? disasterTypes = null,Object? tags = null,Object? priority = null,Object? conditions = null,Object? steps = null,Object? warning = freezed,Object? source = null,Object? sourceUpdated = freezed,}) {
  return _then(_GuideCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,disasterTypes: null == disasterTypes ? _self._disasterTypes : disasterTypes // ignore: cast_nullable_to_non_nullable
as List<DisasterType>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,conditions: null == conditions ? _self._conditions : conditions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,warning: freezed == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sourceUpdated: freezed == sourceUpdated ? _self.sourceUpdated : sourceUpdated // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
