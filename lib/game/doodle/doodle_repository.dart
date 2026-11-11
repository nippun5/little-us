import 'dart:convert';
import '../../store.dart';
import 'doodle_model.dart';

/// Only server RPCs can access a real couple's doodles. No direct table writes.
class DoodleRepository {
  DoodleRepository(this.store);
  final AppStore store;
  static const _demoKey = 'little_us_finish_my_doodle_demo_v1';

  Future<List<CoupleDoodle>> list() async {
    if (store.demo) {
      final raw = store.prefs.getString(_demoKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List<dynamic>)
          .map(
              (e) => CoupleDoodle.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (!store.paired || store.client == null) return [];
    final raw = await store.client!
        .rpc('doodle_list')
        .timeout(const Duration(seconds: 15));
    return (raw as List<dynamic>)
        .map((e) => CoupleDoodle.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> start(String prompt, List<DoodleStroke> strokes) async {
    final error = DoodleRules.validate(strokes);
    if (error != null) throw FormatException(error);
    if (!DoodleRules.prompts.contains(prompt)) {
      throw const FormatException('Choose a drawing prompt.');
    }
    if (store.demo) {
      final rows = await _demoRows();
      if (rows.any((r) => r['is_finished'] != true)) {
        throw const FormatException(
            'Finish the open doodle before starting another.');
      }
      if (rows.length >= 40) {
        throw const FormatException(
            'Your doodle gallery is full. Remove an old one first.');
      }
      rows.insert(0, {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'prompt': prompt,
        'starter_name': store.myName,
        'is_mine': true,
        'is_finished': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'starter_strokes': DoodleRules.encode(strokes),
        'finish_strokes': <dynamic>[],
      });
      await _saveDemo(rows);
      return;
    }
    await store.client!.rpc('doodle_start', params: {
      'p_prompt': prompt,
      'p_strokes': DoodleRules.encode(strokes),
    }).timeout(const Duration(seconds: 15));
  }

  Future<void> finish(String id, List<DoodleStroke> strokes) async {
    final error = DoodleRules.validate(strokes);
    if (error != null) throw FormatException(error);
    if (store.demo) {
      throw const FormatException(
          'Demo mode: use Simulate partner finishing instead.');
    }
    await store.client!.rpc('doodle_finish', params: {
      'p_id': id,
      'p_strokes': DoodleRules.encode(strokes),
    }).timeout(const Duration(seconds: 15));
  }

  /// The demo partner is simulated and never contacts another account.
  Future<void> simulateDemoPartner(String id) async {
    if (!store.demo) return;
    final rows = await _demoRows();
    final i = rows.indexWhere((r) => r['id'] == id && r['is_finished'] != true);
    if (i < 0) throw const FormatException('This doodle was already finished.');
    const added = DoodleStroke(
      color: '#DE6B83',
      width: 5,
      points: [
        DoodlePoint(.34, .48),
        DoodlePoint(.39, .41),
        DoodlePoint(.49, .51),
        DoodlePoint(.59, .41),
        DoodlePoint(.65, .48),
        DoodlePoint(.49, .68),
        DoodlePoint(.34, .48),
      ],
    );
    rows[i]['finish_strokes'] = DoodleRules.encode([added]);
    rows[i]['is_finished'] = true;
    await _saveDemo(rows);
  }

  Future<void> delete(String id) async {
    if (store.demo) {
      final rows = await _demoRows();
      rows.removeWhere((r) => r['id'] == id);
      await _saveDemo(rows);
      return;
    }
    await store.client!.rpc('doodle_delete',
        params: {'p_id': id}).timeout(const Duration(seconds: 15));
  }

  Future<List<Map<String, dynamic>>> _demoRows() async {
    final raw = store.prefs.getString(_demoKey);
    return raw == null
        ? []
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
  }

  Future<void> _saveDemo(List<Map<String, dynamic>> rows) async {
    await store.prefs.setString(_demoKey, jsonEncode(rows));
  }
}
