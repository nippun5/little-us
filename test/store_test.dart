import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_us/store.dart';
import 'package:little_us/models.dart';

void main() {
  late AppStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(await SharedPreferences.getInstance());
    await store.startDemo();
  });
  tearDown(() => store.dispose());
  test(
    'answers remain locked until partner completes and reward is one-time',
    () async {
      final initial = store.coins;
      await store.submit([0, 1, 2], [2, 1, 0]);
      expect(store.today!['complete'], false);
      expect(store.today!['partner'], isNull);
      expect(store.coins, initial);
      await store.simulatePartner();
      expect(store.today!['complete'], true);
      expect(store.coins, initial + 30);
      await store.simulatePartner();
      await store.submit([3, 3, 3], [3, 3, 3]);
      expect(store.coins, initial + 30);
      expect(store.rounds.length, 1);
    },
  );
  test(
    'buying a decoration charges once, switching owned items is free',
    () async {
      await store.decorate('lilac');
      expect(store.coins, 60);
      expect(store.theme, 'lilac');
      await store.decorate('peach');
      await store.decorate('lilac');
      expect(store.coins, 60);
      await expectLater(store.decorate('rose'), throwsA(isA<Exception>()));
      expect(store.theme, 'lilac');
    },
  );
  test('demo notes and room survive reopening, deletion clears them', () async {
    await store.addNote('Remember this');
    await store.decorate('mint');
    final next = AppStore(await SharedPreferences.getInstance());
    await next.startDemo();
    expect(next.notes.first['body'], 'Remember this');
    expect(next.theme, 'mint');
    await next.deleteAccount();
    expect(next.home, isNull);
    expect(next.prefs.getString('demo_state'), isNull);
    next.dispose();
  });
  test(
    'daily questions are deterministic and cover every prompt in a week',
    () {
      final seen = <String>{};
      for (int i = 1; i <= 7; i++) {
        final qs = dailyQuestions('2026-10-${i.toString().padLeft(2, '0')}');
        expect(qs.length, 3);
        for (final q in qs) {
          expect(q.options.length, 4);
          seen.add(q.title);
        }
      }
      expect(seen.length, 21);
    },
  );
}
