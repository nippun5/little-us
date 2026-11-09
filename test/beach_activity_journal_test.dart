import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_us/adventures/beach_activity_journal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('progress is scoped to a home and stored once per activity', () async {
    final prefs = await SharedPreferences.getInstance();
    final a = BeachActivityJournal(prefs, 'userA:home1');
    final b = BeachActivityJournal(prefs, 'userB:home1');
    await a.save(const BeachActivityRecord(
        id: 'picnic', summary: 'Picnic', completedAt: '2026-11-09T12:00:00Z'));
    await a.save(const BeachActivityRecord(
        id: 'picnic',
        summary: 'New picnic',
        completedAt: '2026-11-09T12:01:00Z'));
    expect(a.load().length, 1);
    expect(a.load()['picnic']!.summary, 'New picnic');
    expect(b.load(), isEmpty);
    await BeachActivityJournal.clear(prefs, 'userA:home1');
    expect(a.load(), isEmpty);
  });

  test('rejects invalid activity ids', () async {
    final prefs = await SharedPreferences.getInstance();
    final journal = BeachActivityJournal(prefs, 'demo');
    await expectLater(
      journal.save(const BeachActivityRecord(
          id: 'free_hearts', summary: 'Oops', completedAt: 'today')),
      throwsArgumentError,
    );
  });
}
