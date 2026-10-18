import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show MemoryImage;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'fridge_widget.dart';
import 'accessories.dart';

class AppStore extends ChangeNotifier {
  AppStore(this.prefs, {this.client, FridgeBridge? fridgeBridge})
    : fridgeBridge = fridgeBridge ?? NativeFridgeBridge();
  final FridgeBridge fridgeBridge;
  final SharedPreferences prefs;
  final SupabaseClient? client;
  bool demo = false, busy = false;
  String? error;
  Map<String, dynamic>? home;
  List<Map<String, dynamic>> notes = [], rounds = [];
  String day = utcDay();
  Map<String, dynamic>? pet;
  List<String> petCareToday = [];
  String currentRoom = 'living';
  String? widgetError;
  List<Map<String, dynamic>> frames = [];
  final Map<String, Uint8List> frameBytes = {};
  final Map<String, String> _frameRevisions = {};
  String? photoError;
  String? _photoScope;
  String get petAccessory => pet?['accessory'] ?? 'none';
  List<String> get ownedAccessories =>
      List<String>.from(pet?['accessories'] ?? []);

  void _clearPhotos() {
    for (final bytes in frameBytes.values) {
      unawaited(MemoryImage(bytes).evict());
    }
    frames = [];
    frameBytes.clear();
    _frameRevisions.clear();
    photoError = null;
    _photoScope = null;
  }

  Future<void> refreshFrames() async {
    if (demo ||
        !signedIn ||
        home == null ||
        !unlockedRooms.contains('bedroom')) {
      return;
    }
    final scope = widgetScope;
    final generation = _generation;
    bool current() =>
        !_disposed &&
        generation == _generation &&
        scope == widgetScope &&
        !demo;
    if (_photoScope != scope) {
      _clearPhotos();
      _photoScope = scope;
    }
    try {
      final rows = List<Map<String, dynamic>>.from(
        await client!
            .rpc('get_bedroom_frames')
            .timeout(const Duration(seconds: 15)),
      );
      if (!current()) return;
      frames = rows;
      final owners = rows.map((r) => r['owner'] as String).toSet();
      frameBytes.removeWhere((id, _) => !owners.contains(id));
      _frameRevisions.removeWhere((id, _) => !owners.contains(id));
      for (final frame in rows) {
        final owner = frame['owner'] as String;
        final revision = frame['revision'] as String?;
        if (revision == null) {
          frameBytes.remove(owner);
          _frameRevisions.remove(owner);
          continue;
        }
        if (_frameRevisions[owner] == revision) continue;
        // Remove outdated pixels even if the subsequent download fails.
        frameBytes.remove(owner);
        _frameRevisions.remove(owner);
        final bytes = await client!.storage
            .from('bedroom-frames')
            .download(frame['path'] as String)
            .timeout(const Duration(seconds: 20));
        if (!current()) return;
        frameBytes[owner] = bytes;
        _frameRevisions[owner] = revision;
      }
      photoError = null;
    } catch (_) {
      if (current()) photoError = 'Photos could not sync. Pull down to retry.';
    }
  }

  Future<void> uploadFrame(Uint8List jpeg, String expectedScope) async {
    if (home == null ||
        widgetScope != expectedScope ||
        !unlockedRooms.contains('bedroom')) {
      throw const PostgrestException(
        message: 'Your home changed. Choose the photo again.',
      );
    }
    if (jpeg.length > 1048576 ||
        jpeg.length < 3 ||
        jpeg[0] != 255 ||
        jpeg[1] != 216) {
      throw const PostgrestException(
        message: 'Choose a JPEG smaller than 1 MB.',
      );
    }
    if (demo) {
      frameBytes[me] = jpeg;
    } else {
      final path = '${home!['id']}/$me.jpg';
      await client!.storage
          .from('bedroom-frames')
          .uploadBinary(
            path,
            jpeg,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '0',
              upsert: true,
            ),
          );
      _frameRevisions.remove(me);
      await refresh();
    }
    notifyListeners();
  }

  Future<void> removeMyFrame() async {
    if (home == null) return;
    if (demo) {
      frameBytes.remove(me);
    } else {
      await client!.storage.from('bedroom-frames').remove([
        '${home!['id']}/$me.jpg',
      ]);
      frameBytes.remove(me);
      _frameRevisions.remove(me);
      await refresh();
    }
    notifyListeners();
  }

  Future<void> equipAccessory(String item) async {
    final selected = petAccessories.where((a) => a.id == item).firstOrNull;
    if (pet == null || selected == null) {
      throw const PostgrestException(
        message: 'Adopt a pet and choose an accessory.',
      );
    }
    if (demo) {
      final price = ownedAccessories.contains(item) ? 0 : selected.price;
      if (coins < price) {
        throw const PostgrestException(
          message: 'Complete more rounds together to earn hearts.',
        );
      }
      home!['coins'] = coins - price;
      if (item != 'none' && !ownedAccessories.contains(item)) {
        pet!['accessories'] = [...ownedAccessories, item];
      }
      pet!['accessory'] = item;
      await persist();
    } else {
      await client!.rpc('equip_pet_accessory', params: {'item': item});
      await refresh();
    }
    notifyListeners();
  }

  Future<void> cancelPhotoCleanup() async {
    if (!demo) await client!.rpc('cancel_frame_cleanup');
    await refresh();
  }

  Future<void> _deleteHomeWithPhotos({required bool account}) async {
    try {
      final paths = List<String>.from(await client!.rpc('begin_frame_cleanup'));
      if (paths.isNotEmpty) {
        await client!.storage.from('bedroom-frames').remove(paths);
      }
      await client!.rpc(account ? 'delete_my_account' : 'leave_home');
      _clearPhotos();
    } catch (_) {
      // If connectivity is lost, a visible Resume uploads action unlocks it later.
      try {
        await client!.rpc('cancel_frame_cleanup');
      } catch (_) {}
      rethrow;
    }
  }

  String? _lastScope, _widgetFingerprint;
  DateTime? _lastWidgetWrite;
  bool _refreshing = false;
  bool _disposed = false;
  Future<void> _refreshQueue = Future.value();
  int _generation = 0;
  List<String> get unlockedRooms =>
      List<String>.from(home?['unlocked_rooms'] ?? ['living']);
  String get roomTheme => currentRoom == 'living'
      ? theme
      : (home?['room_themes']?[currentRoom] ?? 'peach');
  String get roomName =>
      const {
        'living': 'Living room',
        'bedroom': 'Bedroom',
        'garden': 'Garden',
      }[currentRoom] ??
      'Living room';
  String? get widgetScope => home == null
      ? null
      : demo
      ? 'demo'
      : '${client?.auth.currentUser?.id}:${home!['id']}';
  bool get widgetEnabled =>
      widgetScope != null &&
      prefs.getBool('fridge_enabled_$widgetScope') == true;
  String? get pinnedNoteId =>
      widgetScope == null ? null : prefs.getString('fridge_pin_$widgetScope');
  Map<String, dynamic>? get widgetNote {
    final id = pinnedNoteId;
    if (id != null) {
      for (final n in notes) {
        if (n['id'] == id) return n;
      }
    }
    for (final n in notes) {
      if (n['author_id'] != null
          ? n['author_id'] != me
          : demo && n['author'] != myName) {
        return n;
      }
    }
    return null;
  }

  int get petLevel => 1 + ((pet?['xp'] ?? 0) as int) ~/ 20;

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
    if (!demo && !signedIn) await syncFridgeWidget();
    auth = client?.auth.onAuthStateChange.listen((_) {
      if (!demo) refresh();
    });
    if (signedIn && !demo) await refresh();
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!busy && !_refreshing && (demo || signedIn)) refresh();
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
          : e is StorageException
          ? 'Photo storage: ${e.message}'
          : e is FormatException
          ? e.message
          : 'Could not connect. Check your connection and try again.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> startDemo() async {
    _generation++;
    _clearPhotos();
    demo = true;
    final raw = prefs.getString('demo_state');
    if (raw != null) {
      final d = jsonDecode(raw);
      home = Map<String, dynamic>.from(d['home']);
      notes = List<Map<String, dynamic>>.from(d['notes']);
      rounds = List<Map<String, dynamic>>.from(d['rounds']);
      pet = d['pet'] == null ? null : Map<String, dynamic>.from(d['pet']);
      petCareToday = d['care_day'] == day
          ? List<String>.from(d['pet_care'] ?? [])
          : [];
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
          'author_id': 'demo-b',
          'author': 'Jamie',
          'body':
              'Found a little café we would love. Saving you the window seat.',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
      rounds = [];
    }
    _restoreRoom();
    await prefs.setBool('demo', true);
    await persist();
    notifyListeners();
  }

  Future<void> persist() async {
    if (demo) {
      await prefs.setString(
        'demo_state',
        jsonEncode({
          'home': home,
          'notes': notes,
          'rounds': rounds,
          'pet': pet,
          'pet_care': petCareToday,
          'care_day': day,
        }),
      );
    }
    await syncFridgeWidget();
  }

  Future<void> refresh() {
    final task = _refreshQueue
        .catchError((Object _) {})
        .then((_) => _refreshNow());
    _refreshQueue = task;
    return task;
  }

  Future<void> _refreshNow() async {
    if (_disposed) return;
    _refreshing = true;
    final generation = _generation;
    final userId = client?.auth.currentUser?.id;
    try {
      if (demo) {
        final nextDay = utcDay();
        if (day != nextDay) {
          day = nextDay;
          petCareToday = [];
          await persist();
        }
        await syncFridgeWidget();
        notifyListeners();
        return;
      }
      if (!signedIn) {
        home = null;
        _clearPhotos();
        notes = [];
        rounds = [];
        pet = null;
        petCareToday = [];
        _restoreRoom();
        await syncFridgeWidget();
        notifyListeners();
        return;
      }
      final data = Map<String, dynamic>.from(
        await client!.rpc('get_home').timeout(const Duration(seconds: 15)),
      );
      if (generation != _generation ||
          demo ||
          userId != client?.auth.currentUser?.id) {
        return;
      }
      home = data['home'] == null
          ? null
          : Map<String, dynamic>.from(data['home']);
      notes = List<Map<String, dynamic>>.from(data['notes'] ?? []);
      rounds = List<Map<String, dynamic>>.from(data['rounds'] ?? []);
      pet = data['pet'] == null ? null : Map<String, dynamic>.from(data['pet']);
      petCareToday = List<String>.from(data['pet_care_today'] ?? []);
      day = data['day'];
      if (home == null || _photoScope != widgetScope) _clearPhotos();
      await refreshFrames();
      if (generation != _generation ||
          demo ||
          userId != client?.auth.currentUser?.id) {
        return;
      }
      error = null;
      _restoreRoom();
      await syncFridgeWidget();
      notifyListeners();
    } catch (_) {
      if (generation == _generation) {
        error =
            'Unable to sync. Your last loaded home is shown. Pull down to retry.';
        notifyListeners();
      }
    } finally {
      _refreshing = false;
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
        'author_id': me,
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
      if (currentRoom == 'living') {
        home!['theme'] = id;
      } else {
        home!['room_themes'] = {
          ...Map<String, dynamic>.from(home!['room_themes'] ?? {}),
          currentRoom: id,
        };
      }
      await persist();
    } else {
      await client!.rpc(
        'decorate_room',
        params: {'room': currentRoom, 'item': id},
      );
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
    _generation++;
    if (!demo) await client?.auth.signOut();
    demo = false;
    _clearPhotos();
    home = null;
    notes = [];
    rounds = [];
    error = null;
    pet = null;
    petCareToday = [];
    currentRoom = 'living';
    _lastScope = null;
    await syncFridgeWidget();
    await prefs.setBool('demo', false);
    notifyListeners();
  }

  Future<void> leave() async {
    if (demo) {
      await prefs.remove('fridge_enabled_demo');
      await prefs.remove('fridge_pin_demo');
      await prefs.remove('room_demo');
      await prefs.remove('demo_state');
      await signOut();
    } else {
      await _deleteHomeWithPhotos(account: false);
      await refresh();
    }
  }

  Future<void> deleteAccount() async {
    if (demo) {
      await leave();
      return;
    }
    await _deleteHomeWithPhotos(account: true);
    _generation++;
    home = null;
    notes = [];
    rounds = [];
    pet = null;
    petCareToday = [];
    await syncFridgeWidget();
    await client!.auth.signOut(scope: SignOutScope.local);
    await refresh();
  }

  void _restoreRoom() {
    if (_lastScope != widgetScope) {
      currentRoom = prefs.getString('room_$widgetScope') ?? 'living';
      _lastScope = widgetScope;
    }
    if (!unlockedRooms.contains(currentRoom)) currentRoom = 'living';
  }

  Future<void> selectRoom(String room) async {
    if (!unlockedRooms.contains(room)) {
      throw const PostgrestException(message: 'Unlock this room first.');
    }
    currentRoom = room;
    await prefs.setString('room_$widgetScope', room);
    notifyListeners();
  }

  Future<void> unlockRoom(String room) async {
    final cost = const {'bedroom': 80, 'garden': 120}[room];
    if (cost == null) throw const PostgrestException(message: 'Unknown room.');
    if (demo) {
      if (!unlockedRooms.contains(room)) {
        if (coins < cost) {
          throw const PostgrestException(
            message: 'Complete more rounds together to unlock this room.',
          );
        }
        home!['coins'] = coins - cost;
        home!['unlocked_rooms'] = [...unlockedRooms, room];
        await persist();
      }
    } else {
      await client!.rpc('unlock_room', params: {'room': room});
      await refresh();
    }
    if (unlockedRooms.contains(room)) await selectRoom(room);
  }

  Future<void> adoptPet(String kind, String name) async {
    if (!['cat', 'dog'].contains(kind) ||
        name.trim().isEmpty ||
        name.trim().length > 20) {
      throw const PostgrestException(
        message: 'Choose a pet and a name of 1–20 characters.',
      );
    }
    if (demo) {
      if (pet != null) {
        throw const PostgrestException(message: 'Your home already has a pet.');
      }
      pet = {'kind': kind, 'name': name.trim(), 'xp': 0};
      await persist();
    } else {
      await client!.rpc(
        'adopt_pet',
        params: {'pet_kind': kind, 'pet_name': name.trim()},
      );
      await refresh();
    }
    notifyListeners();
  }

  Future<void> renamePet(String name) async {
    if (name.trim().isEmpty || name.trim().length > 20 || pet == null) {
      throw const PostgrestException(message: 'Use a name of 1–20 characters.');
    }
    if (demo) {
      pet!['name'] = name.trim();
      await persist();
    } else {
      await client!.rpc('rename_pet', params: {'pet_name': name.trim()});
      await refresh();
    }
    notifyListeners();
  }

  Future<void> careForPet(String action) async {
    if (pet == null || !['feed', 'play'].contains(action)) {
      throw const PostgrestException(message: 'Adopt a pet first.');
    }
    if (demo) {
      if (day != utcDay()) {
        day = utcDay();
        petCareToday = [];
      }
      if (!petCareToday.contains(action)) {
        petCareToday.add(action);
        pet!['xp'] = (pet!['xp'] as int) + (action == 'feed' ? 2 : 3);
        await persist();
      }
    } else {
      await client!.rpc('care_for_pet', params: {'care_action': action});
      await refresh();
    }
    notifyListeners();
  }

  Future<void> setWidgetEnabled(bool value) async {
    if (widgetScope == null) return;
    await prefs.setBool('fridge_enabled_$widgetScope', value);
    await syncFridgeWidget(force: true);
    notifyListeners();
  }

  Future<void> pinWidgetNote(String? noteId) async {
    if (widgetScope == null) return;
    if (noteId == null) {
      await prefs.remove('fridge_pin_$widgetScope');
    } else {
      await prefs.setString('fridge_pin_$widgetScope', noteId);
    }
    await setWidgetEnabled(true);
  }

  Future<void> syncFridgeWidget({bool force = false}) async {
    final note = home == null ? null : widgetNote;
    final enabled = widgetEnabled;
    final data = <String, Object?>{
      'enabled': enabled,
      'body': enabled
          ? (note?['body'] ?? 'Your next little note will appear here.')
          : '',
      'author': enabled ? (note?['author'] ?? 'Little us') : '',
      'demo': demo && enabled,
    };
    final fingerprint = jsonEncode(data);
    final now = DateTime.now();
    if (!force &&
        fingerprint == _widgetFingerprint &&
        _lastWidgetWrite != null &&
        now.difference(_lastWidgetWrite!) < const Duration(minutes: 15)) {
      return;
    }
    try {
      await fridgeBridge.update({
        ...data,
        'updatedAt': now.millisecondsSinceEpoch,
      });
      _widgetFingerprint = fingerprint;
      _lastWidgetWrite = now;
      widgetError = null;
    } catch (_) {
      widgetError =
          'Widget could not update. Check the native widget installation and, on iOS, the shared App Group.';
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    timer?.cancel();
    auth?.cancel();
    super.dispose();
  }
}
