import 'fishing_legendary_hunts.dart';
import 'fishing_place.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../camp/camp_state.dart';
import '../collection/fish_collection.dart';
import '../collection/fish_species.dart';
import 'fishing_river.dart';
import 'fishing_shrine.dart';

/// Main fishing storyline: steps leading to the Sea Cave shrine.
/// Each step teaches one system on the way. Add a step by adding a row
/// here and a rule in [FishingQuests.onCatch] / [FishingQuests._doneByState].
enum FishingQuest {
  villageFish(
      'Câu 3 con cá ở Làng', 'Bấm nước để chèo, bấm cần câu để thả câu.', 3,
      coins: 10),
  bambooRare(
      'Câu 1 cá hiếm ở Sông tre',
      'Chèo tới Sông tre, thử câu cá trê, koi hoặc cá vàng rồi tiếp tục khám phá.',
      1,
      coins: 15,
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
  exploreWorld(
      'Khám phá đủ 7 vùng',
      'Ghé đủ các vùng trên bản đồ, gồm cả Hang biển và Biển rộng. Sau đó bắt đầu tìm 3 cá huyền thoại để hiến tế.',
      7,
      coins: 20),
  nessie(
      'Câu được Mèo Nessie',
      'Theo chậm phía sau bóng dài ở Sông tre, giữ khoảng cách. Thả câu đúng hướng lúc Nessie ngoi lên; áp sát hoặc quăng khi lặn sẽ làm nó chạy.',
      1,
      bait: 1),
  moonfish(
      'Câu cá nguyệt quang',
      'Ban đêm trong Hang biển có vệt trăng giả. Tìm bóng cá bên dưới, giữ thuyền yên và câu lúc ánh bạc sáng. Khi kéo, chỉ thu dây lúc cá sáng bạc.',
      1,
      bait: 1),
  seaDragon(
      'Câu Rồng biển',
      'Ở Biển rộng, giữ thuyền trong vành xoáy và lái né ba hướng sóng. Vượt đủ ba đợt, hướng vào tâm và thả câu ngay lúc xoáy mở.',
      1,
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
        sell => FishingVisit.market.anchor,
        activeWater => _along(4500),
        bambooRare => _along(2700),
        nessie => FishingLegendaryHunts.nessieAt(0),
        moonfish => FishingLegendaryHunts.moonAt,
        findShrine || shrine => FishingVisit.shrine.anchor,
        seaDragon => FishingLegendaryHunts.dragonAt,
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
        _completed.addAll((data['done'] as List).cast<String>().where(_known));
        final counts = data['counts'];
        if (counts is Map) {
          for (final e in counts.entries) {
            if (e.key is String && _known(e.key) && e.value is int) {
              _counts[e.key as String] = (e.value as int).clamp(0, 7);
            }
          }
        }
        _visited.addAll((data['visited'] as List? ?? [])
            .whereType<String>()
            .where((name) => FishingRegion.values.any((r) => r.name == name)));
        _reached.addAll(
            (data['reached'] as List? ?? []).whereType<String>().where(_known));
      } catch (error) {
        debugPrint('FishingQuests: unreadable progress ($error)');
        preferences.setString('${_key}_broken', saved);
        _completed.clear();
        _counts.clear();
        _visited.clear();
        _reached.clear();
        _loadPrevious();
      }
    } else {
      _loadPrevious();
    }
    _findCurrent();
  }

  static const _key = 'fishing_quests_v3';
  static const _v2Order = [
    'villageFish',
    'bambooRare',
    'nessie',
    'activeWater',
    'sell',
    'findShrine',
    'moonfish',
    'seaDragon',
    'shrine'
  ];
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
  final Map<String, int> _counts = {};
  final Set<String> _visited = {}, _reached = {};
  static bool _known(String name) =>
      FishingQuest.values.any((q) => q.name == name);

  void _loadPrevious() {
    final v2 = preferences.getString('fishing_quests_v2');
    if (v2 != null) {
      try {
        final data = jsonDecode(v2) as Map<String, dynamic>;
        _completed.addAll((data['done'] as List).cast<String>().where(_known));
        final active =
            _v2Order.where((name) => !_completed.contains(name)).firstOrNull;
        if (active != null) {
          _counts[active] = (data['progress'] as int).clamp(0, 3);
        }
      } catch (e) {
        debugPrint('FishingQuests: unreadable v2 ($e)');
        _loadLegacy();
      }
    } else {
      _loadLegacy();
    }
    // Old completed steps prove these visits without resetting existing saves.
    for (final (quest, region) in [
      (FishingQuest.villageFish, FishingRegion.village),
      (FishingQuest.bambooRare, FishingRegion.bamboo),
      (FishingQuest.nessie, FishingRegion.bamboo),
      (FishingQuest.sell, FishingRegion.coast),
      (FishingQuest.findShrine, FishingRegion.cave),
      (FishingQuest.seaDragon, FishingRegion.openSea),
    ]) {
      if (isCompleted(quest)) _visited.add(region.name);
    }
    if (isCompleted(FishingQuest.shrine)) {
      _visited.addAll(FishingRegion.values.map((r) => r.name));
      _completed.add(FishingQuest.exploreWorld.name);
    }
  }

  void _loadLegacy() {
    _completed.clear();
    _counts.clear();
    final saved = preferences.getStringList('fishing_quests_v1');
    final index = (int.tryParse(saved?.elementAtOrNull(0) ?? '') ?? 0)
        .clamp(0, _legacyOrder.length);
    _completed.addAll(_legacyOrder.take(index));
    if (index < _legacyOrder.length) {
      _counts[_legacyOrder[index]] =
          (int.tryParse(saved?.elementAtOrNull(1) ?? '') ?? 0).clamp(0, 3);
    }
  }

  static const explorationOrder = [
    FishingRegion.village,
    FishingRegion.bamboo,
    FishingRegion.mangrove,
    FishingRegion.coast,
    FishingRegion.rockyBay,
    FishingRegion.cave,
    FishingRegion.openSea
  ];
  bool hasVisited(FishingRegion region) => _visited.contains(region.name);
  bool get explorationComplete => explorationOrder.every(hasVisited);
  static Offset regionTarget(FishingRegion r) => r == FishingRegion.cave
      ? FishingVisit.shrine.anchor
      : Offset(
          (r.start + r.end) / 2, FishingRiver.bayCenter((r.start + r.end) / 2));

  /// A destination disappears after reaching it, even if a catch/sale remains.
  Offset? get navigationTarget {
    final q = current;
    if (q == FishingQuest.exploreWorld) {
      final next = explorationOrder.where((r) => !hasVisited(r)).firstOrNull;
      return next == null ? null : regionTarget(next);
    }
    return q == null || _reached.contains(q.name) ? null : q.target;
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

  int _index = 0;
  int get index => _index;
  bool get allDone => _index >= FishingQuest.values.length;
  FishingQuest? get current => allDone ? null : FishingQuest.values[_index];

  /// Progress toward [current]; the shrine step reads offerings directly.
  int get progress => current == FishingQuest.shrine
      ? FishCollection.instance.shrineOfferings
      : current == FishingQuest.exploreWorld
          ? _visited.length
          : _counts[current?.name] ?? 0;

  /// Last finished step, for a short "done" toast. Cleared by the UI.
  FishingQuest? justDone;

  Future<void> _save() async {
    final ok = await preferences.setString(
        _key,
        jsonEncode({
          'done': _completed.toList(),
          'counts': _counts,
          'visited': _visited.toList(),
          'reached': _reached.toList()
        }));
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
      _counts.remove(quest.name);
      justDone = quest;
      await _save();
      return true;
    } finally {
      _completing = false;
    }
  }

  Future<void> _advance(FishingQuest step, [int by = 1]) async {
    if (_completing || current != step) return;
    _counts[step.name] = (_counts[step.name] ?? 0) + by;
    if (_counts[step.name]! >= step.goal) {
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
      FishingQuest.findShrine =>
        _reached.contains(q.name) || c.shrineOfferings > 0,
      FishingQuest.exploreWorld => explorationComplete,
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

  /// Remember visits regardless of the active quest; never erase them on departure.
  void onBoatAt(Offset boat) {
    var changed = _visited.add(FishingRiver.regionAt(boat.dx, y: boat.dy).name);
    final q = current;
    final target = q?.target;
    if (q != null && target != null && !_reached.contains(q.name)) {
      final caveTarget = q == FishingQuest.findShrine ||
          q == FishingQuest.moonfish ||
          q == FishingQuest.shrine;
      if ((boat - target).distance < 520 &&
          (!caveTarget || FishingRiver.inCave(boat))) {
        changed = _reached.add(q.name) || changed;
      }
    }
    if (changed) {
      unawaited(_save());
      unawaited(sync());
    }
  }
}
