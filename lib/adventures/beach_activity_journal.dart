import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Milestone 3C: PRIVATE ON-DEVICE drafts, not synced between partner devices.
/// Shared Supabase activities/rewards/postcards belong to Milestone 3D.
class BeachActivityRecord {
  const BeachActivityRecord(
      {required this.id,
      required this.summary,
      required this.completedAt,
      this.caption = ''});

  final String id;
  final String summary;
  final String completedAt;
  final String caption;

  Map<String, String> toJson() => {
        'id': id,
        'summary': summary,
        'completed_at': completedAt,
        'caption': caption,
      };
  factory BeachActivityRecord.fromJson(Map<String, dynamic> json) =>
      BeachActivityRecord(
        id: (json['id'] ?? '').toString(),
        summary: (json['summary'] ?? '').toString(),
        completedAt: (json['completed_at'] ?? '').toString(),
        caption: (json['caption'] ?? '').toString(),
      );
}

class BeachActivityJournal {
  const BeachActivityJournal(this.prefs, this.scope);
  final SharedPreferences prefs;
  final String scope;
  String get storageKey => 'little_us_beach_m3c_$scope';
  static const ids = {'picnic', 'shells', 'bench', 'photo'};

  Map<String, BeachActivityRecord> load() {
    final raw = prefs.getString(storageKey);
    if (raw == null) return {};
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return {};
      final result = <String, BeachActivityRecord>{};
      for (final entry in data.entries) {
        if (!ids.contains(entry.key) || entry.value is! Map) continue;
        final record = BeachActivityRecord.fromJson(
            Map<String, dynamic>.from(entry.value as Map));
        if (record.id == entry.key) result[record.id] = record;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> save(BeachActivityRecord record) async {
    if (!ids.contains(record.id)) throw ArgumentError.value(record.id, 'id');
    final updated = load()..[record.id] = record;
    final okay = await prefs.setString(storageKey,
        jsonEncode({for (final e in updated.entries) e.key: e.value.toJson()}));
    if (!okay)
      throw StateError('Could not save beach progress on this device.');
  }

  static Future<void> clear(SharedPreferences prefs, String? scope) async {
    if (scope != null) await prefs.remove('little_us_beach_m3c_$scope');
  }
}
