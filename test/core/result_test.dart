import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';

void main() {
  group('Result combinators', () {
    test('map: Ok を変換 / Err はそのまま', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('e');
      expect(ok.map((v) => v * 3), isA<Ok<int, String>>());
      expect((ok.map((v) => v * 3) as Ok<int, String>).value, 6);
      expect(err.map((v) => v * 3), isA<Err<int, String>>());
      expect((err.map((v) => v * 3) as Err<int, String>).error, 'e');
    });

    test('mapErr: Err を変換 / Ok はそのまま', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('e');
      expect(ok.mapErr((e) => e.length), isA<Ok<int, int>>());
      expect((err.mapErr((e) => e.length) as Err<int, int>).error, 1);
    });

    test('fold: ok/err 両方の分岐を書ける', () {
      const Result<int, String> ok = Ok(3);
      const Result<int, String> err = Err('boom');
      expect(ok.fold(ok: (v) => 'v=$v', err: (e) => 'e=$e'), 'v=3');
      expect(err.fold(ok: (v) => 'v=$v', err: (e) => 'e=$e'), 'e=boom');
    });

    test('isOk / isErr', () {
      expect(const Ok<int, String>(1).isOk, isTrue);
      expect(const Ok<int, String>(1).isErr, isFalse);
      expect(const Err<int, String>('x').isOk, isFalse);
      expect(const Err<int, String>('x').isErr, isTrue);
    });

    test('valueOrNull', () {
      expect(const Ok<int, String>(1).valueOrNull, 1);
      expect(const Err<int, String>('x').valueOrNull, isNull);
    });
  });
}
