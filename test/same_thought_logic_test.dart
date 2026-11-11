import 'package:flutter_test/flutter_test.dart';
import 'package:little_us/game/same_thought/same_thought_logic.dart';

void main() {
  test('normalization ignores case and surrounding whitespace', () {
    expect(normalizeSameThoughtWord('  NEW    Zealand '), 'new zealand');
    expect(localSameThoughtMatch(' Cat ', 'cAT'), isTrue);
    expect(localSameThoughtMatch('cat', 'cow'), isFalse);
    expect(localSameThoughtMatch('', ''), isFalse);
    expect(localSameThoughtMatch(null, 'cat'), isFalse);
  });

  test('lobby does not report a result', () {
    final snap = SameThoughtSnapshot({'phase': 'lobby', 'score': 0});
    expect(snap.status, 'lobby');
    expect(snap.recap, isEmpty);
    expect(snap.matched, isNull);
  });

  test('time remaining uses server offset, clamps at zero', () {
    final snap = SameThoughtSnapshot({
      'deadline': '2026-11-11T18:00:15Z',
    });
    final now = DateTime.parse('2026-11-11T18:00:00Z');
    expect(snap.remainingMs(localNow: now), 15000);
    expect(
        snap.remainingMs(
            localNow: now, serverOffset: const Duration(seconds: 10)),
        5000);
    expect(
        snap.remainingMs(
            localNow: now, serverOffset: const Duration(seconds: 30)),
        0);
  });

  test('recap and score are parsed from the server, not computed by client',
      () {
    final snap = SameThoughtSnapshot({
      'status': 'finished',
      'score': 3,
      'round_no': 5,
      'recap': [
        {'number': 1, 'you': 'cat', 'partner': 'cat', 'matched': true},
        {'number': 2, 'you': 'pizza', 'partner': 'pasta', 'matched': false},
      ],
    });
    expect(snap.score, 3);
    expect(snap.round, 5);
    expect(snap.recap.length, 2);
  });
}
