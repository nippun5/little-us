import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Locally bundled, original little sound effects. No network connection.
class PetAudio {
  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;
  DateTime _lastPlay = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> react(String kind) async {
    if (_disposed) return;
    final now = DateTime.now();
    if (now.difference(_lastPlay) < const Duration(milliseconds: 450)) return;
    _lastPlay = now;
    try {
      await _player.stop();
      if (_disposed) return;
      await _player.play(
        AssetSource(
            kind == 'cat' ? 'audio/kitten_meow.wav' : 'audio/puppy_bark.wav'),
        volume: .45,
      );
    } catch (_) {
      // Animation still works when sound is disabled by the device or platform.
    }
  }

  void dispose() {
    _disposed = true;
    unawaited(_player.dispose());
  }
}
