import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'store.dart';
import 'room.dart';
import 'room_scenes.dart';
import 'v2_features.dart';
import 'v3_features.dart';

const ink = Color(0xFF443747),
    muted = Color(0xFF817580),
    coral = Color(0xFFC75E68),
    cream = Color(0xFFFFFAF4),
    lilac = Color(0xFFEDE3F6),
    mint = Color(0xFFE2EFE5);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL'),
      key = String.fromEnvironment('SUPABASE_ANON_KEY');
  SupabaseClient? client;
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: key);
    client = Supabase.instance.client;
  }
  final store = AppStore(await SharedPreferences.getInstance(), client: client);
  await store.init();
  if (const bool.fromEnvironment('SCREENSHOT')) await store.startDemo();
  runApp(LittleUs(store: store));
}

class LittleUs extends StatelessWidget {
  const LittleUs({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Little us',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(seedColor: coral, surface: cream),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 15, color: ink),
        bodyLarge: TextStyle(fontSize: 16, color: ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: coral,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5DCD9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5DCD9)),
        ),
      ),
    ),
    home: AnimatedBuilder(
      animation: store,
      builder: (context, _) =>
          store.home != null ? HomeShell(store: store) : Welcome(store: store),
    ),
  );
}

Widget heading(String text, {double size = 30}) => Text(
  text,
  style: TextStyle(
    fontFamily: 'Lora',
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: ink,
    height: 1.18,
  ),
);
Widget small(String text) =>
    Text(text, style: const TextStyle(color: muted, fontSize: 13, height: 1.5));
Widget pill(String text, {Color color = lilac, IconData? icon}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(30),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 15, color: ink),
        const SizedBox(width: 5),
      ],
      Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
    ],
  ),
);
Widget card({
  required Widget child,
  Color color = Colors.white,
  EdgeInsets padding = const EdgeInsets.all(20),
}) => Container(
  width: double.infinity,
  padding: padding,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0x0C443747)),
  ),
  child: child,
);

class Welcome extends StatefulWidget {
  const Welcome({super.key, required this.store});
  final AppStore store;
  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      code = TextEditingController();
  bool signup = false, join = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_rounded, color: coral),
                    const SizedBox(width: 8),
                    heading('Little us', size: 28),
                  ],
                ),
                const SizedBox(height: 30),
                const Room(theme: 'peach'),
                const SizedBox(height: 28),
                heading(
                  s.signedIn
                      ? 'Make room for two.'
                      : 'A little home.\nA whole lot of us.',
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  s.signedIn
                      ? 'Create a private home or join your favorite person.'
                      : 'Play, leave little love notes, and grow closer—even when you are far apart.',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (s.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(s.error!, style: const TextStyle(color: coral)),
                  ),
                if (s.signedIn) ...[
                  TextField(
                    controller: name,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: 'Your first name',
                    ),
                  ),
                  if (join)
                    TextField(
                      controller: code,
                      decoration: const InputDecoration(
                        labelText: 'Invite code',
                        helperText: 'Paste the code your partner shared.',
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: s.busy
                        ? null
                        : () {
                            if (name.text.trim().isEmpty ||
                                (join && code.text.trim().isEmpty)) {
                              return;
                            }
                            s.run(
                              () => s.pair(name.text, join ? code.text : null),
                            );
                          },
                    child: Text(join ? 'Join our home' : 'Create our home'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => join = !join),
                    child: Text(
                      join
                          ? 'Create a new home instead'
                          : 'I have an invite code',
                    ),
                  ),
                  TextButton(
                    onPressed: () => s.run(s.signOut),
                    child: const Text('Sign out'),
                  ),
                ] else ...[
                  if (s.client != null) ...[
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password (at least 8 characters)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: s.busy
                          ? null
                          : () {
                              if (!email.text.contains('@') ||
                                  password.text.length < 8) {
                                setState(
                                  () => s.error =
                                      'Enter a valid email and a password of at least 8 characters.',
                                );
                                return;
                              }
                              s.run(
                                () =>
                                    s.login(email.text, password.text, signup),
                              );
                            },
                      child: Text(signup ? 'Create account' : 'Welcome back'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => signup = !signup),
                      child: Text(
                        signup
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                  ],
                  OutlinedButton(
                    onPressed: s.busy ? null : () => s.run(s.startDemo),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(17),
                    ),
                    child: const Text('Explore the demo home'),
                  ),
                  const SizedBox(height: 12),
                  small(
                    s.client == null
                        ? 'Demo build · Changes stay on this device. Connect Supabase to invite your partner.'
                        : 'Demo mode is local. Shared homes use your connected account.',
                  ),
                ],
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => showPolicy(context),
                  child: const Text('Privacy & your data'),
                ),
                if (s.busy) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final AppStore store;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) s.refresh();
  }

  int tab = const int.fromEnvironment('START_TAB');

  void selectTab(int value) {
    setState(() => tab = value);
  }

  AppStore get s => widget.store;
  Future<void> date() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final chosen = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(s.home?['reunion'] ?? '')?.isAfter(now) == true
          ? DateTime.parse(s.home!['reunion'])
          : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'When do we meet again?',
    );
    if (chosen != null) await s.run(() => s.reunion(chosen));
  }

  Future<void> note() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: heading('A little love note', size: 24),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Something only you would say…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(c, controller.text);
              }
            },
            child: const Text('Leave note'),
          ),
        ],
      ),
    );
    // Controller belongs to the route animation until its transition finishes.
    if (text != null) await s.run(() => s.addNote(text));
  }

  Future<void> confirm(
    String title,
    String body,
    Future<void> Function() action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok == true) await s.run(action);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              if (s.busy) const LinearProgressIndicator(minHeight: 2),
              if (s.error != null)
                MaterialBanner(
                  content: Text(s.error!),
                  actions: [
                    TextButton(
                      onPressed: s.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: s.refresh,
                  child: ListView(
                    key: ValueKey(tab),
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: lilac,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: coral,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: heading('Little us', size: 23)),
                          pill(
                            '${s.coins}',
                            color: const Color(0xFFFFEAC5),
                            icon: Icons.favorite_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...switch (tab) {
                        0 => homePage(),
                        1 => playPage(),
                        2 => notesPage(),
                        3 => shopPage(),
                        _ => settingsPage(),
                      },
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      height: 76,
      backgroundColor: cream,
      indicatorColor: lilac,
      selectedIndex: tab,
      onDestinationSelected: selectTab,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.cottage_outlined),
          selectedIcon: Icon(Icons.cottage_rounded),
          label: 'Our home',
        ),
        NavigationDestination(
          icon: Icon(Icons.style_outlined),
          selectedIcon: Icon(Icons.style),
          label: 'Play',
        ),
        NavigationDestination(
          icon: Icon(Icons.mail_outline_rounded),
          selectedIcon: Icon(Icons.mail_rounded),
          label: 'Notes',
        ),
        NavigationDestination(
          icon: Icon(Icons.chair_outlined),
          selectedIcon: Icon(Icons.chair),
          label: 'Decorate',
        ),
        NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Us'),
      ],
    ),
  );
  List<Widget> homePage() => [
    Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              small('OUR HAPPY LITTLE PLACE'),
              const SizedBox(height: 6),
              heading('Better, together.'),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        pill(
          '${s.myName} + ${s.partner}',
          color: mint,
          icon: Icons.favorite_border,
        ),
        if (s.demo) small('Demo home'),
      ],
    ),
    const SizedBox(height: 18),
    RoomPicker(store: s),
    const SizedBox(height: 12),
    RoomScene(
      room: s.currentRoom,
      theme: s.roomTheme,
      petKind: s.pet?['kind'],
      accessory: s.petAccessory,
      bedroomFrames: BedroomWallFrames(store: s),
      onPlay: () => selectTab(1),
      onNote: note,
      onDate: date,
    ),
    const SizedBox(height: 8),
    Center(
      child: small(
        s.currentRoom == 'living'
            ? 'Tap the cards, calendar, or note to explore.'
            : '${s.roomName} · a little more space for us.',
      ),
    ),
    const SizedBox(height: 16),
    if (s.currentRoom == 'bedroom') BedroomPhotoPanel(store: s),
    PetPanel(store: s),
    PetAccessoriesPanel(store: s),
    const SizedBox(height: 20),
    InkWell(
      onTap: () => selectTab(1),
      borderRadius: BorderRadius.circular(24),
      child: card(
        color: lilac,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  small('A LITTLE CLOSER, EVERY DAY'),
                  const SizedBox(height: 7),
                  heading('How well do\nyou know me?', size: 25),
                  const SizedBox(height: 10),
                  const Text(
                    '3 questions · 2 hearts · 1 little ritual',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
            Container(
              width: 62,
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.favorite_rounded, color: coral, size: 35),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    ),
    const SizedBox(height: 16),
    InkWell(
      onTap: date,
      borderRadius: BorderRadius.circular(24),
      child: card(
        color: const Color(0xFFFFEDD9),
        child: Row(
          children: [
            const Icon(
              Icons.wb_sunny_outlined,
              color: Color(0xFFAB7137),
              size: 34,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading(reunionLabel(), size: 23),
                  small(
                    s.home?['reunion'] == null
                        ? 'Set a date to look forward to'
                        : 'Until our next hello in person',
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 18),
          ],
        ),
      ),
    ),
    if (!s.paired) ...[const SizedBox(height: 16), inviteCard()],
    const SizedBox(height: 22),
    Row(
      children: [
        Expanded(child: heading('On the fridge', size: 22)),
        TextButton(onPressed: note, child: const Text('+ Leave a note')),
      ],
    ),
    if (s.notes.isEmpty)
      small('A blank page for your first little message.')
    else
      noteCard(s.notes.first, 0),
  ];
  String reunionLabel() {
    final d = DateTime.tryParse(s.home?['reunion'] ?? '');
    if (d == null) return 'Our next hello';
    final days = d.difference(DateUtils.dateOnly(DateTime.now())).inDays;
    return days > 0
        ? '$days sleeps to go'
        : days == 0
        ? 'Today is the day!'
        : 'Plan our next hello';
  }

  Widget inviteCard() => card(
    color: mint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('There is room for two.', size: 22),
        const SizedBox(height: 8),
        small(
          'Share this private invite code with your partner. It expires after 7 days.',
        ),
        const SizedBox(height: 12),
        SelectableText(
          s.home?['invite'] ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: s.home?['invite'] ?? '')),
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy invite'),
        ),
        TextButton(
          onPressed: () => s.run(() async {
            await s.client!.rpc('renew_invite');
            await s.refresh();
          }),
          child: const Text('Generate a fresh code'),
        ),
      ],
    ),
  );
  List<Widget> playPage() => [
    small('YOUR DAILY DOSE OF US'),
    const SizedBox(height: 7),
    heading('Know me better.', size: 33),
    const SizedBox(height: 10),
    const Text(
      'A few guesses. A little discovery.\nAlways something new to love.',
      style: TextStyle(color: muted, height: 1.5),
    ),
    const SizedBox(height: 24),
    card(
      color: lilac,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              pill('TODAY’S CHAPTER', color: Colors.white),
              const Spacer(),
              const Icon(Icons.auto_awesome, color: Color(0xFF9770B2)),
            ],
          ),
          const SizedBox(height: 22),
          heading('The little things\nthat make you, you.', size: 29),
          const SizedBox(height: 16),
          ...dailyQuestions(s.day).map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border, size: 17, color: coral),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: s.busy || !s.paired ? null : () => openRound(s.today),
              child: Text(
                s.today?['complete'] == true
                    ? 'See our answers'
                    : s.today?['submitted'] == true
                    ? 'Waiting for your person'
                    : 'Let’s play',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: small('+30 shared hearts when you both finish')),
        ],
      ),
    ),
    const SizedBox(height: 16),
    card(
      color: mint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: Color(0xFF61836B)),
          const SizedBox(width: 12),
          Expanded(
            child: small(
              'Answers stay a surprise until you both finish. You can play at different times. No perfect scores needed.',
            ),
          ),
        ],
      ),
    ),
    if (!s.paired) ...[const SizedBox(height: 16), inviteCard()],
    if (s.demo && s.today?['submitted'] == true && s.today?['complete'] != true)
      TextButton(
        onPressed: () => s.run(s.simulatePartner),
        child: const Text('Demo: simulate partner finishing'),
      ),
    const SizedBox(height: 24),
    heading('Our little discoveries', size: 23),
    const SizedBox(height: 12),
    if (s.rounds.where((r) => r['complete'] == true).isEmpty)
      small('Your completed rounds will feel right at home here.')
    else
      ...s.rounds
          .where((r) => r['complete'] == true)
          .map(
            (r) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: lilac,
                child: Icon(Icons.favorite_outline, color: coral),
              ),
              title: Text('A little closer · ${r['day']}'),
              subtitle: const Text('Your answers, side by side'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openRound(r),
            ),
          ),
    const SizedBox(height: 16),
    small('New chapter at midnight UTC · 21 prompts rotate weekly.'),
  ];
  void openRound(Map<String, dynamic>? round) {
    if (round?['submitted'] == true && round?['complete'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your answers are saved. Come back when your partner finishes.',
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          store: s,
          completed: round?['complete'] == true ? round : null,
        ),
      ),
    );
  }

  Widget noteCard(Map<String, dynamic> n, int i) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: card(
      color: [const Color(0xFFFFEDB9), lilac, mint][i % 3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: small(
                  'A LITTLE NOTE FROM ${(n['author'] as String).toUpperCase()}',
                ),
              ),
              const Icon(Icons.push_pin_outlined, size: 18, color: muted),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            n['body'],
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 20,
              color: ink,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: small('Just for us')),
              IconButton(
                tooltip: s.pinnedNoteId == n['id']
                    ? 'Pinned to widget'
                    : 'Pin to phone widget',
                onPressed: s.busy
                    ? null
                    : () => pinFridgeNote(context, s, n['id']),
                icon: Icon(
                  s.pinnedNoteId == n['id']
                      ? Icons.push_pin
                      : Icons.add_to_home_screen,
                  size: 19,
                  color: coral,
                ),
              ),
              IconButton(
                tooltip: 'Delete note',
                visualDensity: VisualDensity.compact,
                onPressed: () => confirm(
                  'Delete this note?',
                  'This removes the note for both people.',
                  () => s.removeNote(n['id']),
                ),
                icon: const Icon(Icons.delete_outline, size: 18, color: muted),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  List<Widget> notesPage() => [
    small('WORDS TO COME HOME TO'),
    const SizedBox(height: 7),
    heading('Little love notes.', size: 33),
    const SizedBox(height: 20),
    FridgeWidgetPanel(store: s),
    const SizedBox(height: 12),
    small('For the big feelings and the everyday things.'),
    const SizedBox(height: 20),
    FilledButton.icon(
      onPressed: s.busy ? null : note,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Leave a little note'),
    ),
    const SizedBox(height: 24),
    if (s.notes.isEmpty)
      card(
        color: mint,
        child: const Text('Your fridge is waiting for its first love note.'),
      ),
    ...s.notes.asMap().entries.map((e) => noteCard(e.value, e.key)),
  ];
  List<Widget> shopPage() => [
    small('MAKE IT FEEL LIKE US'),
    const SizedBox(height: 7),
    heading('A home, your way.', size: 33),
    const SizedBox(height: 12),
    small('Earn hearts by showing up for each other.'),
    const SizedBox(height: 20),
    RoomPicker(store: s),
    const SizedBox(height: 12),
    RoomScene(
      room: s.currentRoom,
      theme: s.roomTheme,
      petKind: s.pet?['kind'],
      accessory: s.petAccessory,
      bedroomFrames: BedroomWallFrames(store: s),
    ),
    const SizedBox(height: 22),
    Row(
      children: [
        Expanded(child: heading('${s.roomName} colors', size: 23)),
        pill('4 colors', color: mint),
      ],
    ),
    const SizedBox(height: 14),
    ...decorations.map(
      (d) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: card(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 58,
                decoration: BoxDecoration(
                  color: sofaColor(d.id).withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.chair_rounded,
                  color: sofaColor(d.id),
                  size: 36,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    small(
                      s.owned.contains(d.id)
                          ? 'Yours to keep'
                          : '${d.price} hearts',
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: s.busy || s.roomTheme == d.id
                    ? null
                    : () => s.run(() => s.decorate(d.id)),
                child: Text(
                  s.roomTheme == d.id
                      ? 'In our home'
                      : s.owned.contains(d.id)
                      ? 'Use'
                      : 'Get',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    const SizedBox(height: 8),
    small('Hearts are earned in the app. No purchases, no pressure.'),
  ];
  List<Widget> settingsPage() => [
    small('OUR CORNER OF THE WORLD'),
    const SizedBox(height: 7),
    heading('${s.myName} & ${s.partner}', size: 31),
    const SizedBox(height: 22),
    card(
      color: lilac,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(
            s.demo ? 'You’re in the demo.' : 'Your private little home.',
            size: 24,
          ),
          const SizedBox(height: 10),
          small(
            s.demo
                ? 'Explore freely. Nothing is sent to a partner. Demo changes are saved on this device.'
                : 'Your home syncs every 15 seconds while the app is open. Pull down to refresh sooner.',
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    if (!s.paired) inviteCard(),
    FridgeWidgetPanel(store: s),
    const SizedBox(height: 12),
    ListTile(
      leading: const Icon(Icons.calendar_month_outlined),
      title: const Text('Our next meeting'),
      subtitle: Text(reunionLabel()),
      onTap: date,
    ),
    ListTile(
      leading: const Icon(Icons.privacy_tip_outlined),
      title: const Text('Privacy & your data'),
      onTap: () => showPolicy(context),
    ),
    ListTile(
      leading: const Icon(Icons.logout),
      title: Text(s.demo ? 'Exit demo' : 'Sign out'),
      onTap: () => s.run(s.signOut),
    ),
    ListTile(
      leading: const Icon(Icons.link_off),
      title: Text(s.demo ? 'Reset demo home' : 'Leave and erase shared home'),
      subtitle: const Text(
        'Removes notes, rounds, photos, and decorations for both.',
      ),
      onTap: () => confirm(
        'Erase this home?',
        'This permanently removes all shared content for both partners. Your account remains unless you choose Delete account.',
        s.leave,
      ),
    ),
    ListTile(
      leading: const Icon(Icons.delete_forever_outlined, color: coral),
      title: Text(
        s.demo ? 'Delete local demo data' : 'Delete account',
        style: const TextStyle(color: coral),
      ),
      onTap: () => confirm(
        'Delete account and home?',
        'This permanently deletes your account and the entire shared home, including your partner’s access to its contents. This cannot be undone.',
        s.deleteAccount,
      ),
    ),
    const SizedBox(height: 24),
    Center(
      child: small('Little us · made for the little moments\nVersion 2.1.0'),
    ),
  ];
}

class RoundScreen extends StatefulWidget {
  const RoundScreen({super.key, required this.store, this.completed});
  final AppStore store;
  final Map<String, dynamic>? completed;
  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> {
  int step = 0;
  final answers = List<int>.filled(3, -1), guesses = List<int>.filled(3, -1);
  bool submitting = false;
  late final String roundDay = widget.completed?['day'] ?? widget.store.day;
  @override
  Widget build(BuildContext context) {
    final s = widget.store,
        qs = dailyQuestions(roundDay),
        done = widget.completed;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text('Know me better'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: done != null
                  ? [
                      pill(
                        'A LITTLE CLOSER',
                        color: mint,
                        icon: Icons.favorite_outline,
                      ),
                      const SizedBox(height: 20),
                      heading('Every answer is\na little discovery.', size: 33),
                      const SizedBox(height: 14),
                      small(
                        'You earned 30 shared hearts for showing up together.',
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: card(
                            color: i.isEven ? lilac : mint,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                heading(qs[i].title, size: 23),
                                const SizedBox(height: 16),
                                Text(
                                  '${s.myName}: ${qs[i].options[done['mine'][i]]}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${s.partner}: ${qs[i].options[done['partner'][i]]}',
                                ),
                                const Divider(height: 28),
                                small(
                                  'You guessed: ${qs[i].options[done['guesses'][i]]}',
                                ),
                                small(
                                  'They guessed: ${qs[i].options[done['partner_guesses'][i]]}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back to our home'),
                      ),
                    ]
                  : [
                      Row(
                        children: [
                          pill('QUESTION ${step + 1} OF 3', color: lilac),
                          const Spacer(),
                          small('No wrong feelings'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: (step + 1) / 3,
                        color: coral,
                        backgroundColor: lilac,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 28),
                      heading(qs[step].title, size: 32),
                      const SizedBox(height: 24),
                      small('FIRST, YOUR ANSWER'),
                      const SizedBox(height: 10),
                      ...List.generate(
                        4,
                        (i) => choice(
                          qs[step].options[i],
                          answers[step] == i,
                          () => setState(() => answers[step] = i),
                        ),
                      ),
                      const SizedBox(height: 22),
                      small('NOW, GUESS ${s.partner.toUpperCase()}’S ANSWER'),
                      const SizedBox(height: 10),
                      ...List.generate(
                        4,
                        (i) => choice(
                          qs[step].options[i],
                          guesses[step] == i,
                          () => setState(() => guesses[step] = i),
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (s.error != null)
                        Text(s.error!, style: const TextStyle(color: coral)),
                      FilledButton(
                        onPressed:
                            submitting || answers[step] < 0 || guesses[step] < 0
                            ? null
                            : () async {
                                if (step < 2) {
                                  setState(() => step++);
                                  return;
                                }
                                setState(() => submitting = true);
                                await s.run(
                                  () => s.submit(
                                    answers,
                                    guesses,
                                    forDay: roundDay,
                                  ),
                                );
                                if (!mounted || !context.mounted) return;
                                setState(() => submitting = false);
                                if (s.error == null) Navigator.pop(context);
                              },
                        child: Text(
                          submitting
                              ? 'Saving…'
                              : step < 2
                              ? 'Next little question'
                              : 'Save my answers',
                        ),
                      ),
                      if (step > 0)
                        TextButton(
                          onPressed: submitting
                              ? null
                              : () => setState(() => step--),
                          child: const Text('Previous question'),
                        ),
                      const SizedBox(height: 12),
                      small(
                        'Answers unlock only when you both finish. Daily rounds use UTC.',
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget choice(String text, bool selected, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: submitting ? null : action,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected ? lilac : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF9C7CBA)
                  : const Color(0xFFE8DFDC),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: selected ? const Color(0xFF87609F) : muted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void showPolicy(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (c) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: MediaQuery.sizeOf(c).height * .7,
        child: ListView(
          children: [
            heading('Privacy, with care.'),
            const Text(
              'Bedroom photos are optional and shared only with your home. Each partner controls one frame. Photos are resized and rebuilt without location metadata, stored privately, and removed when you erase the shared home. Pet accessory ownership and the equipped item are shared. Photos are not placed in the fridge widget.',
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 18),
            const Text(
              'Demo mode stores your home, notes, game answers, and preferences on this device. It does not send them to a partner. Delete local demo data in Us to erase them.\n\nConnected mode uses Supabase for authentication and storage. Your email, account ID, chosen name, notes, answers, guesses, home decorations, and reunion date are processed to provide your shared home. Your paired partner can see shared content; answers are hidden until both finish a round. Invite codes should only be shared privately.\n\nVersion 2 also stores your unlocked rooms, room colors, pet name/species, bond XP, and daily pet-care actions. If you enable the home-screen widget, a copy of the selected note, author, and sync time is saved on this device and shared with the operating system widget. No account tokens are shared with the widget. Anyone who can see your home screen may see the note. Turn the widget off or sign out to clear the local snapshot; an offline widget may keep an old note until this app syncs, and the operating system controls when it redraws.\n\nThere are no ads, analytics SDKs, location tracking, or in-app purchases in this version. This app does not provide end-to-end encryption. Network data uses HTTPS. Authentication tokens are persisted by the authentication SDK on this device.\n\nDelete individual notes in Notes. Leave and erase shared home removes the entire home for both people. Delete account also removes your sign-in account. Your partner’s account remains. Hosting-provider logs and backups may remain according to the deployed service’s retention settings.\n\nBefore public release, the operator must publish the supplied full policy with their contact information and verified retention details.',
              style: TextStyle(height: 1.65),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Back to our little home'),
            ),
          ],
        ),
      ),
    ),
  ),
);
