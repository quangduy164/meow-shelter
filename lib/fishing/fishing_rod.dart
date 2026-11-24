import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fishing_river.dart';

enum FishingRod {
  classic('Cần máy'),
  bamboo('Cần tre');

  const FishingRod(this.label);
  final String label;
  static const _key = 'fishing_rod_v1';
  static FishingRod load(SharedPreferences preferences) {
    final name = preferences.getString(_key);
    return values.firstWhere((r) => r.name == name, orElse: () => classic);
  }

  Future<bool> save(SharedPreferences preferences) =>
      preferences.setString(_key, name);
}

class FishingRodHouse {
  static const x = 400.0;
  static Offset get base => Offset(x, FishingRiver.bottom(x) + 180);
  static Rect get bounds =>
      Rect.fromLTRB(base.dx - 104, base.dy - 155, base.dx + 104, base.dy + 28);
  static Offset get door => base + const Offset(0, 30);
  static Offset get mooring => Offset(x, FishingRiver.bottom(x) - 60);
  static bool hit(Offset p) => bounds.inflate(8).contains(p);
}
