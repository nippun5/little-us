class Question {
  final String title;
  final List<String> options;
  const Question(this.title, this.options);
}

const questions = [
  Question('What is my ideal way to spend a Friday night?', [
    'Going out with friends',
    'Cozy night in with a movie',
    'Trying a new restaurant',
    'Working on a hobby or project',
  ]),
  Question('What is my absolute favorite comfort food?', [
    'Pizza or Burgers',
    'Mac and Cheese or Pasta',
    'Ice Cream or Chocolate',
    'Soup or Stew',
  ]),
  Question('How do I prefer to wake up in the morning?', [
    'Hitting snooze multiple times',
    'Jumping right out of bed',
    'Slowly with a cup of coffee/tea',
    'Scrolling on my phone',
  ]),
  Question('What is my biggest pet peeve?', [
    'Loud chewing',
    'People being late',
    'Being interrupted',
    'Messy spaces',
  ]),
  Question('Which movie genre do I lean towards the most?', [
    'Action or Sci-Fi',
    'Rom-Com or Drama',
    'Horror or Thriller',
    'Comedy or Animation',
  ]),
  Question('What is my dream vacation destination?', [
    'A tropical beach',
    'A bustling historic city',
    'A quiet mountain cabin',
    'An adventurous safari or trek',
  ]),
  Question('How do I handle stressful situations?', [
    'I need to talk it out',
    'I need space to process alone',
    'I try to fix the problem immediately',
    'I distract myself',
  ]),
  Question('What is my favorite season?', [
    'Spring',
    'Summer',
    'Autumn',
    'Winter',
  ]),
  Question('What kind of music do I listen to when I am driving alone?', [
    'Pop or Top 40',
    'Rock or Alternative',
    'Hip-Hop or R&B',
    'Podcasts or Audiobooks',
  ]),
  Question('What is my go-to drink order at a cafe?', [
    'Black coffee or espresso',
    'Sweet iced coffee or latte',
    'Hot tea or iced tea',
    'Something fruity or a smoothie',
  ]),
  Question('If I could have any superpower, what would it be?', [
    'Flying',
    'Invisibility',
    'Teleportation',
    'Reading minds',
  ]),
  Question('What is my favorite time of day?', [
    'Early morning',
    'Midday',
    'Late evening',
    'The dead of night',
  ]),
  Question('How do I usually express anger?', [
    'I get quiet and shut down',
    'I vent and raise my voice',
    'I become sarcastic',
    'I try to calmly explain why I am mad',
  ]),
  Question('What was my favorite subject in school?', [
    'Math or Science',
    'English or History',
    'Art or Music',
    'Physical Education',
  ]),
  Question('What is my preferred love language to receive?', [
    'Words of Affirmation',
    'Acts of Service',
    'Receiving Gifts',
    'Physical Touch',
  ]),
  Question('What is my worst habit?', [
    'Biting my nails',
    'Procrastinating',
    'Interrupting people',
    'Overthinking everything',
  ]),
  Question('What is my favorite way to exercise?', [
    'Lifting weights at the gym',
    'Running or cycling outdoors',
    'Yoga or stretching',
    'I prefer not to exercise',
  ]),
  Question(
      'If I won the lottery tomorrow, what is the very first thing I would buy?',
      [
        'A new house',
        'A luxury car',
        'A first-class plane ticket',
        'Pay off all my debt',
      ]),
  Question('What is my favorite type of weather?', [
    'Sunny and hot',
    'Crisp and cool',
    'Rainy and gray',
    'Snowy',
  ]),
  Question('How do I feel about roller coasters?', [
    'I absolutely love them',
    'I will go on them but I am scared',
    'I completely refuse to ride them',
    'I only like the gentle ones',
  ]),
  Question('What is my go-to midnight snack?', [
    'Chips or popcorn',
    'Cookies or candy',
    'Leftovers from dinner',
    'Cereal or toast',
  ]),
  Question('Which chore do I hate doing the most?', [
    'Doing the dishes',
    'Folding laundry',
    'Cleaning the bathroom',
    'Vacuuming or sweeping',
  ]),
  Question('What is my favorite thing to do on a lazy Sunday?', [
    'Binge-watch a TV show',
    'Read a good book',
    'Sleep in until noon',
    'Tackle a small project at my own pace',
  ]),
  Question('How do I prefer to communicate during the day?', [
    'Texting constantly',
    'One or two phone calls',
    'Sending memes and voice notes',
    'I prefer waiting until we see each other',
  ]),
  Question('What is my attitude towards spicy food?', [
    'The spicier the better',
    'I like a little bit of a kick',
    'I can barely handle black pepper',
    'I only eat it if I have to',
  ]),
  Question('What is my biggest irrational fear?', [
    'Spiders or bugs',
    'Heights',
    'The dark',
    'Clowns or dolls',
  ]),
  Question('What kind of sleeper am I?', [
    'A very heavy sleeper',
    'A light sleeper who wakes up at everything',
    'I toss and turn all night',
    'I talk or walk in my sleep',
  ]),
  Question(
      'If I had to eat one cuisine for the rest of my life, what would it be?',
      [
        'Mexican',
        'Italian',
        'Asian (Chinese, Thai, Japanese)',
        'Classic American',
      ]),
  Question('What is my favorite part of our relationship?', [
    'Our deep conversations',
    'How much we laugh together',
    'The physical affection',
    'Knowing I always have a partner',
  ]),
  Question('How do I react to surprises?', [
    'I love them and get super excited',
    'I hate not knowing what is happening',
    'I get awkward and do not know how to react',
    'I try to guess them before they happen',
  ]),
  Question('What is my favorite type of clothing to wear?', [
    'Athleisure or sweatpants',
    'Dressed up and stylish',
    'Jeans and a t-shirt',
    'Cozy oversized sweaters',
  ]),
  Question('What would be my ideal pet?', [
    'A playful dog',
    'An independent cat',
    'Something exotic like a reptile',
    'No pets for me',
  ]),
  Question('How do I feel about horror movies?', [
    'I love the thrill',
    'I will watch them but hide my eyes',
    'I absolutely refuse to watch them',
    'I just think they are funny',
  ]),
  Question('What is my usual role in a group of friends?', [
    'The loud and funny one',
    'The planner and organizer',
    'The quiet observer',
    'The "mom" or "dad" of the group',
  ]),
  Question('What is my favorite holiday?', [
    'Christmas or winter holidays',
    'Halloween',
    'My birthday',
    'Thanksgiving',
  ]),
  Question('If we are ordering takeout, what is my first choice?', [
    'Pizza',
    'Sushi',
    'Indian',
    'Thai',
  ]),
  Question('What is my preferred way to travel long distances?', [
    'Flying',
    'Taking a scenic train',
    'Driving on a road trip',
    'Taking a bus',
  ]),
  Question('What is my favorite type of dessert?', [
    'Cake or cupcakes',
    'Pie or cobbler',
    'Brownies or cookies',
    'Ice cream or gelato',
  ]),
  Question('How do I organize my phone apps?', [
    'By color',
    'In specific folders',
    'Alphabetical order',
    'Total chaos, no organization',
  ]),
  Question('What is my biggest goal in life right now?', [
    'Advancing my career',
    'Starting or growing a family',
    'Traveling the world',
    'Finding inner peace and happiness',
  ]),
  Question('What is my go-to alcoholic or non-alcoholic party drink?', [
    'Beer or cider',
    'Wine or champagne',
    'A mixed cocktail',
    'Just soda or water',
  ]),
  Question('How many alarms do I set in the morning?', [
    'Just one, and I am up',
    'Two or three to be safe',
    'Five or more, I cannot wake up',
    'I wake up naturally without an alarm',
  ]),
  Question('What was my favorite cartoon growing up?', [
    'SpongeBob SquarePants',
    'Tom and Jerry',
    'Scooby-Doo',
    'Avatar: The Last Airbender',
  ]),
  Question('What is my preferred seating at a movie theater?', [
    'Right in the front row',
    'Dead center',
    'Way in the back',
    'On the aisle for easy bathroom access',
  ]),
  Question('How do I prefer to read books?', [
    'Physical paperbacks or hardcovers',
    'On an e-reader or tablet',
    'Audiobooks',
    'I do not really read books',
  ]),
  Question('What is my favorite physical feature of yours?', [
    'Your eyes',
    'Your smile',
    'Your hair',
    'Your body',
  ]),
  Question('What is my favorite non-physical feature of yours?', [
    'Your sense of humor',
    'Your intelligence',
    'Your kindness',
    'Your ambition',
  ]),
  Question('What do I usually do when I am sick?', [
    'Act like a big baby and want to be taken care of',
    'Deny I am sick and keep working',
    'Sleep for 14 hours straight',
    'WebMD my symptoms and panic',
  ]),
  Question('What is my favorite board game or card game?', [
    'Monopoly or strategy games',
    'Cards Against Humanity or party games',
    'Uno or classic card games',
    'Scrabble or word games',
  ]),
  Question('How do I handle my finances?', [
    'I track every single penny I spend',
    'I save well but splurge occasionally',
    'I spend it as soon as I make it',
    'I avoid looking at my bank account',
  ]),
  Question('What is my favorite fast food chain?', [
    'McDonald\'s',
    'Taco Bell',
    'Wendy\'s',
    'Chick-fil-A',
  ]),
  Question('What is my attitude towards camping?', [
    'I love roughing it in a tent',
    'I will only go if there is an RV or cabin',
    'Absolutely not, take me to a hotel',
    'I like the campfire, but not the sleeping part',
  ]),
  Question('What is my favorite flower or plant?', [
    'Roses',
    'Sunflowers',
    'Succulents or Cacti',
    'Tulips or Lilies',
  ]),
  Question('What is the best gift I have ever received?', [
    'Something expensive and flashy',
    'Something sentimental and handmade',
    'An experience like a trip or concert',
    'Something highly practical I needed',
  ]),
  Question(
      'How do I usually behave at parties where I do not know many people?', [
    'I stick right by your side the whole time',
    'I awkwardly stand in the corner on my phone',
    'I introduce myself to everyone',
    'I find the host\'s pet and hang out with them',
  ]),
  Question('What is my favorite social media app?', [
    'Instagram',
    'TikTok',
    'Twitter/X',
    'Reddit',
  ]),
  Question('What is my typical shower routine?', [
    'In and out in 5 minutes',
    'Long, scalding hot showers',
    'Singing concerts in the shower',
    'I prefer taking baths',
  ]),
  Question('What do I value most in a friendship?', [
    'Loyalty and trust',
    'Having fun and laughing',
    'Deep emotional support',
    'Shared interests and hobbies',
  ]),
  Question('What is my favorite breakfast food?', [
    'Pancakes or waffles',
    'Eggs and bacon',
    'Just a bagel or toast',
    'A healthy smoothie or oatmeal',
  ]),
  Question('How do I like my steak cooked?', [
    'Rare',
    'Medium Rare',
    'Medium Well',
    'Well Done',
  ]),
  Question('What is my favorite memory of us?', [
    'Our very first date',
    'Our first trip together',
    'The moment we said "I love you"',
    'A random, simple quiet moment at home',
  ]),
  Question('If I could live in any era, which would it be?', [
    'The Roaring 1920s',
    'The Groovy 1970s',
    'The Neon 1980s',
    'Right now in the present',
  ]),
  Question('What is my most used emoji?', [
    'The crying laughing face 😂',
    'The red heart ❤️',
    'The skull 💀',
    'The pleading eyes 🥺',
  ]),
  Question('What is my favorite thing to buy at the grocery store?', [
    'Fresh fruit and veggies',
    'Snacks and junk food',
    'Fancy cheeses or meats',
    'Something from the bakery',
  ]),
  Question('How do I handle getting lost?', [
    'I stubbornly refuse to ask for directions',
    'I immediately pull up Google Maps',
    'I panic and get stressed out',
    'I view it as an unexpected adventure',
  ]),
  Question('What is my favorite smell?', [
    'Freshly brewed coffee',
    'Vanilla or baked goods',
    'Campfires and pine trees',
    'Clean laundry',
  ]),
  Question('What is my biggest insecurity?', [
    'My physical appearance',
    'My career or financial status',
    'Worrying if people actually like me',
    'Failing at my goals',
  ]),
  Question('What is my favorite childhood memory?', [
    'Family vacations',
    'Playing outside with neighborhood kids',
    'Holidays and birthdays',
    'A specific achievement in school or sports',
  ]),
  Question('How do I feel about public speaking?', [
    'I am totally comfortable with it',
    'I get nervous but I can do it',
    'I am absolutely terrified of it',
    'I actually enjoy being the center of attention',
  ]),
  Question('What is my favorite type of cheese?', [
    'Cheddar',
    'Brie or Camembert',
    'Mozzarella',
    'Pepper Jack',
  ]),
  Question('What is my favorite thing to do at an amusement park?', [
    'Ride the biggest, scariest roller coasters',
    'Eat all the theme park food',
    'Play the carnival games',
    'Walk around and people-watch',
  ]),
  Question('How do I like to spend my birthday?', [
    'A big party with all my friends',
    'A romantic dinner for two',
    'A quiet day at home doing nothing',
    'Traveling somewhere new',
  ]),
  Question('What is my favorite ice cream flavor?', [
    'Vanilla Bean',
    'Chocolate Fudge',
    'Mint Chocolate Chip',
    'Cookie Dough',
  ]),
  Question('What is my stance on New Year\'s resolutions?', [
    'I make a strict list and stick to it',
    'I make them but forget by February',
    'I think they are silly and do not make them',
    'I set broad, general goals instead',
  ]),
  Question('If I could only watch one TV show forever, what would it be?', [
    'The Office or Friends',
    'Breaking Bad or The Sopranos',
    'Game of Thrones',
    'A reality TV show',
  ]),
  Question('What is my favorite color to wear?', [
    'Black or gray',
    'Bright colors like red or yellow',
    'Earth tones like green or brown',
    'Pastels',
  ]),
  Question('How do I feel about PDA (Public Displays of Affection)?', [
    'I love holding hands and kissing in public',
    'I am okay with holding hands, but that is it',
    'I think it is awkward and avoid it',
    'I only do it to make other people uncomfortable',
  ]),
  Question('What is my favorite kind of chocolate?', [
    'Milk chocolate',
    'Dark chocolate',
    'White chocolate',
    'I do not like chocolate',
  ]),
  Question('What is my dream car?', [
    'A fast sports car',
    'A huge luxury SUV',
    'A vintage classic car',
    'An eco-friendly electric car',
  ]),
  Question('What is my least favorite food?', [
    'Mushrooms',
    'Olives',
    'Seafood',
    'Tomatoes',
  ]),
  Question('How do I prepare for a trip?', [
    'I pack a week in advance with a checklist',
    'I throw things in a bag the night before',
    'I pack the morning of the flight',
    'I make you pack for me',
  ]),
  Question('What is my favorite animal at the zoo?', [
    'Monkeys and apes',
    'Big cats (lions, tigers)',
    'Elephants or giraffes',
    'Reptiles and snakes',
  ]),
  Question('What is my favorite type of art to look at?', [
    'Classic paintings',
    'Modern abstract art',
    'Photography',
    'Sculptures',
  ]),
  Question('What is my attitude toward working out?', [
    'I genuinely love it and look forward to it',
    'I do it just because I have to',
    'I struggle to stay consistent',
    'I avoid it at all costs',
  ]),
  Question('What is my favorite type of bread?', [
    'Sourdough',
    'Garlic bread',
    'Croissants',
    'Whole wheat',
  ]),
  Question(
      'If I had a completely free day, what is the first thing I would do?', [
    'Sleep in as late as possible',
    'Go outside for a hike or walk',
    'Play video games all day',
    'Call my family or friends',
  ]),
  Question('What is my favorite way to cool down in the summer?', [
    'Swimming in a pool or the ocean',
    'Sitting inside with the AC on blast',
    'Eating ice cream or popsicles',
    'Drinking ice-cold beer or lemonade',
  ]),
  Question('What is my favorite thing to do on a long flight?', [
    'Sleep the entire time',
    'Watch three movies back-to-back',
    'Read a book or magazine',
    'Stare at the map tracker',
  ]),
  Question('What do I think is my best quality?', [
    'My intelligence',
    'My sense of humor',
    'My loyalty',
    'My work ethic',
  ]),
  Question('What is my favorite way that we connect as a couple?', [
    'Cooking a meal together',
    'Cuddling on the couch',
    'Having deep conversations late at night',
    'Going on fun, active dates',
  ]),
];
List<Question> dailyQuestions(String day) {
  final date = DateTime.parse('${day}T00:00:00Z');
  final offset = (date.millisecondsSinceEpoch ~/ 86400000 % 30) * 3;
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
