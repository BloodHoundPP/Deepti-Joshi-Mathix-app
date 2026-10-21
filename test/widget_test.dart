import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coaching_portal/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test verifies coaching dashboard loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CoachingApp());
    await tester.pumpAndSettle();

    expect(find.text('Deepti Joshi Coaching Academy'), findsWidgets);
  });
}
