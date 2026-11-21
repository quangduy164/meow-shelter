import 'dart:math' as math;
import '../collection/fish_collection.dart';
import '../collection/fish_species.dart';

/// Treasure chest in the cabin bedroom: refills with three sea fish once per
/// calendar day; opening puts them straight into the basket.
class FishingCabinChest {
  static const key = 'fishing_cabin_chest_day_v1';
  static const count = 3;
  static const pool = {
    FishSpecies.sardine: 3,
    FishSpecies.mackerel: 2,
    FishSpecies.grouper: 2,
    FishSpecies.clownfish: 1,
    FishSpecies.butterflyfish: 1,
  };

  static String _day(DateTime now) => '${now.year}-${now.month}-${now.day}';

  static bool full(FishCollection collection, [DateTime? now]) =>
      collection.preferences.getString(key) != _day(now ?? DateTime.now());

  /// The fish received, or null when the chest is empty today / save failed.
  static Future<List<FishSpecies>?> open(FishCollection collection,
      {math.Random? random, DateTime? now}) async {
    now ??= DateTime.now();
    if (!full(collection, now)) return null;
    final rng = random ?? math.Random();
    final total = pool.values.fold(0, (a, b) => a + b);
    final fish = <FishSpecies>[];
    for (var i = 0; i < count; i++) {
      var roll = rng.nextInt(total);
      for (final e in pool.entries) {
        roll -= e.value;
        if (roll < 0) {
          fish.add(e.key);
          break;
        }
      }
    }
    if (!await collection.addToBasket(fish)) return null;
    await collection.preferences.setString(key, _day(now));
    return fish;
  }
}
