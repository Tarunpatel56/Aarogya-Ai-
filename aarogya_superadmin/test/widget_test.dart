import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya_superadmin/main.dart';

void main() {
  testWidgets('SuperAdminApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AarogyaSuperAdminApp());
    expect(find.byType(AarogyaSuperAdminApp), findsOneWidget);
  });
}
