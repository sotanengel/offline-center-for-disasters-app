import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/domain/usecases/destination_planner.dart';

void main() {
  test('formatDistanceM: 1000m 以上は km 表示', () {
    expect(formatDistanceM(1200), '1.2km');
    expect(formatDistanceM(850), '850m');
  });
}
