import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('shows the staff login screen', (tester) async {
    await tester.pumpWidget(const CampusRadioApp());
    expect(find.text('Campus Radio Login'), findsOneWidget);
    expect(find.text('Login to Admin Portal'), findsOneWidget);
  });
}
