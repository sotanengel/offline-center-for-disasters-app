import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/data/sensors/shake_detector.dart';

/// §3.4-b 揺れ検知: 3 軸合成 ≥ 2.5 m/s² が 3 秒継続 → 15 分保持。
/// MUST NOT: 自動画面遷移・自動避難開始はしない（検知は提示のみ）。

/// テスト用の手動進行クロック。
class FakeClock {
  DateTime _now = DateTime(2026, 8, 1, 12, 0);

  DateTime call() => _now;

  DateTime now() => _now;

  void advance(Duration d) {
    _now = _now.add(d);
  }
}

void main() {
  ({
    StreamController<AccelSample> accel,
    FakeClock clock,
    ShakeDetector detector,
  })
  makeDetector() {
    final accel = StreamController<AccelSample>(sync: true);
    final clock = FakeClock();
    final detector = ShakeDetector(
      accelStream: accel.stream,
      clock: () => clock(),
    );
    return (accel: accel, clock: clock, detector: detector);
  }

  test('閾値未満では検知しない', () async {
    final d = makeDetector();
    d.detector.start();
    for (var i = 0; i < 10; i++) {
      d.accel.add(AccelSample(1.0, 0, 0, d.clock.now()));
      d.clock.advance(const Duration(seconds: 1));
    }
    expect(d.detector.isDetected, isFalse);
    await d.accel.close();
  });

  test('2.5 m/s² が 3 秒継続で検知する', () async {
    final d = makeDetector();
    d.detector.start();
    final t0 = d.clock.now();
    // 0秒, 1秒, 2秒, 3秒と継続
    for (var i = 0; i <= 3; i++) {
      d.accel.add(AccelSample(2.6, 0, 0, t0.add(Duration(seconds: i))));
      d.clock.advance(const Duration(seconds: 1));
    }
    expect(d.detector.isDetected, isTrue);
    await d.accel.close();
  });

  test('途中で閾値を割ると継続判定がリセットされる', () async {
    final d = makeDetector();
    d.detector.start();
    final t0 = d.clock.now();
    d.accel.add(AccelSample(3.0, 0, 0, t0));
    d.clock.advance(const Duration(seconds: 1));
    d.accel.add(AccelSample(3.0, 0, 0, t0.add(const Duration(seconds: 1))));
    d.clock.advance(const Duration(seconds: 1));
    // 2 秒時点で閾値を割る
    d.accel.add(AccelSample(1.0, 0, 0, t0.add(const Duration(seconds: 2))));
    d.clock.advance(const Duration(seconds: 1));
    d.accel.add(AccelSample(3.0, 0, 0, t0.add(const Duration(seconds: 3))));
    d.clock.advance(const Duration(seconds: 1));
    expect(d.detector.isDetected, isFalse);
    await d.accel.close();
  });

  test('3 軸合成で判定する（各軸小さくても合成で超過）', () async {
    final d = makeDetector();
    d.detector.start();
    final t0 = d.clock.now();
    // √(1.5²+1.5²+1.5²) ≈ 2.60 ≥ 2.5
    for (var i = 0; i <= 3; i++) {
      d.accel.add(AccelSample(1.5, 1.5, 1.5, t0.add(Duration(seconds: i))));
      d.clock.advance(const Duration(seconds: 1));
    }
    expect(d.detector.isDetected, isTrue);
    await d.accel.close();
  });

  test('検知事実は 15 分間保持され、以後は失効する', () async {
    final d = makeDetector();
    d.detector.start();
    final t0 = d.clock.now();
    for (var i = 0; i <= 3; i++) {
      d.accel.add(AccelSample(3.0, 0, 0, t0.add(Duration(seconds: i))));
      d.clock.advance(const Duration(seconds: 1));
    }
    expect(d.detector.isDetected, isTrue);

    d.clock.advance(const Duration(minutes: 14));
    expect(d.detector.isDetected, isTrue);
    d.clock.advance(const Duration(minutes: 5));
    expect(d.detector.isDetected, isFalse);
    await d.accel.close();
  });
}
