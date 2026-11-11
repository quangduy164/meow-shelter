import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/cats/cat_breed.dart';

/// One buyable decoration with a fixed spot in the camp yard (fractions of the
/// yard size), so buying is enough to see it placed.
/// Shop sections.
enum CampCategory {
  toys('Đồ chơi'),
  beds('Chỗ ngủ'),
  furniture('Nội thất'),
  wall('Treo tường'),
  plants('Cây & đèn');

  const CampCategory(this.label);
  final String label;
}

class CampDecoration {
  const CampDecoration(this.id, this.name, this.price, this.x, this.y,
      {this.scale = 1, required this.cat});
  final CampCategory cat;
  final String id;
  final String name;
  final int price;

  /// Centre of the item as fractions of the room size.
  final double x;
  final double y;

  /// Size relative to the base 60px decoration box (sofa and rug are large).
  final double scale;

  static const all = [
    CampDecoration('yarn', 'Cuộn len', 20, .30, .86, cat: CampCategory.toys),
    CampDecoration('flowers', 'Chậu hoa', 25, .06, .64,
        cat: CampCategory.plants),
    CampDecoration('frames', 'Tranh treo tường', 30, .46, .2,
        scale: 1.4, cat: CampCategory.wall),
    CampDecoration('bed', 'Ổ đệm êm', 40, .16, .82, cat: CampCategory.beds),
    CampDecoration('shelf', 'Kệ sách', 45, .16, .2,
        scale: 1.6, cat: CampCategory.wall),
    CampDecoration('post', 'Trụ cào móng', 50, .8, .62, cat: CampCategory.toys),
    CampDecoration('rug', 'Thảm tròn', 55, .46, .8,
        scale: 3.4, cat: CampCategory.furniture),
    CampDecoration('lantern', 'Đèn lồng', 60, .34, .1, cat: CampCategory.wall),
    CampDecoration('lamp', 'Đèn cây', 70, .93, .38,
        scale: 2.2, cat: CampCategory.plants),
    CampDecoration('bowl', 'Bể cá nhỏ', 80, .68, .84, cat: CampCategory.toys),
    CampDecoration('sofa', 'Ghế sofa', 120, .42, .44,
        scale: 2.8, cat: CampCategory.furniture),
    CampDecoration('house', 'Nhà gỗ mèo', 150, .58, .63,
        cat: CampCategory.beds),
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
    // Saves from before the cat shop: breeds already rescued stay owned.
    if (data['catShop'] == null) {
      for (final e in rescued.entries) {
        if (e.value > 0) owned.add(catItemId(e.key));
      }
    }
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

  /// Bumped whenever [levelStars] changes, so open screens (level select)
  /// refresh even when the win happened several rounds later.
  final progress = ValueNotifier<int>(0);

  Future<void> recordLevel(int id, int stars) async {
    if (stars <= (levelStars['$id'] ?? 0)) return;
    levelStars['$id'] = stars;
    progress.value += 1;
    await _save();
  }

  static const _herdTutorialKey = 'mode:herd:tutorial:v1';
  bool get herdTutorialDone => seenGuides.contains(_herdTutorialKey);
  Future<void> completeHerdTutorial() => markGuidesSeen([_herdTutorialKey]);

  /// Cat breeds and mode guides already completed/read.
  final seenGuides = <String>{};

  Future<void> markGuidesSeen(Iterable<String> types) async {
    seenGuides.addAll(types);
    await _save();
  }

  /// Price of each breed in the camp shop; the orange cat is free.
  static const catPrices = {
    'orange': 0,
    'himalaya': 80,
    'scottish': 100,
    'calico': 120,
    'black': 150,
  };

  static String catItemId(String type) => 'cat:$type';

  /// The orange cat lives in the camp from the start; others are bought.
  bool unlocked(String type) =>
      type == 'orange' || owned.contains(catItemId(type));

  /// Returns false when the player cannot afford the cat or already has it.
  Future<bool> buyCat(String type) async {
    final price = catPrices[type] ?? 0;
    if (unlocked(type) || coins < price) return false;
    coins -= price;
    owned.add(catItemId(type));
    await _save();
    return true;
  }

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
        'catShop': 1,
      });
}
