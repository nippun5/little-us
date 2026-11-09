import 'package:flutter_test/flutter_test.dart';
import 'package:little_us/game/round_score.dart';

void main() {
  test('counts both partners predictions independently', () {
    final score = RoundGuessScore.fromRound({
      'complete': true,
      'mine': [0, 1, 2],
      'partner': [2, 0, 3],
      'guesses': [2, 0, 1], // 2/3
      'partner_guesses': [0, 2, 1], // 1/3
    })!;
    expect(score.yourCorrect, 2);
    expect(score.partnerCorrect, 1);
    expect(score.yours, [true, true, false]);
    expect(score.partners, [true, false, false]);
  });

  test('does not reveal pending rounds', () {
    expect(
        RoundGuessScore.fromRound({
          'complete': false,
          'mine': [0, 1, 2],
          'partner': [0, 1, 2],
          'guesses': [0, 1, 2],
          'partner_guesses': [0, 1, 2],
        }),
        isNull);
  });

  test('malformed completed round cannot crash score view', () {
    expect(
        RoundGuessScore.fromRound({
          'complete': true,
          'mine': [0, 1],
        }),
        isNull);
  });
}
