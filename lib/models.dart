class Question {
  final String title;
  final List<String> options;
  const Question(this.title, this.options);
}

const questions = [
  Question('My perfect slow Sunday?', [
    'Coffee & a book',
    'A little adventure',
    'Movies in bed',
    'Cooking together',
  ]),
  Question('What makes me feel most loved?', [
    'A thoughtful note',
    'Time together',
    'A little surprise',
    'Words of affection',
  ]),
  Question('Our next dream date?', [
    'A sunset picnic',
    'A cozy café',
    'A mountain cabin',
    'A seaside walk',
  ]),
  Question('My comfort food mood?', [
    'Something spicy',
    'Something sweet',
    'A warm bowl',
    'Your cooking',
  ]),
  Question('How do I recharge?', [
    'Quiet time',
    'A long walk',
    'Talking it out',
    'Music on repeat',
  ]),
  Question('A tiny thing I love?', [
    'Morning messages',
    'Inside jokes',
    'Your voice',
    'Shared playlists',
  ]),
  Question('My dream weekend away?', [
    'A lively city',
    'The mountains',
    'The beach',
    'A tiny village',
  ]),
  Question('My favorite kind of surprise?', [
    'A handwritten letter',
    'An unexpected visit',
    'A handmade gift',
    'A planned date',
  ]),
  Question('What should we learn together?', [
    'A new recipe',
    'A dance',
    'A language',
    'A creative hobby',
  ]),
  Question('My ideal rainy evening?', [
    'Board games',
    'A movie marathon',
    'Baking cookies',
    'Talking for hours',
  ]),
  Question('Which little adventure calls me?', [
    'A museum',
    'A food market',
    'A forest trail',
    'A train ride',
  ]),
  Question('What would I save from our dates?', [
    'A photo',
    'A ticket stub',
    'A voice note',
    'A tiny souvenir',
  ]),
  Question('When do I feel most creative?', [
    'Early morning',
    'Late at night',
    'On a walk',
    'When we talk',
  ]),
  Question('My favorite way to celebrate?', [
    'Dinner out',
    'A quiet night in',
    'A little trip',
    'Friends together',
  ]),
  Question('What would I put in our home?', [
    'A reading nook',
    'A big kitchen',
    'A sunny balcony',
    'A music corner',
  ]),
  Question('A message I would love today?', [
    'I am proud of you',
    'I miss your laugh',
    'You have got this',
    'Tell me everything',
  ]),
  Question('Our ideal shared hobby?', [
    'Gardening',
    'Photography',
    'Gaming',
    'Baking',
  ]),
  Question('Which season feels like us?', [
    'Fresh spring',
    'Golden summer',
    'Cozy autumn',
    'Quiet winter',
  ]),
  Question('My favorite travel moment?', [
    'Planning together',
    'The journey',
    'Exploring',
    'Coming home',
  ]),
  Question('My kind of good morning?', [
    'A voice note',
    'A funny photo',
    'A sweet message',
    'A quick call',
  ]),
  Question('What do I want more of?', [
    'Small adventures',
    'Slow moments',
    'Deep conversations',
    'Silly laughter',
  ]),
];
List<Question> dailyQuestions(String day) {
  final date = DateTime.parse('${day}T00:00:00Z');
  final offset = (date.millisecondsSinceEpoch ~/ 86400000 % 7) * 3;
  return questions.sublist(offset, offset + 3);
}

String utcDay() => DateTime.now().toUtc().toIso8601String().substring(0, 10);

class Decoration {
  final String id, name, caption;
  final int price;
  const Decoration(this.id, this.name, this.caption, this.price);
}

const decorations = [
  Decoration('peach', 'Peach daydream', 'A little warmth for your sofa', 0),
  Decoration('lilac', 'Lavender afternoon', 'A softer shade of together', 60),
  Decoration('mint', 'Matcha morning', 'Fresh, calm, and perfectly us', 60),
  Decoration('rose', 'Rose-colored days', 'A room with a little romance', 90),
];
