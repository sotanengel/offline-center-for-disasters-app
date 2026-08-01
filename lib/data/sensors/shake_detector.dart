import 'dart:async';
import 'dart:math' as math;

/// 加速度サンプル（sensors_plus のイベントから変換。テスト容易性のため分離）。
class AccelSample {
  const AccelSample(this.x, this.y, this.z, this.at);

  final double x;
  final double y;
  final double z;
  final DateTime at;

  double get magnitude => math.sqrt(x * x + y * y + z * z);
}

/// §3.4-b 揺れ検知: 3 軸合成 ≥ 2.5 m/s² が 3 秒継続 → 15 分保持。
///
/// MUST NOT: 自動画面遷移・自動避難開始は行わない。
/// 誤検知（乗り物・落下）の可能性があるため、ホーム画面での提示にのみ使う。
class ShakeDetector {
  ShakeDetector({
    required Stream<AccelSample> accelStream,
    DateTime Function()? clock,
    this.thresholdMps2 = 2.5,
    this.sustainFor = const Duration(seconds: 3),
    this.holdFor = const Duration(minutes: 15),
  }) : _accelStream = accelStream,
       _clock = clock ?? DateTime.now;

  final Stream<AccelSample> _accelStream;
  final DateTime Function() _clock;

  /// 検知閾値 [m/s²]（3 軸合成）
  final double thresholdMps2;

  /// 継続時間（この時間以上の連続超過で検知）
  final Duration sustainFor;

  /// 検知事実の保持時間
  final Duration holdFor;

  StreamSubscription<AccelSample>? _sub;
  DateTime? _overSince;
  DateTime? _detectedAt;
  final _changes = StreamController<void>.broadcast();

  /// 新規検知のたびに発火する通知（UI 更新用）。
  Stream<void> get changes => _changes.stream;

  void start() {
    // センサを利用できない環境（CI 等）では検知なしとして縮退する
    _sub ??= _accelStream.listen(_onSample, onError: (_) {});
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _changes.close();
  }

  /// 現在、保持期間内の検知事実があるか。
  bool get isDetected {
    final at = _detectedAt;
    if (at == null) return false;
    return _clock().difference(at) <= holdFor;
  }

  /// 検知時刻（保持切れでも最後の検知を返す。表示用）
  DateTime? get lastDetectedAt => _detectedAt;

  void _onSample(AccelSample sample) {
    if (sample.magnitude >= thresholdMps2) {
      final since = _overSince ??= sample.at;
      if (sample.at.difference(since) >= sustainFor) {
        if (_detectedAt != sample.at) {
          _detectedAt = sample.at;
          _changes.add(null);
        }
      }
    } else {
      _overSince = null;
    }
  }
}
