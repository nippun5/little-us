import 'package:flutter/material.dart';

/// A correct answer means guessing what the OTHER person actually chose.
/// Existing completed round keys (unchanged):
/// mine, partner, guesses, partner_guesses — each a list of three option indices.
@immutable
class RoundGuessScore {
  const RoundGuessScore({required this.yours, required this.partners});

  final List<bool> yours;
  final List<bool> partners;

  int get yourCorrect => yours.where((v) => v).length;
  int get partnerCorrect => partners.where((v) => v).length;
  int get questionCount => yours.length;

  static RoundGuessScore? fromRound(Map<String, dynamic> round) {
    List<int>? read(String key) {
      final raw = round[key];
      if (raw is! List || raw.length != 3) return null;
      final result = <int>[];
      for (final v in raw) {
        if (v is! int || v < 0 || v > 3) return null;
        result.add(v);
      }
      return result;
    }

    if (round['complete'] != true) return null; // Never reveal pending results.
    final mine = read('mine');
    final partner = read('partner');
    final guesses = read('guesses');
    final partnerGuesses = read('partner_guesses');
    if (mine == null ||
        partner == null ||
        guesses == null ||
        partnerGuesses == null) {
      return null;
    }
    return RoundGuessScore(
      yours: List<bool>.generate(3, (i) => guesses[i] == partner[i]),
      partners: List<bool>.generate(3, (i) => partnerGuesses[i] == mine[i]),
    );
  }
}

class RoundScoreCard extends StatelessWidget {
  const RoundScoreCard(
      {super.key,
      required this.round,
      required this.yourName,
      required this.partnerName});
  final Map<String, dynamic> round;
  final String yourName;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final score = RoundGuessScore.fromRound(round);
    if (score == null) {
      return const Text('Scores unavailable for this round.',
          style: TextStyle(color: Colors.black54));
    }
    return Semantics(
      label: '$yourName guessed ${score.yourCorrect} out of 3 correctly. '
          '$partnerName guessed ${score.partnerCorrect} out of 3 correctly.',
      child: Card(
        color: const Color(0xFFFFF0EA),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('How well did we guess?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Correct predictions of each other’s answers',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child:
                      _ScoreTile(name: yourName, correct: score.yourCorrect)),
              const SizedBox(width: 12),
              Expanded(
                  child: _ScoreTile(
                      name: partnerName, correct: score.partnerCorrect)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({required this.name, required this.correct});
  final String name;
  final int correct;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Text(name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              Text('$correct / 3',
                  style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC75E68))),
              const Text('correct', style: TextStyle(fontSize: 12)),
            ])),
      );
}

class RoundQuestionScore extends StatelessWidget {
  const RoundQuestionScore(
      {super.key,
      required this.round,
      required this.index,
      required this.yourName,
      required this.partnerName});
  final Map<String, dynamic> round;
  final int index;
  final String yourName;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final score = RoundGuessScore.fromRound(round);
    if (score == null || index < 0 || index >= score.questionCount) {
      return const SizedBox.shrink();
    }
    Widget line(String name, bool correct) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            Icon(correct ? Icons.check_circle_rounded : Icons.cancel_outlined,
                size: 18,
                color: correct
                    ? const Color(0xFF477E56)
                    : const Color(0xFFA36C68)),
            const SizedBox(width: 6),
            Flexible(
                child: Text(
                    '$name: ${correct ? 'Correct guess' : 'Different guess'}',
                    style: const TextStyle(fontSize: 13))),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      line(yourName, score.yours[index]),
      line(partnerName, score.partners[index]),
    ]);
  }
}
