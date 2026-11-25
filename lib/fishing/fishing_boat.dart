import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fishing_river.dart';

/// Boats the cat can row; picked at the village boathouse.
enum FishingBoat {
  basket('Thúng chai'),
  paper('Thuyền giấy'),
  swan('Thiên nga');

  const FishingBoat(this.label);
  final String label;

  static const _key = 'fishing_boat_v1';

  static FishingBoat load(SharedPreferences preferences) {
    final saved = preferences.getString(_key);
    // The watermelon boat (then the rubber duck) became the swan.
    final name = saved == 'melon' || saved == 'duck' ? 'swan' : saved;
    return values.firstWhere((b) => b.name == name, orElse: () => basket);
  }

  static Future<void> save(SharedPreferences preferences, FishingBoat boat) =>
      preferences.setString(_key, boat.name);
}

/// Village harbour boathouse on the near bank, beside the starting pier.
class FishingBoatHouse {
  static const x = 108.0;

  /// Bottom centre of the house (where its walls meet the ground).
  static Offset get base => Offset(x, FishingRiver.bottom(x) + 180);

  /// Whole house, roof included; also used to keep scenery off it.
  static Rect get bounds =>
      Rect.fromLTRB(base.dx - 106, base.dy - 178, base.dx + 96, base.dy + 18);

  static bool hit(Offset world) => bounds.inflate(10).contains(world);

  /// Where the cat stands to use the boathouse: at the foot of the slipway.
  static Offset get door => base + const Offset(-24, 30);

  /// Close enough to the boathouse to pick a boat, on foot or by boat.
  static const reach = 110.0;
  static bool near(Offset world) => (world - door).distance < reach;
}
