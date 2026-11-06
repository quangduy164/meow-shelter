import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/cats/cat_breed.dart';

/// One buyable decoration with a fixed spot in the camp yard (fractions of the
/// yard size), so buying is enough to see it placed.
class CampDecoration {
  const CampDecoration(this.id, this.name, this.price, this.x, this.y,
      {this.scale = 1});
  final String id;
  final String name;
  final int price;

  /// Centre of the item as fractions of the room size.
  final double x;
  final double y;

  /// Size relative to the base 60px decoration box (sofa and rug are large).
  final double scale;

  static const all = [
    CampDecoration('yarn', 'Cuộn len', 20, .30, .86),
    CampDecoration('flowers', 'Chậu hoa', 25, .06, .64),
    CampDecoration('frames', 'Tranh treo tường', 30, .46, .2, scale: 1.4),
    CampDecoration('bed', 'Ổ đệm êm', 40, .16, .82),
    CampDecoration('shelf', 'Kệ sách', 45, .16, .2, scale: 1.6),
    CampDecoration('post', 'Trụ cào móng', 50, .8, .62),
    CampDecoration('rug', 'Thảm tròn', 55, .46, .8, scale: 3.4),
    CampDecoration('lantern', 'Đèn lồng', 60, .34, .1),
    CampDecoration('lamp', 'Đèn cây', 70, .93, .38, scale: 2.2),
    CampDecoration('bowl', 'Bể cá nhỏ', 80, .68, .84),
    CampDecoration('sofa', 'Ghế sofa', 120, .42, .44, scale: 2.8),
    CampDecoration('house', 'Nhà gỗ mèo', 150, .58, .63),
  ];
}

/// Long-term progress shared by every mode: coins, which cats were rescued,
/// how close each cat is to the player, and which decorations are owned.
class CampState {
  CampState(this.preferences) {
    final saved = preferences.getString(_key);
    if (saved == null) return;
    try {
      _load(jsonDecode(saved) as Map<String, dynamic>);
    } catch (error) {
      // A corrupt save must never stop the app from opening: start fresh,
      // keep the broken copy for inspection and report it in debug logs.
      debugPrint('CampState: unreadable save, starting fresh ($error)');
      preferences.setString('${_key}_broken', saved);
      _reset();
    }
  }

  void _reset() {
    coins = 0;
    for (final c in [rescued, affection, placement, levelStars]) {
      c.clear();
    }
    owned.clear();
    seenGuides.clear();
  }

  void _load(Map<String, dynamic> data) {
    coins = data['coins'] as int? ?? 0;
    rescued.addAll(Map<String, int>.from(data['rescued'] as Map? ?? {}));
    affection.addAll(Map<String, int>.from(data['affection'] as Map? ?? {}));
    owned.addAll(List<String>.from(data['owned'] as List? ?? []));
    final placed = data['placement'] as Map? ?? {};
    for (final e in placed.entries) {
      final xy = List<num>.from(e.value as List);
      placement[e.key as String] = (xy[0].toDouble(), xy[1].toDouble());
    }
    seenGuides.addAll(List<String>.from(data['seenGuides'] as List? ?? []));
    levelStars.addAll(Map<String, int>.from(data['levelStars'] as Map? ?? {}));
  }

  static late CampState instance;
  static const _key = 'camp_state_v1';

  /// Affection needed for the skill-cooldown bonus in Return Home.
  static const bondedAffection = 10;

  final SharedPreferences preferences;
  int coins = 0;
  final rescued = <String, int>{};
  final affection = <String, int>{};
  final owned = <String>{};

  /// Where the player dragged each decoration, as room fractions.
  final placement = <String, (double, double)>{};

  (double, double) positionOf(CampDecoration item) =>
      placement[item.id] ?? (item.x, item.y);

  Future<void> place(String id, double x, double y) async {
    placement[id] = (x, y);
    await _save();
  }

  /// Best stars per level id (as a string key, for JSON).
  final levelStars = <String, int>{};

  Future<void> recordLevel(int id, int stars) async {
    if (stars <= (levelStars['$id'] ?? 0)) return;
    levelStars['$id'] = stars;
    await _save();
  }

  /// Cat breeds whose catch guide the player has already read.
  final seenGuides = <String>{};

  Future<void> markGuidesSeen(Iterable<String> types) async {
    seenGuides.addAll(types);
    await _save();
  }

  /// The orange cat is the starter; every other breed must be rescued first.
  bool unlocked(String type) => type == 'orange' || (rescued[type] ?? 0) > 0;
  bool bonded(String type) => (affection[type] ?? 0) >= bondedAffection;
  List<String> get residents => [
        for (final b in CatBreed.all)
          if (unlocked(b.id)) b.id
      ];

  Future<void> addCoins(int amount) async {
    coins += amount;
    await _save();
  }

  Future<void> rescue(String type) async {
    rescued[type] = (rescued[type] ?? 0) + 1;
    coins += 5;
    await _save();
  }

  Future<void> pet(String type) async {
    affection[type] = (affection[type] ?? 0) + 1;
    await _save();
  }

  /// Returns false when the player cannot afford it or already owns it.
  Future<bool> buy(CampDecoration item) async {
    if (owned.contains(item.id) || coins < item.price) return false;
    coins -= item.price;
    owned.add(item.id);
    await _save();
    return true;
  }

  /// Writes progress. Callers inside the game loop may not await this, so it
  /// never throws; a failed write is logged instead of crashing the round.
  Future<bool> _save() async {
    try {
      final ok = await preferences.setString(_key, _encode());
      if (!ok) debugPrint('CampState: save was rejected');
      return ok;
    } catch (error) {
      debugPrint('CampState: save failed ($error)');
      return false;
    }
  }

  String _encode() => jsonEncode({
        'coins': coins,
        'rescued': rescued,
        'affection': affection,
        'owned': owned.toList(),
        'placement': {
          for (final e in placement.entries) e.key: [e.value.$1, e.value.$2]
        },
        'seenGuides': seenGuides.toList(),
        'levelStars': levelStars,
      });
}
