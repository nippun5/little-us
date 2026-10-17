import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_us/store.dart';
import 'package:little_us/main.dart';
import 'package:little_us/v2_features.dart';
import 'v2_store_test.dart' show FakeFridge;

void main() {
  testWidgets('room picker unlocks and pet actions reflect daily completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(
      await SharedPreferences.getInstance(),
      fridgeBridge: FakeFridge(),
    );
    await s.startDemo();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: s,
            builder: (_, __) => SingleChildScrollView(
              child: Column(
                children: [
                  RoomPicker(store: s),
                  PetPanel(store: s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Bedroom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock · 80'));
    await tester.pumpAndSettle();
    expect(s.currentRoom, 'bedroom');
    expect(s.coins, 40);
    await tester.tap(find.text('Meet our pet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adopt for free'));
    await tester.pumpAndSettle();
    expect(s.pet!['name'], 'Mochi');
    await tester.tap(find.text('Feed · +2 XP'));
    await tester.pumpAndSettle();
    expect(find.text('Fed today'), findsOneWidget);
    expect(s.pet!['xp'], 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
  testWidgets('widget sharing requires consent and clearing is visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final bridge = FakeFridge();
    final s = AppStore(
      await SharedPreferences.getInstance(),
      fridgeBridge: bridge,
    );
    await s.startDemo();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: s,
            builder: (_, __) =>
                SingleChildScrollView(child: FridgeWidgetPanel(store: s)),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Enable widget'), findsOneWidget);
    expect(s.widgetEnabled, false);
    await tester.tap(find.text('Enable widget'));
    await tester.pumpAndSettle();
    expect(s.widgetEnabled, true);
    expect(bridge.writes.last['author'], 'Jamie');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(s.widgetEnabled, false);
    expect(bridge.writes.last['body'], '');
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
  testWidgets('three rooms render with pet at a narrow phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(
      await SharedPreferences.getInstance(),
      fridgeBridge: FakeFridge(),
    );
    await s.startDemo();
    s.home!['coins'] = 500;
    await s.adoptPet('dog', 'Peanut');
    await s.unlockRoom('bedroom');
    await s.unlockRoom('garden');
    await tester.pumpWidget(LittleUs(store: s));
    await tester.pumpAndSettle();
    for (final room in ['living', 'bedroom', 'garden']) {
      await s.selectRoom(room);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
}
