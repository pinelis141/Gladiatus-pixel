import 'dart:convert';
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
  testWidgets('XP vazio exibe 0/30 e não uma barra cheia', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GladiatusApp());
    await tester.pumpAndSettle();
    expect(find.text('EXPERIÊNCIA 0 / 30'), findsOneWidget);
    final bars = tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bars.any((bar) => bar.value == 0.0), isTrue);
  });

  testWidgets('Renovar loja desconta ouro e persiste ofertas', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GladiatusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comércio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renovar ofertas • 25 ouro'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OURO 275'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('gladiatus_pixel_save_v2')!)
        as Map<String, dynamic>;
    expect(saved['gold'], 275);
    expect((saved['shop'] as List).length, 7);
  });

}
