import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../camp/camp_state.dart';
import '../collection/fish_collection.dart';
import '../collection/fish_species.dart';
import 'fishing_market.dart';
import 'fishing_river.dart';
import 'fishing_shrine.dart';

/// Main fishing storyline: nine steps leading to the Sea Cave shrine.
/// Each step teaches one system on the way. Add a step by adding a row
/// here and a rule in [FishingQuests.onCatch] / [FishingQuests._doneByState].
enum FishingQuest {
  villageFish(
      'Câu 3 con cá ở Làng', 'Bấm nước để chèo, bấm cần câu để thả câu.', 3,
      coins: 10),
  sell(
      'Bán cá ở chợ cá nổi', 'Chợ nổi ở Cửa biển. Bấm chợ để đổi cá lấy xu.', 1,
      bait: 1),
  bambooRare('Câu 1 cá hiếm ở Sông tre',
      'Chèo ngược lên Sông tre. Cá trê, koi và cá vàng ở đây.', 1,
      coins: 15),
  activeWater('Câu ở chỗ nước có cá động',
      'Tìm chỗ nước sủi bọt hoặc cá quẫy. Cá hiếm cắn nhiều hơn.', 1,
      coins: 15),
  nessie('Câu được Mèo Nessie',
      'Huyền thoại ở Sông tre. Bật mồi huyền thoại để dễ gặp hơn.', 1,
      bait: 1),
  findShrine('Tìm đền trong Hang biển',
      'Hang nằm ở bờ trên Vịnh đá. Chèo vào cửa hang.', 1,
      coins: 20),
  moonfish('Câu cá nguyệt quang',
      'Chỉ cắn câu ban đêm trong hang. Ngủ trên thuyền lớn để qua ngày.', 1,
      bait: 1),
  seaDragon('Câu Rồng biển', 'Huyền thoại ngoài Biển rộng, vùng xa nhất.', 1,
      bait: 1),
  shrine('Hiến đủ 3 loài huyền thoại',
      'Mang 3 cá huyền thoại tới đền trong Hang biển.', 3,
      coins: 99999);

  const FishingQuest(this.title, this.hint, this.goal,
      {this.coins = 0, this.bait = 0});
  final String title, hint;
  final int goal, coins, bait;

  String get reward => [
        if (coins > 0) '$coins xu',
        if (bait > 0) '$bait mồi huyền thoại',
      ].join(' · ');

  /// World point the step asks the player to reach, if any.
  Offset? get target => switch (this) {
        sell => FishingMarket.center,
        bambooRare || nessie => _along(2700),
        findShrine || moonfish || shrine => FishingShrine.center,
        seaDragon => _along(10800),
        _ => null,
      };

  static Offset _along(double x) => Offset(x, FishingRiver.center(x));
}

class FishingQuests extends ChangeNotifier {
  FishingQuests(this.preferences) {
    final saved = preferences.getStringList(_key);
    _index = int.tryParse(saved?.elementAtOrNull(0) ?? '') ?? 0;
    _progress = int.tryParse(saved?.elementAtOrNull(1) ?? '') ?? 0;
    _index = _index.clamp(0, FishingQuest.values.length);
  }

  static const _key = 'fishing_quests_v1';
  final SharedPreferences preferences;

  static FishingQuests? _instance;

  /// Follows [FishCollection.instance], so a new save gets fresh quests.
  static FishingQuests get instance {
    final prefs = FishCollection.instance.preferences;
    if (_instance?.preferences != prefs) _instance = FishingQuests(prefs);
    return _instance!;
  }

  int _index = 0, _progress = 0;
  int get index => _index;
  bool get allDone => _index >= FishingQuest.values.length;
  FishingQuest? get current => allDone ? null : FishingQuest.values[_index];

  /// Progress toward [current]; the shrine step reads offerings directly.
  int get progress => current == FishingQuest.shrine
      ? FishCollection.instance.shrineOfferings
      : _progress;

  /// Last finished step, for a short "done" toast. Cleared by the UI.
  FishingQuest? justDone;

  Future<void> _save() =>
      preferences.setStringList(_key, ['$_index', '$_progress']);

  Future<void> _complete() async {
    final quest = current!;
    // Pay first, keyed per quest: if the app dies before the step is saved,
    // the step completes again on the next visit but is not paid twice.
    final paid = await CampState.instance.grantReward(
        'quest-reward:${quest.name}',
        coins: quest.coins,
        legendaryBait: quest.bait);
    if (!paid) return;
    _index++;
    _progress = 0;
    justDone = quest;
    await _save();
    await sync();
  }

  Future<void> _advance(FishingQuest step, [int by = 1]) async {
    if (current != step) return;
    _progress += by;
    if (_progress >= step.goal) {
      await _complete();
    } else {
      await _save();
    }
    notifyListeners();
  }

  /// Finishes steps the save already proves done (older players, or the
  /// shrine after an offering). Safe to call any time.
  Future<void> sync() async {
    while (!allDone && _doneByState(current!)) {
      await _complete();
    }
    notifyListeners();
  }

  bool _doneByState(FishingQuest q) {
    final c = FishCollection.instance;
    bool caught(FishSpecies f) => c.countOf(f) > 0 || c.hasShrineOffering(f);
    return switch (q) {
      FishingQuest.villageFish => c.countOf(FishSpecies.perch) +
              c.countOf(FishSpecies.tilapia) +
              c.countOf(FishSpecies.carp) >=
          3,
      FishingQuest.bambooRare =>
        caught(FishSpecies.koi) || caught(FishSpecies.goldfish),
      FishingQuest.nessie => caught(FishSpecies.catMew),
      FishingQuest.findShrine => c.shrineOfferings > 0,
      FishingQuest.moonfish => caught(FishSpecies.moonfish),
      FishingQuest.seaDragon => caught(FishSpecies.seaDragon),
      FishingQuest.shrine => c.shrineOfferings >= FishingShrine.requiredFish,
      _ => false,
    };
  }

  /// A fish (never junk) was saved to the basket.
  Future<void> onCatch(FishSpecies fish, Offset at,
      {required bool activeWater}) async {
    if (fish.isJunk || allDone) return;
    final region = FishingRiver.regionAt(at.dx, y: at.dy);
    switch (current!) {
      case FishingQuest.villageFish when region == FishingRegion.village:
        await _advance(FishingQuest.villageFish);
      case FishingQuest.bambooRare
          when region == FishingRegion.bamboo && fish.rarity != 'Phổ biến':
        await _advance(FishingQuest.bambooRare);
      case FishingQuest.activeWater when activeWater:
        await _advance(FishingQuest.activeWater);
      case FishingQuest.nessie when fish == FishSpecies.catMew:
      case FishingQuest.moonfish when fish == FishSpecies.moonfish:
      case FishingQuest.seaDragon when fish == FishSpecies.seaDragon:
        await _advance(current!);
      default:
        break;
    }
    await sync();
  }

  Future<void> onSold(int count) async {
    if (count > 0) await _advance(FishingQuest.sell);
  }

  /// Called with the boat position; cheap unless the step is "find".
  void onBoatAt(Offset boat) {
    if (current == FishingQuest.findShrine &&
        (boat - FishingShrine.center).distance < 520) {
      _advance(FishingQuest.findShrine);
    }
  }
}
