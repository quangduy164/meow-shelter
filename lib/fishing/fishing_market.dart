import 'dart:math' as math;
import 'package:flutter/painting.dart';

import '../camp/camp_state.dart';
import '../collection/fish_collection.dart';
import '../collection/fish_species.dart';

/// Floating fish market at the river mouth (Cửa biển): rafts of stalls on
/// the water. Basket fish sell for camp coins; one species a day is wanted
/// and sells for double.
class FishingMarket {
  static const center = Offset(6050, 1250);

  /// Solid reach for boat collision and routing.
  static const radius = 150.0;

  /// Where the boat stops to trade, just south of the stalls.
  static const mooring = Offset(6050, 1250 + 200);

  /// Tap area: the whole art, awnings and lantern strings included.
  static bool hit(Offset world) => Rect.fromCenter(
          center: center - const Offset(0, 30), width: 400, height: 290)
      .contains(world);

  static int basePrice(FishSpecies fish) => switch (fish.rarity) {
        'Phổ biến' => 6,
        'Hiếm' => 16,
        'Quý' => 30,
        'Cực hiếm' => 60,
        'Huyền thoại' => 120,
        _ => 0,
      };

  /// Species the market wants today: same for everyone on a given day.
  static FishSpecies wantedOn(DateTime day) {
    final pool = [
      for (final f in FishSpecies.values)
        if (!f.isJunk && f.rarity != 'Huyền thoại' && f.rarity != 'Cực hiếm') f
    ];
    final seed = day.year * 372 + day.month * 31 + day.day;
    return pool[math.Random(seed).nextInt(pool.length)];
  }

  static int priceOf(FishSpecies fish, DateTime day) =>
      basePrice(fish) * (fish == wantedOn(day) ? 2 : 1);

  /// Sells [count] of [fish] from the basket; returns the coins earned, or 0
  /// when nothing was sold (empty basket or a failed save).
  static Future<int> sell(FishSpecies fish, int count, {DateTime? now}) async {
    final collection = FishCollection.instance;
    final n = math.min(count, collection.stockOf(fish));
    if (n <= 0 || basePrice(fish) <= 0) return 0;
    if (!await collection.takeMany(fish, n)) return 0;
    final coins = priceOf(fish, now ?? DateTime.now()) * n;
    await CampState.instance.addCoins(coins);
    return coins;
  }
}
