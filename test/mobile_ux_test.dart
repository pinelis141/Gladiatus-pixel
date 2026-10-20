import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gladiatus_pixel/main.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();

  for(final width in [320.0,360.0,412.0]){
    testWidgets('Mobile layout width $width does not overflow',
      (tester) async{
        SharedPreferences.setMockInitialValues({});
        await tester.binding.setSurfaceSize(Size(width,730));
        addTearDown(() async=>tester.binding.setSurfaceSize(null));
        final previousError = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint('UX AUDIT DIAGNOSTIC: ${details.toString()}');
          previousError?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousError);
        await tester.pumpWidget(const GladiatusApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
        await tester.tap(find.descendant(of:find.byType(NavigationBar),matching:find.byIcon(Icons.map)));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
        await tester.tap(find.descendant(of:find.byType(NavigationBar),matching:find.byIcon(Icons.storefront)));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
    });
  }

  testWidgets('Important recovering and contracts are visible first',
      (tester) async{
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GladiatusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();
    expect(find.text('CONTRATOS DIÁRIOS'),findsOneWidget);
    expect(find.text('TAVERNA'),findsOneWidget);
  });

  testWidgets('Item filtering and forge remain accessible',(tester) async{
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GladiatusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Itens'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<String>),findsOneWidget);
    await tester.tap(find.text('Comércio'));
    await tester.pumpAndSettle();
    expect(find.text('FERREIRO'),findsOneWidget);
    await tester.tap(find.text('FERREIRO'));
    await tester.pumpAndSettle();
    expect(find.text('OFICINA DO FERREIRO'),findsOneWidget);
  });
}
