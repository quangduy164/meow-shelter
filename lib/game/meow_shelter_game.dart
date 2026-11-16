import 'dart:async';
import 'dart:math';
import '../audio/game_audio.dart';

import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'components/cat_component.dart';
import 'components/fish_item_component.dart';
import 'components/catch_tutorial_component.dart';
import 'components/shelter_garden_component.dart';
import '../camp/camp_state.dart';
import 'components/hud_component.dart';
import 'components/darkness_component.dart';
import 'components/shelter_zone_component.dart';
import 'constants.dart';
import '../levels/level_config.dart';
import '../levels/levels.dart';
import 'world/shelter_layout.dart';
import 'world/shelter_map.dart';
import 'night_shift/night_game.dart';
import 'systems/bait_system.dart';

class MeowShelterGame extends FlameGame {
  MeowShelterGame({required this.level, this.onNextLevel, Random? random})
      : random = random ?? Random();

  final LevelConfig level;
  final void Function()? onNextLevel;
  final Random random;
  final shelters = <ShelterZoneComponent>[];
  late HudComponent hud;
  RoundStatus get roundStatus => hud.status;
  bool _restarting = false;
  double _secondAccumulator = 0;
  final bait = BaitSystem();
  ShelterMap _map = ShelterMap.none;

  // Clock for the ordinary rescue maps (sprinklers and moving crates).
  double _mapClock = 0;

  /// Night rules live outside the shared cat-catching engine.
  late final NightGame? night = level.isInfinite ? NightGame(this) : null;
  Vector2 bedSize = Vector2.zero();

  /// Counters for the level goals of the current round.
  RoundStats stats = RoundStats();

  /// Cats still waiting to enter on wave levels: (breed, isBoss).
  final _pending = <(String, bool)>[];

  /// Seconds until the beds swap on moving-bed levels.
  double _bedTimer = 0;
  bool _bedWarned = false;
  static const bedInterval = 18.0;

  /// Why the last round was lost, shown on the result board.
  String lostReason = 'HẾT GIỜ RỒI!';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await restartRound();
  }

  /// A restart asked for while one is running (e.g. the night-shift picker
  /// starting during the first load) runs again right after it.
  bool _restartQueued = false;

  Future<void> restartRound() async {
    if (_restarting) {
      _restartQueued = true;
      return;
    }
    _restarting = true;
    try {
      do {
        _restartQueued = false;
        await _startRound();
      } while (_restartQueued);
    } finally {
      _restarting = false;
    }
  }

  Future<void> _startRound() async {
    overlays.remove('roundResult');
    night?.reset();
    removeAll(children.toList());
    shelters.clear();
    _secondAccumulator = 0;
    stats = RoundStats();
    _pending.clear();
    _bedTimer = bedInterval;
    _bedWarned = false;
    _map = level.isInfinite ? ShelterMap.none : level.map ?? ShelterMap.none;
    _mapClock = 0;
    lostReason = 'HẾT GIỜ RỒI!';
    bait.reset(limit: level.fishLimit);
    hud = HudComponent()..size = size;
    hud.totalCats = level.catTypes.length;
    hud.secondsLeft = level.timeLimit;
    hud.isTutorial = level.isTutorial;
    hud.isInfinite = level.isInfinite;
    hud.goals = level.goals;
    hud.stats = () => stats;
    hud.fishLeft = bait.limited ? bait.fishCount : null;

    if (night != null) {
      night!.mountScene();
    } else {
      add(ShelterGardenComponent(
          isPlaying: () => hud.status == RoundStatus.playing,
          map: () => _map,
          mapTime: () => _mapClock));
    }
    await _addCats();
    await _addShelters();
    if (level.isTutorial) {
      add(CatchTutorialComponent(
        cat: () => children.whereType<CatComponent>().firstOrNull,
        shelter: () => shelters.single,
        screenSize: () => size,
        isPlaying: () => hud.status == RoundStatus.playing,
      ));
    }
    if (level.darkness && night == null) {
      add(DarknessComponent(
          lights: _lights, visible: () => hud.status == RoundStatus.playing));
    }
    add(hud);
    if (level.twistLines.isNotEmpty && !level.isTutorial) {
      hud.showBanner(level.twistLines, 4);
    }
    add(FishItemComponent(
      enabled: () => canPlaceFish,
      visible: () => hud.status == RoundStatus.playing,
      placeFish: _placeFish,
      remaining: () => bait.limited ? bait.fishCount : null,
    ));
    night?.beginNight();
  }

  Future<void> _addCats() async {
    // The night controller spawns its own quota.
    if (level.isInfinite) return;
    var bossLeft = level.bossType;
    final queue = <(String, bool)>[];
    for (final type in level.catTypes) {
      final boss = type == bossLeft;
      if (boss) bossLeft = null;
      queue.add((type, boss));
    }
    // The boss walks in last on wave levels so it is the finale.
    final first = level.waveSize > 0 ? level.waveSize : queue.length;
    for (final (type, boss) in queue.take(first)) {
      spawnCat(type, boss: boss);
    }
    _pending.addAll(queue.skip(first));
  }

  void spawnCat(String type, {bool boss = false}) {
    final catLevel = night?.catLevel() ?? level;
    add(CatComponent(
      position: level.isTutorial
          ? Vector2(size.x * .43 - catWidth / 2, size.y * .43 - catHeight / 2)
          : _randomCatPosition(),
      catType: type,
      level: catLevel,
      isBoss: boss,
      isBlocked: _isMapBlocked,
      terrainSpeed: _terrainSpeed,
      lureWaypoint: night?.lureWaypoint,
      onFed: night?.cardEffects.onFed,
      lightTimeScale: night?.run?.lightTimeScale ?? .5,
      onStartled: (_) {
        stats.startles += 1;
        night?.onMistake();
      },
      onDrop: _handleDrop,
      onDelivered: _handleDelivered,
      onEscaped: _handleEscape,
      isPlaying: () => hud.status == RoundStatus.playing,
      assist: night?.assist,
      freezeInLight: night?.freezesCat,
      inLight: night?.lightsCat,
    ));
  }

  Future<void> _addShelters() async {
    final bedSize = Vector2(size.x * 0.20, size.x * 0.133);
    this.bedSize = bedSize;
    final placements = shelterLayout(level.catTypes);
    for (final shelter in placements) {
      final component = ShelterZoneComponent(
        catType: shelter.type,
        label: shelter.label,
        size: bedSize,
        position: level.isTutorial
            ? Vector2(size.x * .74, size.y * .42)
            : Vector2(size.x * shelter.x, size.y * shelter.y),
      );
      shelters.add(component);
      add(component);
    }
  }

  bool _handleDrop(CatComponent cat) {
    if (hud.status != RoundStatus.playing) return false;
    // Calico helper: any bed bounces the cat into its own.
    if (night?.acceptsAnyBed == true &&
        shelters.any((shelter) => shelter.covers(cat))) {
      return true;
    }
    final isCorrect = shelters.any((shelter) => shelter.accepts(cat));
    if (!isCorrect && shelters.any((shelter) => shelter.covers(cat))) {
      stats.wrongDrops += 1;
      night?.onMistake();
    }
    return isCorrect;
  }

  void _handleDelivered(CatComponent cat) {
    if (hud.status != RoundStatus.playing) return;
    hud.delivered += 1;
    // Practice rounds are replayable, so they do not pay out coins.
    if (!level.isTutorial) unawaited(CampState.instance.rescue(cat.catType));
    if (night != null) {
      night!.onDelivered(cat);
    } else if (hud.delivered >= hud.totalCats) {
      showResult(RoundStatus.won);
    } else if (_pending.isNotEmpty) {
      final (type, boss) = _pending.removeAt(0);
      spawnCat(type, boss: boss);
      if (boss) {
        GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
        hud.showBanner(['Trùm xuất hiện!', level.twistLines.first]);
      }
    }
  }

  void _handleEscape(CatComponent cat) {
    if (hud.status != RoundStatus.playing) return;
    if (level.isInfinite) {
      lostReason = 'MÈO ĐÃ CHẠY MẤT!';
      showResult(RoundStatus.lost);
      return;
    }
    // Mèo chạy ra ngoài được thay bằng một mèo cùng loại để màn vẫn có thể thắng.
    spawnCat(cat.catType, boss: cat.isBoss);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || paused || hud.status != RoundStatus.playing) return;
    bait.update(children.whereType<CatComponent>(), dt: dt);
    if (bait.limited) hud.fishLeft = bait.fishCount;
    _mapClock += dt;
    if (night != null) {
      night!.update(dt);
      return;
    }
    // Let the last rescued cat finish its success animations before ending.
    if (hud.delivered >= hud.totalCats) return;
    if (level.isTutorial || level.isInfinite) return;
    if (level.movingBeds) updateMovingBeds(dt);
    if (outOfFish) {
      lostReason = 'HẾT CÁ RỒI!';
      showResult(RoundStatus.lost);
      return;
    }
    _secondAccumulator += dt;
    if (_secondAccumulator >= 1) {
      _secondAccumulator -= 1;
      hud.secondsLeft -= 1;
      if (hud.secondsLeft == 10) {
        GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
      }
      if (hud.secondsLeft <= 0) showResult(RoundStatus.lost);
    }
  }

  int lastStars = 0;

  /// Cats rescued this round, for the result board.
  int get rescued => hud.delivered;

  void showResult(RoundStatus status) {
    if (hud.status != RoundStatus.playing) return;
    GameAudio.instance.playRescue(
        status == RoundStatus.won ? GameSound.rescueWin : GameSound.rescueLose,
        important: true);
    hud.status = status;
    night?.recordResult();
    if (status == RoundStatus.won && !level.isInfinite) {
      stats.secondsLeft = hud.secondsLeft;
      lastStars = starsFor(level, stats);
      unawaited(CampState.instance.recordLevel(level.id, lastStars));
    }
    overlays.add('roundResult');
  }

  bool get canPlaceFish =>
      isLoaded &&
      hud.status == RoundStatus.playing &&
      bait.canPlace &&
      (!level.isTutorial ||
          (bait.positions.isEmpty &&
              !children.whereType<CatComponent>().any((cat) => cat.hasEaten)));

  void _placeFish(Vector2 point) {
    if (!canPlaceFish) return;
    if (night?.allowsBait(point) == false) {
      hud.showBanner(['Chỉ đặt cá trong vùng đánh dấu trên mái giữa'], 1.5);
      return;
    }
    final reach = Vector2(catWidth, catHeight);
    if (_isMapBlocked(point - reach / 2, reach)) {
      hud.showBanner(['Mèo không tới được chỗ này'], 1.5);
      return;
    }
    if (bait.place(point, size, children.whereType<CatComponent>())) {
      GameAudio.instance.playRescue(GameSound.baitDrop);
      stats.fishUsed += 1;
      if (bait.limited) hud.fishLeft = bait.fishCount;
    }
  }

  /// No fish left, none on the ground, and someone still needs a meal.
  bool get outOfFish {
    if (night?.scene.hasBaitInTransit == true) return false;
    if (!bait.limited || bait.fishCount > 0 || bait.hasBaitOut) {
      return false;
    }
    final cats = children.whereType<CatComponent>().toList();
    if (cats.any((cat) => cat.isLit || cat.isDelivered)) return false;
    return cats.any((cat) => cat.catType != 'calico') ||
        _pending.any((entry) => entry.$1 != 'calico');
  }

  void resetBedTimer() {
    _bedTimer = bedInterval;
    _bedWarned = false;
  }

  void updateMovingBeds(double dt) {
    _bedTimer -= dt;
    if (!_bedWarned && _bedTimer <= 3) {
      GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
      _bedWarned = true;
      hud.showBanner(['Ổ sắp dời chỗ!'], 2.5);
    }
    // Never pull a bed away while the player is carrying a cat.
    if (_bedTimer > 0 ||
        children.whereType<CatComponent>().any((cat) => cat.isCarried)) {
      return;
    }
    _bedTimer = bedInterval;
    _bedWarned = false;
    final spots = [for (final shelter in shelters) shelter.position.clone()];
    if (spots.length < 2) return;
    for (var i = 0; i < shelters.length; i++) {
      shelters[i].add(MoveToEffect(spots[(i + 1) % spots.length],
          EffectController(duration: .7, curve: Curves.easeInOutCubic)));
    }
  }

  /// Light pools for dark levels.
  Iterable<(Offset, double)> _lights() sync* {
    for (final fish in bait.positions) {
      yield (Offset(fish.x, fish.y), 120);
    }
    for (final shelter in shelters) {
      yield (shelter.center.toOffset(), 80);
    }
    for (final cat in children.whereType<CatComponent>()) {
      // Every cat glows faintly so calico can still be found.
      yield (cat.center.toOffset(), cat.isLit ? 85 : 40);
    }
  }

  void shuffleShelters() {
    final slots = shelterLayout(level.catTypes)
        .map((shelter) => Vector2(size.x * shelter.x, size.y * shelter.y))
        .toList()
      ..shuffle(random);
    for (var i = 0; i < shelters.length && i < slots.length; i++) {
      shelters[i].position = slots[i];
    }
  }

  bool _isMapBlocked(Vector2 position, Vector2 size) {
    final bounds = Rect.fromLTWH(position.x / this.size.x,
        position.y / this.size.y, size.x / this.size.x, size.y / this.size.y);
    final night = this.night;
    if (night != null) return night.blocks(bounds);
    return _map.blockersAt(_mapClock).any(bounds.overlaps);
  }

  double _terrainSpeed(Vector2 center) {
    final point = Offset(center.x / size.x, center.y / size.y);
    return _map.mud.any((mud) => mud.contains(point)) ? ShelterMap.mudSpeed : 1;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isLoaded || paused || hud.status != RoundStatus.playing) return;
    for (final fish in bait.positions) {
      drawFish(canvas, Offset(fish.x, fish.y));
    }
  }

  Vector2 _randomCatPosition() {
    final nightSpot = night?.spawnPosition(Vector2(catWidth, catHeight));
    if (nightSpot != null) return nightSpot;
    for (var i = 0;; i++) {
      final x =
          size.x * .22 + random.nextDouble() * max(0, size.x * .56 - catWidth);
      final y = size.y * 0.28 + random.nextDouble() * (size.y * 0.32);
      final spot = Vector2(x, y);
      if (i >= 20 || !_isMapBlocked(spot, Vector2(catWidth, catHeight))) {
        return spot;
      }
    }
  }
}
