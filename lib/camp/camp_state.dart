import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One buyable decoration with a fixed spot in the camp yard (fractions of the
/// yard size), so buying is enough to see it placed.
class CampDecoration {
  const CampDecoration(this.id, this.name, this.price, this.x, this.y);
  final String id;
  final String name;
  final int price;
  final double x;
  final double y;

  static const all = [
    CampDecoration('yarn', 'Cuộn len', 20, .30, .78),
    CampDecoration('flowers', 'Chậu hoa', 25, .08, .62),
    CampDecoration('bed', 'Ổ đệm êm', 40, .18, .80),
    CampDecoration('post', 'Trụ cào móng', 50, .86, .58),
    CampDecoration('lantern', 'Đèn lồng', 60, .62, .36),
    CampDecoration('bowl', 'Bể cá nhỏ', 80, .74, .80),
    CampDecoration('house', 'Nhà gỗ mèo', 150, .46, .40),
  ];
}

/// Long-term progress shared by every mode: coins, which cats were rescued,
/// how close each cat is to the player, and which decorations are owned.
class CampState {
  CampState(this.preferences) {
    final saved = preferences.getString(_key);
    if (saved == null) return;
    final data = jsonDecode(saved) as Map<String, dynamic>;
    coins = data['coins'] as int? ?? 0;
    rescued.addAll(Map<String, int>.from(data['rescued'] as Map? ?? {}));
    affection.addAll(Map<String, int>.from(data['affection'] as Map? ?? {}));
    owned.addAll(List<String>.from(data['owned'] as List? ?? []));
  }

  static late CampState instance;
  static const _key = 'camp_state_v1';
  static const catTypes = ['orange', 'black', 'himalaya', 'scottish', 'calico'];
  static const catNames = {
    'orange': 'Mèo cam',
    'black': 'Mèo đen',
    'himalaya': 'Himalaya',
    'scottish': 'Scottish',
    'calico': 'Tam thể',
  };

  /// Affection needed for the skill-cooldown bonus in Return Home.
  static const bondedAffection = 10;

  final SharedPreferences preferences;
  int coins = 0;
  final rescued = <String, int>{};
  final affection = <String, int>{};
  final owned = <String>{};

  /// The orange cat is the starter; every other breed must be rescued first.
  bool unlocked(String type) => type == 'orange' || (rescued[type] ?? 0) > 0;
  bool bonded(String type) => (affection[type] ?? 0) >= bondedAffection;
  List<String> get residents => catTypes.where(unlocked).toList();

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

  Future<void> _save() => preferences.setString(
      _key,
      jsonEncode({
        'coins': coins,
        'rescued': rescued,
        'affection': affection,
        'owned': owned.toList(),
      }));
}
