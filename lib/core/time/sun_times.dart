import 'dart:math' as math;

import '../geo/geo_point.dart';

/// 日出・日没時刻の値。
/// 極夜のときは isPolarNight=true / sunrise, sunset は null。
/// 白夜のときは isPolarDay=true / sunrise, sunset は null。
class SunTimes {
  const SunTimes({
    this.sunrise,
    this.sunset,
    this.isPolarNight = false,
    this.isPolarDay = false,
  });

  final DateTime? sunrise;
  final DateTime? sunset;
  final bool isPolarNight;
  final bool isPolarDay;
}

/// NOAA の Solar Position Algorithm（簡略版）に基づく、指定地点・指定日の
/// 日の出と日の入りを返す純粋関数。
///
/// 大気差 34'、太陽視半径 16' を合わせて -0.833° を天頂角補正として使用する。
///
/// [date] は当日の代表時刻（UTC/ローカルいずれでも可）。返り値は UTC。
SunTimes sunTimes(GeoPoint at, DateTime date) {
  final utc = date.toUtc();
  final day = DateTime.utc(utc.year, utc.month, utc.day, 12);
  final jd = _julianDay(day);
  final t = (jd - 2451545.0) / 36525.0;

  // 平均黄経 (deg)
  final l0 = _norm360(280.46646 + t * (36000.76983 + t * 0.0003032));
  // 平均近点角
  final m = _norm360(357.52911 + t * (35999.05029 - 0.0001537 * t));
  // 中心差
  final mRad = _rad(m);
  final c =
      math.sin(mRad) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
      math.sin(2 * mRad) * (0.019993 - 0.000101 * t) +
      math.sin(3 * mRad) * 0.000289;
  final trueLong = l0 + c;
  final omega = 125.04 - 1934.136 * t;
  final appLong = trueLong - 0.00569 - 0.00478 * math.sin(_rad(omega));

  // 傾斜角
  final e0 =
      23 +
      (26 + (21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))) / 60) / 60;
  final e = e0 + 0.00256 * math.cos(_rad(omega));
  final eRad = _rad(e);

  // 赤緯
  final decl = math.asin(math.sin(eRad) * math.sin(_rad(appLong)));

  // 離心率
  final ecc = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

  // 方程式時 (minutes) — NOAA 標準式
  final y = math.tan(eRad / 2) * math.tan(eRad / 2);
  final l0Rad = _rad(l0);
  final eqTimeMin =
      4 *
      _deg(
        y * math.sin(2 * l0Rad) -
            2 * ecc * math.sin(mRad) +
            4 * ecc * y * math.sin(mRad) * math.cos(2 * l0Rad) -
            0.5 * y * y * math.sin(4 * l0Rad) -
            1.25 * ecc * ecc * math.sin(2 * mRad),
      );

  final latRad = _rad(at.lat);
  final zenith = _rad(90.833); // 大気差 + 太陽半径

  final cosHa =
      (math.cos(zenith) - math.sin(latRad) * math.sin(decl)) /
      (math.cos(latRad) * math.cos(decl));
  if (cosHa > 1) {
    // 太陽が常に地平線下 → 極夜
    return const SunTimes(isPolarNight: true);
  }
  if (cosHa < -1) {
    // 太陽が常に地平線上 → 白夜
    return const SunTimes(isPolarDay: true);
  }

  final ha = _deg(math.acos(cosHa)); // hour angle (deg)
  // 太陽正中時刻（UTC 分）
  final solarNoonUtcMin = 720 - 4 * at.lng - eqTimeMin;
  final sunriseMin = solarNoonUtcMin - 4 * ha;
  final sunsetMin = solarNoonUtcMin + 4 * ha;

  DateTime toDt(double minutesFromMidnight) {
    final base = DateTime.utc(day.year, day.month, day.day);
    return base.add(
      Duration(milliseconds: (minutesFromMidnight * 60000).round()),
    );
  }

  return SunTimes(sunrise: toDt(sunriseMin), sunset: toDt(sunsetMin));
}

/// [at] における [when] が夜間かどうか（isNight = !(sunrise <= t <= sunset)）。
/// 極夜は true、白夜は false。
bool isNight(GeoPoint at, DateTime when) {
  final st = sunTimes(at, when);
  if (st.isPolarNight) return true;
  if (st.isPolarDay) return false;
  final t = when.toUtc();
  final sr = st.sunrise;
  final ss = st.sunset;
  if (sr == null || ss == null) return true;
  return t.isBefore(sr) || t.isAfter(ss);
}

double _julianDay(DateTime utc) {
  var y = utc.year;
  var m = utc.month;
  final d = utc.day + (utc.hour + utc.minute / 60 + utc.second / 3600) / 24;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d +
      b -
      1524.5;
}

double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;

double _norm360(double v) {
  final r = v % 360;
  return r < 0 ? r + 360 : r;
}
