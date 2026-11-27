import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Installation identity, not a login credential. Future Firebase auth links
/// its UID to this ID rather than replacing IDs embedded in local saves.
class PlayerIdentity {
  PlayerIdentity._(this.id, this.saved);
  final String id;
  final Future<bool> saved;
  static const key = 'player_id_v1';
  static final _sessions = Expando<PlayerIdentity>();
  static final _valid = RegExp(r'^[a-f0-9]{32}$');

  static String generateId() {
    final random = Random.secure();
    return List.generate(
            16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static PlayerIdentity load(SharedPreferences preferences) {
    final existing = _sessions[preferences];
    if (existing != null) return existing;
    final stored = preferences.get(key);
    final valid = stored is String && _valid.hasMatch(stored);
    final id = valid ? stored : generateId();
    final identity = PlayerIdentity._(
        id, valid ? Future.value(true) : _save(preferences, id, stored));
    _sessions[preferences] = identity;
    return identity;
  }

  static Future<bool> _save(
      SharedPreferences preferences, String id, Object? broken) async {
    try {
      if (broken != null) {
        await preferences.setString('${key}_broken', broken.toString());
      }
      final ok = await preferences.setString(key, id);
      if (!ok) debugPrint('PlayerIdentity: could not save installation ID');
      return ok;
    } catch (error) {
      debugPrint('PlayerIdentity: could not save installation ID ($error)');
      return false;
    }
  }
}
