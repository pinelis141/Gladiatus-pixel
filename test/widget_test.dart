import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gladiatus_pixel/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A tela principal abre com a navegacao', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GladiatusApp());
    await tester.pumpAndSettle();
    expect(find.text('GLADIATUS PIXEL'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
