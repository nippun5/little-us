import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class AppStore extends ChangeNotifier {
  AppStore(this.prefs, {this.client});
  final SharedPreferences prefs;
  final SupabaseClient? client;
  bool demo = false, busy = false;
  String? error;
  Map<String, dynamic>? home;
  List<Map<String, dynamic>> notes = [], rounds = [];
  String day = utcDay();
  Timer? timer;
  StreamSubscription<AuthState>? auth;
  bool get signedIn => client?.auth.currentUser != null;
  String get me => demo ? 'demo-a' : client!.auth.currentUser!.id;
  bool get isA => home?['a'] == me;
  String get myName => home?[isA ? 'a_name' : 'b_name'] ?? 'You';
  String get partner => home?[isA ? 'b_name' : 'a_name'] ?? 'Your person';
  bool get paired => home?['b'] != null;
  int get coins => home?['coins'] ?? 0;
  String get theme => home?['theme'] ?? 'peach';
  List<String> get owned => List<String>.from(home?['owned'] ?? ['peach']);
  Map<String, dynamic>? get today {
    for (final r in rounds) {
      if (r['day'] == day) return r;
    }
    return null;
  }

  Future<void> init() async {
    if (prefs.getBool('demo') == true) await startDemo();
    auth = client?.auth.onAuthStateChange.listen((_) {
      if (!demo) refresh();
    });
    if (signedIn && !demo) await refresh();
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!busy && (demo || signedIn)) refresh();
    });
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e is AuthException
          ? e.message
          : e is PostgrestException
          ? e.message
          : 'Could not connect. Check your connection and try again.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> startDemo() async {
    demo = true;
    final raw = prefs.getString('demo_state');
    if (raw != null) {
      final d = jsonDecode(raw);
      home = Map<String, dynamic>.from(d['home']);
      notes = List<Map<String, dynamic>>.from(d['notes']);
      rounds = List<Map<String, dynamic>>.from(d['rounds']);
    } else {
      home = {
        'a': 'demo-a',
        'b': 'demo-b',
        'a_name': 'Alex',
        'b_name': 'Jamie',
        'coins': 120,
        'theme': 'peach',
        'owned': ['peach'],
        'reunion': DateTime.now()
            .add(const Duration(days: 24))
            .toIso8601String()
            .substring(0, 10),
      };
      notes = [
        {
          'id': 'welcome',
          'author': 'Jamie',
          'body':
              'Found a little café we would love. Saving you the window seat.',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
      rounds = [];
    }
    await prefs.setBool('demo', true);
    await persist();
    notifyListeners();
  }

  Future<void> persist() async {
    if (demo) {
      await prefs.setString(
        'demo_state',
        jsonEncode({'home': home, 'notes': notes, 'rounds': rounds}),
      );
    }
  }

  Future<void> refresh() async {
    try {
      if (demo) {
        day = utcDay();
        notifyListeners();
        return;
      }
      if (!signedIn) {
        home = null;
        notes = [];
        rounds = [];
        notifyListeners();
        return;
      }
      final data = Map<String, dynamic>.from(await client!.rpc('get_home'));
      home = data['home'] == null
          ? null
          : Map<String, dynamic>.from(data['home']);
      notes = List<Map<String, dynamic>>.from(data['notes'] ?? []);
      rounds = List<Map<String, dynamic>>.from(data['rounds'] ?? []);
      day = data['day'];
      error = null;
      notifyListeners();
    } catch (_) {
      error =
          'Unable to sync. Your last loaded home is shown. Pull down to retry.';
      notifyListeners();
    }
  }

  Future<void> login(String email, String password, bool signup) async {
    if (signup) {
      final r = await client!.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (r.session == null) {
        error = 'Check your email to confirm your account, then sign in.';
        return;
      }
    } else {
      await client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    }
    await refresh();
  }

  Future<void> pair(String name, String? code) async {
    await client!.rpc(
      code == null ? 'create_home' : 'join_home',
      params: code == null
          ? {'display_name': name.trim()}
          : {'display_name': name.trim(), 'invite': code.trim()},
    );
    await refresh();
  }

  Future<void> addNote(String text) async {
    if (demo) {
      notes.insert(0, {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'author': myName,
        'body': text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      await persist();
    } else {
      await client!.rpc('add_note', params: {'body': text.trim()});
      await refresh();
    }
    notifyListeners();
  }

  Future<void> removeNote(String id) async {
    if (demo) {
      notes.removeWhere((n) => n['id'] == id);
      await persist();
    } else {
      await client!.rpc('remove_note', params: {'note_id': id});
      await refresh();
    }
    notifyListeners();
  }

  Future<void> decorate(String id) async {
    final item = decorations.firstWhere((i) => i.id == id);
    if (demo) {
      if (!owned.contains(id)) {
        if (coins < item.price) {
          throw const PostgrestException(
            message: 'Complete more rounds to earn hearts.',
          );
        }
        home!['coins'] = coins - item.price;
        home!['owned'] = [...owned, id];
      }
      home!['theme'] = id;
      await persist();
    } else {
      await client!.rpc('decorate', params: {'item': id});
      await refresh();
    }
    notifyListeners();
  }

  Future<void> reunion(DateTime date) async {
    final s = date.toIso8601String().substring(0, 10);
    if (demo) {
      home!['reunion'] = s;
      await persist();
    } else {
      await client!.rpc('set_reunion', params: {'target': s});
      await refresh();
    }
    notifyListeners();
  }

  Future<void> submit(
    List<int> answers,
    List<int> guesses, {
    String? forDay,
  }) async {
    final targetDay = forDay ?? day;
    if (targetDay != day) {
      throw const PostgrestException(
        message: 'A new day has started. Reopen the daily round.',
      );
    }
    if (demo) {
      if (today != null) return;
      rounds.insert(0, {
        'day': day,
        'submitted': true,
        'complete': false,
        'mine': answers,
        'guesses': guesses,
      });
      await persist();
    } else {
      await client!.rpc(
        'submit_round',
        params: {
          'round_day': targetDay,
          'answers': answers,
          'guesses': guesses,
        },
      );
      await refresh();
    }
    notifyListeners();
  }

  Future<void> simulatePartner() async {
    if (!demo || today == null || today!['complete'] == true) return;
    today!['complete'] = true;
    today!['partner'] = [1, 2, 0];
    today!['partner_guesses'] = [0, 1, 2];
    home!['coins'] = coins + 30;
    await persist();
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!demo) await client?.auth.signOut();
    demo = false;
    home = null;
    notes = [];
    rounds = [];
    error = null;
    await prefs.setBool('demo', false);
    notifyListeners();
  }

  Future<void> leave() async {
    if (demo) {
      await prefs.remove('demo_state');
      await signOut();
    } else {
      await client!.rpc('leave_home');
      await refresh();
    }
  }

  Future<void> deleteAccount() async {
    if (demo) {
      await leave();
      return;
    }
    await client!.rpc('delete_my_account');
    await client!.auth.signOut(scope: SignOutScope.local);
    await refresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    auth?.cancel();
    super.dispose();
  }
}
