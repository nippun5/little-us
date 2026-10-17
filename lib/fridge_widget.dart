import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Widgets receive only a selected note snapshot, never Supabase credentials.
abstract class FridgeBridge {
  bool get supported;
  Future<void> update(Map<String, Object?> snapshot);
  Future<bool> requestPin();
}

class NativeFridgeBridge implements FridgeBridge {
  static const channel = MethodChannel('little_us/fridge_widget');
  Future<void> _queue = Future.value();
  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  @override
  Future<void> update(Map<String, Object?> snapshot) {
    if (!supported) return Future.value();
    // Serialize snapshots, so a sign-out clear cannot be overtaken by an old write.
    final operation = _queue.catchError((Object _) {}).then((_) async {
      await channel.invokeMethod<void>('update', snapshot);
    });
    _queue = operation;
    return operation;
  }

  @override
  Future<bool> requestPin() async {
    if (!supported) return false;
    return await channel.invokeMethod<bool>('requestPin') ?? false;
  }
}
