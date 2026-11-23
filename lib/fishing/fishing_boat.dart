import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fishing_river.dart';

/// Boats the cat can row; picked at the village boathouse.
enum FishingBoat {
  basket('Thúng chai'),
  paper('Thuyền giấy');

  const FishingBoat(this.label);
  final String label;

  static const _key = 'fishing_boat_v1';

  static FishingBoat load(SharedPreferences preferences) {
    final name = preferences.getString(_key);
    return values.firstWhere((b) => b.name == name, orElse: () => basket);
  }

  static Future<void> save(SharedPreferences preferences, FishingBoat boat) =>
      preferences.setString(_key, boat.name);
}

/// Village boathouse on the near bank, beside the starting dock.
class FishingBoatHouse {
  static const x = 100.0;

  /// Bottom centre of the house (where its walls meet the ground).
  static Offset get base => Offset(x, FishingRiver.bottom(x) + 100);

  /// Whole house, roof included; also used to keep scenery off it.
  static Rect get bounds =>
      Rect.fromLTRB(base.dx - 78, base.dy - 118, base.dx + 78, base.dy + 12);

  static bool hit(Offset world) => bounds.inflate(10).contains(world);
}
