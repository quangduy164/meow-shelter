import 'dart:convert';

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
  bambooRare(
      'Câu 1 cá hiếm ở Sông tre',
      'Chèo tiếp đến Sông tre. Cá trê, koi và cá vàng ở đây. Nhận mồi để thử săn Nessie.',
      1,
      coins: 15,
      bait: 1),
  nessie('Câu được Mèo Nessie',
      'Ở lại Sông tre, bật mồi huyền thoại vừa nhận để thử săn Nessie.', 1,
      bait: 1),
  activeWater(
      'Câu ở chỗ nước có cá động',
      'Đi tiếp đến Rừng ngập mặn, tìm nước sủi bọt hoặc cá quẫy. Điểm cá động ở vùng khác cũng được tính.',
      1,
      coins: 15),
  sell('Bán cá ở chợ cá nổi',
      'Đi tiếp ra Cửa biển. Bấm chợ nổi để bán cá lấy xu.', 1,
      bait: 1),
  findShrine('Tìm đền trong Hang biển',
      'Hang nằm ở bờ trên Vịnh đá. Chèo vào cửa hang.', 1,
      coins: 20),
  moonfish(
      'Câu cá nguyệt quang',
      'Chỉ cắn câu từ 18:00 đến trước 06:00 trong Hang biển. Xem giờ trên bản đồ; ban ngày có thể bán cá, khám phá đảo hoặc chơi parkour trong lúc chờ tối.',
      1,
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
        activeWater => _along(4500),
        bambooRare || nessie => _along(2700),
        findShrine || moonfish || shrine => FishingShrine.center,
        seaDragon => _along(10800),
        _ => null,
      };

  static Offset _along(double x) => Offset(x, FishingRiver.center(x));
}

class FishingQuests extends ChangeNotifier {
  FishingQuests(this.preferences) {
    final saved = preferences.getString(_key);
    if (saved != null) {
      try {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        _completed.addAll((data['done'] as List)
            .cast<String>()
            .where((name) => FishingQuest.values.any((q) => q.name == name)));
        _progress = (data['progress'] as int).clamp(0, 3);
      } catch (error) {
        debugPrint('FishingQuests: unreadable progress ($error)');
        preferences.setString('${_key}_broken', saved);
        _loadLegacy();
      }
    } else {
      _loadLegacy();
    }
    _findCurrent();
  }

  static const _key = 'fishing_quests_v2';
  // v1 saved the index in this original order, rather than quest names.
  static const _legacyOrder = [
    'villageFish',
    'sell',
    'bambooRare',
    'activeWater',
    'nessie',
    'findShrine',
    'moonfish',
    'seaDragon',
    'shrine',
  ];
  final Set<String> _completed = {};
  void _loadLegacy() {
    _completed.clear();
    final saved = preferences.getStringList('fishing_quests_v1');
    final index = (int.tryParse(saved?.elementAtOrNull(0) ?? '') ?? 0)
        .clamp(0, _legacyOrder.length);
    _completed.addAll(_legacyOrder.take(index));
    _progress = index < _legacyOrder.length &&
            _legacyOrder[index] ==
                FishingQuest.values.firstWhere((q) => !isCompleted(q)).name
        ? (int.tryParse(saved?.elementAtOrNull(1) ?? '') ?? 0).clamp(0, 3)
        : 0;
  }

  void _findCurrent() {
    _index = FishingQuest.values.indexWhere((q) => !isCompleted(q));
    if (_index < 0) _index = FishingQuest.values.length;
  }

  bool isCompleted(FishingQuest quest) => _completed.contains(quest.name);
  int get completedCount => _completed.length;
  bool _completing = false;
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

  Future<void> _save() async {
    final ok = await preferences.setString(
        _key, jsonEncode({'done': _completed.toList(), 'progress': _progress}));
    if (!ok) debugPrint('FishingQuests: could not save progress');
  }

  Future<bool> _complete() async {
    if (_completing || current == null) return false;
    _completing = true;
    final quest = current!;
    try {
      // The stable name also prevents paying a migrated quest twice.
      final paid = await CampState.instance.grantReward(
          'quest-reward:${quest.name}',
          coins: quest.coins,
          legendaryBait: quest.bait);
      if (!paid) return false;
      _completed.add(quest.name);
      _findCurrent();
      _progress = 0;
      justDone = quest;
      await _save();
      return true;
    } finally {
      _completing = false;
    }
  }

  Future<void> _advance(FishingQuest step, [int by = 1]) async {
    if (_completing || current != step) return;
    _progress += by;
    if (_progress >= step.goal) {
      if (await _complete()) await sync();
    } else {
      await _save();
    }
    notifyListeners();
  }

  /// Finishes steps the save already proves done (older players, or the
  /// shrine after an offering). Safe to call any time.
  Future<void> sync() async {
    while (!allDone && _doneByState(current!)) {
      if (!await _complete()) break;
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
