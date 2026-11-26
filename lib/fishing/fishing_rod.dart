import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fishing_river.dart';
import 'fishing_quests.dart';
import '../camp/camp_state.dart';
import '../collection/fish_collection.dart';

enum FishingRod {
  classic('Cần máy', 'Kéo cá nhanh hơn 10%'),
  bamboo('Cần tre', 'Cá cắn câu sớm hơn 25%'),
  lantern('Cần đèn lồng', 'Cá đêm ×1,5 khi trời tối', price: 200);

  const FishingRod(this.label, this.effect, {this.price = 0});
  final String label, effect;

  /// Reeling speed multiplier while the fish is coming in.
  double get reel => this == classic ? 1.1 : 1;

  /// Multiplier on the wait before a bite.
  double get biteWait => this == bamboo ? .75 : 1;

  /// Coins to buy; 0 means every player has it.
  final int price;
  String get itemId => 'rod:$name';

  /// Bought rods are kept in the camp save together with the coins.
  bool get owned => price == 0 || CampState.instance.owned.contains(itemId);

  /// The lantern rod is sold once the Sea Cave shrine has been found.
  bool get available =>
      this != lantern ||
      FishCollection.instance.shrineOfferings > 0 ||
      FishingQuests.instance.isCompleted(FishingQuest.findShrine);
  static const _key = 'fishing_rod_v1';
  static FishingRod load(SharedPreferences preferences) {
    final name = preferences.getString(_key);
    final rod = values.firstWhere((r) => r.name == name, orElse: () => classic);
    return rod.owned ? rod : classic;
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
