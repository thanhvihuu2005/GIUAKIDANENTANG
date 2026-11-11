import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testgk/main.dart';

void main() {
  testWidgets('App loads LoginScreen properly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen title exists
    expect(find.text('Đăng Nhập Quản Trị'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
