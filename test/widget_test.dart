import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/main.dart';

void main() {
  testWidgets('アプリが起動しタイトルが表示される', (tester) async {
    await tester.pumpWidget(const OfflineCenterApp());
    expect(find.text('オフライン災害対応センター'), findsOneWidget);
  });
}
