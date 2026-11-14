import 'package:flutter_test/flutter_test.dart';
import 'package:little_us/push/push_destination.dart';

void main() {
  test('fridge alerts navigate to notes', () {
    final to = pushDestinationFromData({'kind': 'fridge_note'});
    expect(to, PushDestination.fridgeNote);
    expect(tabForPushDestination(to!), 2);
  });
  test('game alerts navigate to play', () {
    for (final kind in ['same_thought','doodle_started','doodle_finished']) {
      final to = pushDestinationFromData({'kind': kind});
      expect(to, isNotNull);
      expect(tabForPushDestination(to!), 1);
    }
  });
  test('unknown or malformed destinations are ignored', () {
    expect(pushDestinationFromData({'kind':'danger'}), isNull);
    expect(pushDestinationFromData({}), isNull);
  });
}
