import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('shows the campus radio login screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CampusLoginPage()));
    expect(find.text('Campus Radio Login'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
