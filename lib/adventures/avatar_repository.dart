import 'dart:convert';
import '../store.dart';
import 'avatar_model.dart';

class AvatarPair {
  const AvatarPair({
    required this.mine,
    required this.partner,
    required this.mineSaved,
    required this.partnerSaved,
  });

  final CoupleAvatar mine;
  final CoupleAvatar partner;
  final bool mineSaved;
  final bool partnerSaved;
}

/// Reads/writes the existing AppStore's local-demo preferences or Supabase RPCs.
/// Connected data is scoped to the current home on the database, not on client.
class AvatarRepository {
  AvatarRepository(this.store);
  final AppStore store;

  static const _demoMineKey = 'little_us_avatar_demo_a_v1';
  static const _demoPartnerKey = 'little_us_avatar_demo_b_v1';

  CoupleAvatar? _decodeDemo(String key) {
    final raw = store.prefs.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map) {
        return CoupleAvatar.fromJson(Map<String, dynamic>.from(json));
      }
    } catch (_) {
      // An invalid local value is treated as an unset avatar.
    }
    return null;
  }

  CoupleAvatar? _decodeRemote(dynamic value) {
    if (value is Map) {
      return CoupleAvatar.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  Future<AvatarPair> load() async {
    if (store.home == null) throw StateError('Open your shared home first.');
    if (store.demo) {
      final mine = _decodeDemo(_demoMineKey);
      final partner = _decodeDemo(_demoPartnerKey);
      return AvatarPair(
        mine: mine ?? const CoupleAvatar(),
        partner: partner ?? CoupleAvatar.partnerPlaceholder,
        mineSaved: mine != null,
        partnerSaved: partner != null,
      );
    }
    if (store.client?.auth.currentUser == null) {
      throw StateError('Please sign in again.');
    }
    final raw = await store.client!
        .rpc('get_couple_avatars')
        .timeout(const Duration(seconds: 15));
    final response = Map<String, dynamic>.from(raw as Map);
    final mine = _decodeRemote(response['mine']);
    final partner = _decodeRemote(response['partner']);
    return AvatarPair(
      mine: mine ?? const CoupleAvatar(),
      partner: partner ?? CoupleAvatar.partnerPlaceholder,
      mineSaved: mine != null,
      partnerSaved: partner != null,
    );
  }

  Future<void> saveMine(CoupleAvatar avatar) async {
    if (store.home == null) throw StateError('No shared home available.');
    if (store.demo) {
      await store.prefs.setString(_demoMineKey, jsonEncode(avatar.toJson()));
      return;
    }
    if (store.client?.auth.currentUser == null) {
      throw StateError('Please sign in again.');
    }
    await store.client!.rpc(
      'save_my_avatar',
      params: {'appearance': avatar.toJson()},
    ).timeout(const Duration(seconds: 15));
  }

  /// Called from AppStore.leave() when the offline demo is deleted.
  static Future<void> clearDemo(AppStore store) async {
    await store.prefs.remove(_demoMineKey);
    await store.prefs.remove(_demoPartnerKey);
  }
}
