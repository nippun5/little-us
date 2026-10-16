import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_us/main.dart';
import 'package:little_us/store.dart';

void main() {
  testWidgets('home and all tabs render at narrow phone size', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance());
    await store.startDemo();
    await tester.pumpWidget(LittleUs(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Better, together.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final label in ['Play', 'Notes', 'Decorate', 'Us']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
