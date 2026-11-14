import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_destination.dart';

/// FCM is only for delivery. Supabase Auth and the SQL trigger are the source of truth.
/// No note text, drawing content, or secret guesses are delivered in push payloads.
class PushManager {
  PushManager({required this.client, required this.prefs, this.inDemo});
  static PushManager? instance;

  final SupabaseClient client;
  final bool Function()? inDemo;
  final SharedPreferences prefs;
  final ValueNotifier<bool> enabled = ValueNotifier(false);
  final ValueNotifier<PushDestination?> pending = ValueNotifier(null);
  final StreamController<PushDestination> _foreground =
      StreamController<PushDestination>.broadcast();
  Stream<PushDestination> get foreground => _foreground.stream;

  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<RemoteMessage>? _messages;
  StreamSubscription<AuthState>? _auth;
  String? _registeredToken;
  String? _lastUser;
  bool _started = false;

  String _prefKey(String uid) => 'little_us_push_enabled_$uid';

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _opened = FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
    _messages = FirebaseMessaging.onMessage.listen((message) {
      final destination = pushDestinationFromData(message.data);
      if (destination != null && enabled.value && !_foreground.isClosed) {
        _foreground.add(destination);
      }
    });
    _tokens = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) { unawaited(_onNewToken(token)); },
      onError: (Object e) => debugPrint('FCM token refresh failed: $e'),
    );
    _auth = client.auth.onAuthStateChange.listen((_) {
      unawaited(sync());
    });
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onOpened(initial);
    await sync();
  }

  void _onOpened(RemoteMessage message) {
    final destination = pushDestinationFromData(message.data);
    if (destination != null) pending.value = destination;
  }

  /// Call on app resume because iOS APNs may become available after startup.
  Future<void> sync() async {
    final user = client.auth.currentUser;
    if (user == null || (inDemo?.call() ?? false)) {
      _lastUser = null;
      _registeredToken = null;
      enabled.value = false;
      return;
    }
    if (_lastUser != user.id) {
      _lastUser = user.id;
      _registeredToken = null;
    }
    final wanted = prefs.getBool(_prefKey(user.id)) ?? false;
    enabled.value = wanted;
    if (!wanted) return;
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) return;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null) return; // Retry on resume; do not call getToken too early.
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
    } catch (e) {
      debugPrint('Push registration deferred: $e');
    }
  }

  Future<void> _onNewToken(String token) async {
    final user = client.auth.currentUser;
    if (user == null || prefs.getBool(_prefKey(user.id)) != true) return;
    try { await _register(token); } catch (e) {
      debugPrint('Push token registration failed: $e');
    }
  }

  Future<void> _register(String token) async {
    final user = client.auth.currentUser;
    if (user == null || prefs.getBool(_prefKey(user.id)) != true) return;
    if (token == _registeredToken) return;
    await client.rpc('push_register_token', params: {
      'p_token': token,
      'p_platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    });
    _registeredToken = token;
  }

  /// Called only after explicit user action from the settings card.
  Future<void> setEnabled(bool value) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Sign in to enable notifications.');
    if (value) {
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        throw StateError('Notifications are not allowed. Enable them in device Settings.');
      }
      await prefs.setBool(_prefKey(user.id), true);
      enabled.value = true;
      await sync();
      return;
    }
    await prefs.setBool(_prefKey(user.id), false);
    enabled.value = false;
    await _unregisterCurrentToken();
  }

  Future<void> _unregisterCurrentToken() async {
    final token = _registeredToken;
    if (token != null && client.auth.currentUser != null) {
      try {
        await client.rpc('push_unregister_token', params: {'p_token': token});
      } catch (e) {
        debugPrint('Push unregister deferred; invalidating FCM token: $e');
      }
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('FCM token invalidation failed: $e');
    }
    _registeredToken = null;
  }

  /// Must run BEFORE Supabase signs out or deletes the user's account.
  Future<void> beforeSignOut() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    await prefs.setBool(_prefKey(user.id), false);
    enabled.value = false;
    await _unregisterCurrentToken();
    _lastUser = null;
  }

  Future<void> dispose() async {
    await _tokens?.cancel();
    await _opened?.cancel();
    await _messages?.cancel();
    await _auth?.cancel();
    await _foreground.close();
    enabled.dispose();
    pending.dispose();
  }
}
