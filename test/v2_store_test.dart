import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_us/store.dart';
import 'package:little_us/fridge_widget.dart';

class FakeFridge implements FridgeBridge {
  final writes = <Map<String, Object?>>[];
  @override
  bool get supported => true;
  @override
  Future<bool> requestPin() async => true;
  @override
  Future<void> update(Map<String, Object?> data) async {
    writes.add(Map.of(data));
  }
}

void main() {
  late AppStore s;
  late FakeFridge bridge;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    bridge = FakeFridge();
    s = AppStore(await SharedPreferences.getInstance(), fridgeBridge: bridge);
    await s.startDemo();
  });
  tearDown(() => s.dispose());
  test('v1 local homes load without losing notes, money, or colors', () async {
    await s.prefs.setString(
      'demo_state',
      jsonEncode({
        'home': {
          'a': 'demo-a',
          'b': 'demo-b',
          'a_name': 'Alex',
          'b_name': 'Jamie',
          'coins': 91,
          'theme': 'rose',
          'owned': ['peach', 'rose'],
        },
        'notes': [
          {'id': 'old', 'author': 'Jamie', 'body': 'Keep this'},
        ],
        'rounds': [],
      }),
    );
    await s.startDemo();
    expect(s.coins, 91);
    expect(s.theme, 'rose');
    expect(s.unlockedRooms, ['living']);
    expect(s.pet, isNull);
    expect(s.notes.single['body'], 'Keep this');
  });
  test('unlock is idempotent and color edits stay in selected room', () async {
    s.home!['coins'] = 300;
    await s.unlockRoom('bedroom');
    expect(s.coins, 220);
    expect(s.currentRoom, 'bedroom');
    await s.unlockRoom('bedroom');
    expect(s.coins, 220);
    await s.decorate('lilac');
    expect(s.coins, 160);
    expect(s.roomTheme, 'lilac');
    expect(s.theme, 'peach');
    await s.selectRoom('living');
    await s.decorate('lilac');
    expect(s.coins, 160);
    await s.unlockRoom('garden');
    expect(s.coins, 40);
    expect(s.unlockedRooms.length, 3);
  });
  test('pet care rewards once and pet data persists', () async {
    await s.adoptPet('cat', 'Mochi');
    await s.careForPet('feed');
    await s.careForPet('feed');
    await s.careForPet('play');
    expect(s.pet!['xp'], 5);
    expect(s.coins, 120);
    final restored = AppStore(
      await SharedPreferences.getInstance(),
      fridgeBridge: bridge,
    );
    await restored.startDemo();
    expect(restored.pet!['name'], 'Mochi');
    expect(restored.petCareToday, containsAll(['feed', 'play']));
    await restored.renamePet('Peanut');
    expect(restored.pet!['name'], 'Peanut');
    restored.dispose();
  });
  test(
    'widget requires opt-in, pins and deletion falls back to partner note',
    () async {
      expect(bridge.writes.last['enabled'], false);
      expect(bridge.writes.last['body'], '');
      await s.setWidgetEnabled(true);
      expect(bridge.writes.last['author'], 'Jamie');
      await s.addNote('A note from me');
      await s.pinWidgetNote(s.notes.first['id']);
      expect(bridge.writes.last['body'], 'A note from me');
      await s.removeNote(s.notes.first['id']);
      expect(bridge.writes.last['author'], 'Jamie');
      expect(bridge.writes.last.keys.toSet(), {
        'enabled',
        'body',
        'author',
        'demo',
        'updatedAt',
      });
      await s.signOut();
      expect(bridge.writes.last['enabled'], false);
      expect(bridge.writes.last['body'], '');
    },
  );
  test(
    'disabling widget removes content and latest mode does not display own note',
    () async {
      await s.removeNote('welcome');
      await s.addNote('Only mine');
      await s.setWidgetEnabled(true);
      expect(s.widgetNote, isNull);
      expect(
        bridge.writes.last['body'],
        'Your next little note will appear here.',
      );
      await s.setWidgetEnabled(false);
      expect(bridge.writes.last['body'], '');
      expect(bridge.writes.last['author'], '');
    },
  );
}
