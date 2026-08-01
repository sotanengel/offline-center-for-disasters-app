// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shelter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Shelter {

 String get id; String get name; double get lat; double get lng; double? get elevationM; bool get okFlood; bool get okLandslide; bool get okStormSurge; bool get okEarthquake; bool get okTsunami; bool get okFire; bool get okInlandFlood; bool get okVolcano; bool get isAllHazard; PlaceClass get placeClass; double? get usableFloorHeightM; bool get isShelter; bool get barrierFree; int? get capacity; String? get note;
/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShelterCopyWith<Shelter> get copyWith => _$ShelterCopyWithImpl<Shelter>(this as Shelter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shelter&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.elevationM, elevationM) || other.elevationM == elevationM)&&(identical(other.okFlood, okFlood) || other.okFlood == okFlood)&&(identical(other.okLandslide, okLandslide) || other.okLandslide == okLandslide)&&(identical(other.okStormSurge, okStormSurge) || other.okStormSurge == okStormSurge)&&(identical(other.okEarthquake, okEarthquake) || other.okEarthquake == okEarthquake)&&(identical(other.okTsunami, okTsunami) || other.okTsunami == okTsunami)&&(identical(other.okFire, okFire) || other.okFire == okFire)&&(identical(other.okInlandFlood, okInlandFlood) || other.okInlandFlood == okInlandFlood)&&(identical(other.okVolcano, okVolcano) || other.okVolcano == okVolcano)&&(identical(other.isAllHazard, isAllHazard) || other.isAllHazard == isAllHazard)&&(identical(other.placeClass, placeClass) || other.placeClass == placeClass)&&(identical(other.usableFloorHeightM, usableFloorHeightM) || other.usableFloorHeightM == usableFloorHeightM)&&(identical(other.isShelter, isShelter) || other.isShelter == isShelter)&&(identical(other.barrierFree, barrierFree) || other.barrierFree == barrierFree)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,lat,lng,elevationM,okFlood,okLandslide,okStormSurge,okEarthquake,okTsunami,okFire,okInlandFlood,okVolcano,isAllHazard,placeClass,usableFloorHeightM,isShelter,barrierFree,capacity,note]);

@override
String toString() {
  return 'Shelter(id: $id, name: $name, lat: $lat, lng: $lng, elevationM: $elevationM, okFlood: $okFlood, okLandslide: $okLandslide, okStormSurge: $okStormSurge, okEarthquake: $okEarthquake, okTsunami: $okTsunami, okFire: $okFire, okInlandFlood: $okInlandFlood, okVolcano: $okVolcano, isAllHazard: $isAllHazard, placeClass: $placeClass, usableFloorHeightM: $usableFloorHeightM, isShelter: $isShelter, barrierFree: $barrierFree, capacity: $capacity, note: $note)';
}


}

/// @nodoc
abstract mixin class $ShelterCopyWith<$Res>  {
  factory $ShelterCopyWith(Shelter value, $Res Function(Shelter) _then) = _$ShelterCopyWithImpl;
@useResult
$Res call({
 String id, String name, double lat, double lng, double? elevationM, bool okFlood, bool okLandslide, bool okStormSurge, bool okEarthquake, bool okTsunami, bool okFire, bool okInlandFlood, bool okVolcano, bool isAllHazard, PlaceClass placeClass, double? usableFloorHeightM, bool isShelter, bool barrierFree, int? capacity, String? note
});




}
/// @nodoc
class _$ShelterCopyWithImpl<$Res>
    implements $ShelterCopyWith<$Res> {
  _$ShelterCopyWithImpl(this._self, this._then);

  final Shelter _self;
  final $Res Function(Shelter) _then;

/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? lat = null,Object? lng = null,Object? elevationM = freezed,Object? okFlood = null,Object? okLandslide = null,Object? okStormSurge = null,Object? okEarthquake = null,Object? okTsunami = null,Object? okFire = null,Object? okInlandFlood = null,Object? okVolcano = null,Object? isAllHazard = null,Object? placeClass = null,Object? usableFloorHeightM = freezed,Object? isShelter = null,Object? barrierFree = null,Object? capacity = freezed,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,elevationM: freezed == elevationM ? _self.elevationM : elevationM // ignore: cast_nullable_to_non_nullable
as double?,okFlood: null == okFlood ? _self.okFlood : okFlood // ignore: cast_nullable_to_non_nullable
as bool,okLandslide: null == okLandslide ? _self.okLandslide : okLandslide // ignore: cast_nullable_to_non_nullable
as bool,okStormSurge: null == okStormSurge ? _self.okStormSurge : okStormSurge // ignore: cast_nullable_to_non_nullable
as bool,okEarthquake: null == okEarthquake ? _self.okEarthquake : okEarthquake // ignore: cast_nullable_to_non_nullable
as bool,okTsunami: null == okTsunami ? _self.okTsunami : okTsunami // ignore: cast_nullable_to_non_nullable
as bool,okFire: null == okFire ? _self.okFire : okFire // ignore: cast_nullable_to_non_nullable
as bool,okInlandFlood: null == okInlandFlood ? _self.okInlandFlood : okInlandFlood // ignore: cast_nullable_to_non_nullable
as bool,okVolcano: null == okVolcano ? _self.okVolcano : okVolcano // ignore: cast_nullable_to_non_nullable
as bool,isAllHazard: null == isAllHazard ? _self.isAllHazard : isAllHazard // ignore: cast_nullable_to_non_nullable
as bool,placeClass: null == placeClass ? _self.placeClass : placeClass // ignore: cast_nullable_to_non_nullable
as PlaceClass,usableFloorHeightM: freezed == usableFloorHeightM ? _self.usableFloorHeightM : usableFloorHeightM // ignore: cast_nullable_to_non_nullable
as double?,isShelter: null == isShelter ? _self.isShelter : isShelter // ignore: cast_nullable_to_non_nullable
as bool,barrierFree: null == barrierFree ? _self.barrierFree : barrierFree // ignore: cast_nullable_to_non_nullable
as bool,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Shelter].
extension ShelterPatterns on Shelter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shelter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shelter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shelter value)  $default,){
final _that = this;
switch (_that) {
case _Shelter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shelter value)?  $default,){
final _that = this;
switch (_that) {
case _Shelter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double lat,  double lng,  double? elevationM,  bool okFlood,  bool okLandslide,  bool okStormSurge,  bool okEarthquake,  bool okTsunami,  bool okFire,  bool okInlandFlood,  bool okVolcano,  bool isAllHazard,  PlaceClass placeClass,  double? usableFloorHeightM,  bool isShelter,  bool barrierFree,  int? capacity,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shelter() when $default != null:
return $default(_that.id,_that.name,_that.lat,_that.lng,_that.elevationM,_that.okFlood,_that.okLandslide,_that.okStormSurge,_that.okEarthquake,_that.okTsunami,_that.okFire,_that.okInlandFlood,_that.okVolcano,_that.isAllHazard,_that.placeClass,_that.usableFloorHeightM,_that.isShelter,_that.barrierFree,_that.capacity,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double lat,  double lng,  double? elevationM,  bool okFlood,  bool okLandslide,  bool okStormSurge,  bool okEarthquake,  bool okTsunami,  bool okFire,  bool okInlandFlood,  bool okVolcano,  bool isAllHazard,  PlaceClass placeClass,  double? usableFloorHeightM,  bool isShelter,  bool barrierFree,  int? capacity,  String? note)  $default,) {final _that = this;
switch (_that) {
case _Shelter():
return $default(_that.id,_that.name,_that.lat,_that.lng,_that.elevationM,_that.okFlood,_that.okLandslide,_that.okStormSurge,_that.okEarthquake,_that.okTsunami,_that.okFire,_that.okInlandFlood,_that.okVolcano,_that.isAllHazard,_that.placeClass,_that.usableFloorHeightM,_that.isShelter,_that.barrierFree,_that.capacity,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double lat,  double lng,  double? elevationM,  bool okFlood,  bool okLandslide,  bool okStormSurge,  bool okEarthquake,  bool okTsunami,  bool okFire,  bool okInlandFlood,  bool okVolcano,  bool isAllHazard,  PlaceClass placeClass,  double? usableFloorHeightM,  bool isShelter,  bool barrierFree,  int? capacity,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _Shelter() when $default != null:
return $default(_that.id,_that.name,_that.lat,_that.lng,_that.elevationM,_that.okFlood,_that.okLandslide,_that.okStormSurge,_that.okEarthquake,_that.okTsunami,_that.okFire,_that.okInlandFlood,_that.okVolcano,_that.isAllHazard,_that.placeClass,_that.usableFloorHeightM,_that.isShelter,_that.barrierFree,_that.capacity,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _Shelter implements Shelter {
  const _Shelter({required this.id, required this.name, required this.lat, required this.lng, this.elevationM, this.okFlood = false, this.okLandslide = false, this.okStormSurge = false, this.okEarthquake = false, this.okTsunami = false, this.okFire = false, this.okInlandFlood = false, this.okVolcano = false, this.isAllHazard = false, this.placeClass = PlaceClass.unknownOrBuilding, this.usableFloorHeightM, this.isShelter = false, this.barrierFree = false, this.capacity, this.note});


@override final  String id;
@override final  String name;
@override final  double lat;
@override final  double lng;
@override final  double? elevationM;
@override@JsonKey() final  bool okFlood;
@override@JsonKey() final  bool okLandslide;
@override@JsonKey() final  bool okStormSurge;
@override@JsonKey() final  bool okEarthquake;
@override@JsonKey() final  bool okTsunami;
@override@JsonKey() final  bool okFire;
@override@JsonKey() final  bool okInlandFlood;
@override@JsonKey() final  bool okVolcano;
@override@JsonKey() final  bool isAllHazard;
@override@JsonKey() final  PlaceClass placeClass;
@override final  double? usableFloorHeightM;
@override@JsonKey() final  bool isShelter;
@override@JsonKey() final  bool barrierFree;
@override final  int? capacity;
@override final  String? note;

/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShelterCopyWith<_Shelter> get copyWith => __$ShelterCopyWithImpl<_Shelter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shelter&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.elevationM, elevationM) || other.elevationM == elevationM)&&(identical(other.okFlood, okFlood) || other.okFlood == okFlood)&&(identical(other.okLandslide, okLandslide) || other.okLandslide == okLandslide)&&(identical(other.okStormSurge, okStormSurge) || other.okStormSurge == okStormSurge)&&(identical(other.okEarthquake, okEarthquake) || other.okEarthquake == okEarthquake)&&(identical(other.okTsunami, okTsunami) || other.okTsunami == okTsunami)&&(identical(other.okFire, okFire) || other.okFire == okFire)&&(identical(other.okInlandFlood, okInlandFlood) || other.okInlandFlood == okInlandFlood)&&(identical(other.okVolcano, okVolcano) || other.okVolcano == okVolcano)&&(identical(other.isAllHazard, isAllHazard) || other.isAllHazard == isAllHazard)&&(identical(other.placeClass, placeClass) || other.placeClass == placeClass)&&(identical(other.usableFloorHeightM, usableFloorHeightM) || other.usableFloorHeightM == usableFloorHeightM)&&(identical(other.isShelter, isShelter) || other.isShelter == isShelter)&&(identical(other.barrierFree, barrierFree) || other.barrierFree == barrierFree)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,lat,lng,elevationM,okFlood,okLandslide,okStormSurge,okEarthquake,okTsunami,okFire,okInlandFlood,okVolcano,isAllHazard,placeClass,usableFloorHeightM,isShelter,barrierFree,capacity,note]);

@override
String toString() {
  return 'Shelter(id: $id, name: $name, lat: $lat, lng: $lng, elevationM: $elevationM, okFlood: $okFlood, okLandslide: $okLandslide, okStormSurge: $okStormSurge, okEarthquake: $okEarthquake, okTsunami: $okTsunami, okFire: $okFire, okInlandFlood: $okInlandFlood, okVolcano: $okVolcano, isAllHazard: $isAllHazard, placeClass: $placeClass, usableFloorHeightM: $usableFloorHeightM, isShelter: $isShelter, barrierFree: $barrierFree, capacity: $capacity, note: $note)';
}


}

/// @nodoc
abstract mixin class _$ShelterCopyWith<$Res> implements $ShelterCopyWith<$Res> {
  factory _$ShelterCopyWith(_Shelter value, $Res Function(_Shelter) _then) = __$ShelterCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double lat, double lng, double? elevationM, bool okFlood, bool okLandslide, bool okStormSurge, bool okEarthquake, bool okTsunami, bool okFire, bool okInlandFlood, bool okVolcano, bool isAllHazard, PlaceClass placeClass, double? usableFloorHeightM, bool isShelter, bool barrierFree, int? capacity, String? note
});




}
/// @nodoc
class __$ShelterCopyWithImpl<$Res>
    implements _$ShelterCopyWith<$Res> {
  __$ShelterCopyWithImpl(this._self, this._then);

  final _Shelter _self;
  final $Res Function(_Shelter) _then;

/// Create a copy of Shelter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? lat = null,Object? lng = null,Object? elevationM = freezed,Object? okFlood = null,Object? okLandslide = null,Object? okStormSurge = null,Object? okEarthquake = null,Object? okTsunami = null,Object? okFire = null,Object? okInlandFlood = null,Object? okVolcano = null,Object? isAllHazard = null,Object? placeClass = null,Object? usableFloorHeightM = freezed,Object? isShelter = null,Object? barrierFree = null,Object? capacity = freezed,Object? note = freezed,}) {
  return _then(_Shelter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,elevationM: freezed == elevationM ? _self.elevationM : elevationM // ignore: cast_nullable_to_non_nullable
as double?,okFlood: null == okFlood ? _self.okFlood : okFlood // ignore: cast_nullable_to_non_nullable
as bool,okLandslide: null == okLandslide ? _self.okLandslide : okLandslide // ignore: cast_nullable_to_non_nullable
as bool,okStormSurge: null == okStormSurge ? _self.okStormSurge : okStormSurge // ignore: cast_nullable_to_non_nullable
as bool,okEarthquake: null == okEarthquake ? _self.okEarthquake : okEarthquake // ignore: cast_nullable_to_non_nullable
as bool,okTsunami: null == okTsunami ? _self.okTsunami : okTsunami // ignore: cast_nullable_to_non_nullable
as bool,okFire: null == okFire ? _self.okFire : okFire // ignore: cast_nullable_to_non_nullable
as bool,okInlandFlood: null == okInlandFlood ? _self.okInlandFlood : okInlandFlood // ignore: cast_nullable_to_non_nullable
as bool,okVolcano: null == okVolcano ? _self.okVolcano : okVolcano // ignore: cast_nullable_to_non_nullable
as bool,isAllHazard: null == isAllHazard ? _self.isAllHazard : isAllHazard // ignore: cast_nullable_to_non_nullable
as bool,placeClass: null == placeClass ? _self.placeClass : placeClass // ignore: cast_nullable_to_non_nullable
as PlaceClass,usableFloorHeightM: freezed == usableFloorHeightM ? _self.usableFloorHeightM : usableFloorHeightM // ignore: cast_nullable_to_non_nullable
as double?,isShelter: null == isShelter ? _self.isShelter : isShelter // ignore: cast_nullable_to_non_nullable
as bool,barrierFree: null == barrierFree ? _self.barrierFree : barrierFree // ignore: cast_nullable_to_non_nullable
as bool,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
