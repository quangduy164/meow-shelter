import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'visual_state.dart';

/// Persistent room codes/metadata only. No live presence, timers or world switching.
class FishingWorldDirectory {
  FishingWorldDirectory(this.preferences);
  final SharedPreferences preferences;
  Map<String, dynamic> _homeDisplay = {};
  Map<String, dynamic> get homeDisplay => _homeDisplay;

  static String newCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(7, (_) => letters[rng.nextInt(letters.length)]).join();
  }

  static String normalizeCode(String code) => code.trim().toUpperCase();
  static bool validCode(String code) =>
      RegExp(r'^[A-HJ-NP-Z2-9]{7}$').hasMatch(code);

  Future<String> ensureHome(FirebaseDatabase database, String uid,
      {required int mapVersion,
      required String Function() encodeDisplay}) async {
    final ref = database.ref('worlds/$uid');
    final existing = await ref.get().timeout(const Duration(seconds: 10));
    if (existing.exists) {
      final code = existing.child('code').value;
      if (code is! String || !validCode(code)) {
        throw StateError('Invalid world code');
      }
      _homeDisplay = VisualState.decode(existing.child('display').value) ?? {};
      await ref.update({
        'mapVersion': mapVersion,
        'display': encodeDisplay()
      }).timeout(const Duration(seconds: 10));
      return code;
    }
    final cached = preferences.getString('fishing_world_code_$uid');
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = attempt == 0 && cached != null && validCode(cached)
          ? cached
          : newCode();
      final reserved =
          await database.ref('worldCodes/$code').runTransaction((value) {
        if (value == null || value == uid) return Transaction.success(uid);
        return Transaction.abort();
      }).timeout(const Duration(seconds: 10));
      if (!reserved.committed) continue;
      // Remember a reservation before creating metadata, so retries reuse it.
      await preferences.setString('fishing_world_code_$uid', code);
      await ref.update({
        'code': code,
        'mapVersion': mapVersion,
        'createdAt': ServerValue.timestamp,
        'display': encodeDisplay()
      }).timeout(const Duration(seconds: 10));
      return code;
    }
    throw StateError('Could not allocate a world code');
  }

  Future<({String id, DataSnapshot metadata})> destination(
      FirebaseDatabase database, String code,
      {required String uid, required int mapVersion}) async {
    final found = await database
        .ref('worldCodes/$code')
        .get()
        .timeout(const Duration(seconds: 10));
    if (found.value is! String) {
      throw const FormatException('Không tìm thấy phòng có mã này.');
    }
    final id = found.value as String;
    if (id == uid) {
      throw const FormatException('Đây là mã phòng của bạn.');
    }
    final world = await database
        .ref('worlds/$id')
        .get()
        .timeout(const Duration(seconds: 10));
    if (world.child('mapVersion').value != mapVersion) {
      throw const FormatException('Hai máy cần cùng phiên bản game.');
    }
    if (!world.child('hosts').exists) {
      throw const FormatException('Chủ phòng chưa vào chơi câu cá.');
    }
    return (id: id, metadata: world);
  }
}
