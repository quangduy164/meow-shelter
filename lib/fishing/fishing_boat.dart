import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boats the cat can row; picked at the village boathouse.
enum FishingBoat {
  basket('Thúng chai', 'Cá kéo trôi ít hơn 30%'),
  paper('Thuyền giấy', 'Chèo nhanh hơn 25%'),
  swan('Thiên nga', 'Thấy cá động xa hơn 50%');

  const FishingBoat(this.label, this.effect);
  final String label, effect;

  /// How hard a hooked fish can drag this boat around.
  double get dragByFish => this == basket ? .7 : 1;

  /// Top rowing / pedalling speed multiplier.
  double get speed => this == paper ? 1.25 : 1;

  /// Reach for spotting active water when casting.
  double get activeReach => this == swan ? 1.5 : 1;

  /// The swan pedal boat seats two; the first aboard drives.
  int get seats => this == swan ? 2 : 1;

  /// Seat positions relative to the boat point, boat facing right. Seat 0
  /// (the driver) is the boat point itself, so the local cat, oar and rod
  /// keep their anchors; the passenger sits behind.
  static const _swanSeats = [Offset.zero, Offset(-46, 0)];
  Offset seatOffset(int seat, {bool facingRight = true}) {
    final o = this == swan && seat < _swanSeats.length
        ? _swanSeats[seat]
        : Offset.zero;
    return facingRight ? o : Offset(-o.dx, o.dy);
  }

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
