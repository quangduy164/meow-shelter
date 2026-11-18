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
import 'cats/dish.dart';
import 'systems/bush_system.dart';
import 'systems/moon_system.dart';
import 'systems/rack_system.dart';
import 'systems/storm_system.dart';
import 'cats/cat_breed.dart';
import 'cats/cat_catch_rule.dart';

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

  /// Chapter 2 garden: shy cats hide in bushes until it is quiet.
  BushSystem? bushes;

  /// Chapter 5 attic: drifting moonlight and the phantom boss.
  MoonSystem? moon;

  /// Chapter 1 yard: the drying rack that drops free fish.
  RackSystem? rack;

  /// Chapter 6 storm: rising water, flooded beds and the rescue truck.
  StormSystem? storm;

  // Seconds on the current map (drives the straw-mat glow).
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
    bushes = _map.bushes.isEmpty || night != null
        ? null
        : BushSystem(_map, onRetreat: () => stats.retreats += 1);
    moon = _map.moonbeams.isEmpty || night != null ? null : MoonSystem(_map);
    rack = _map.rack == null || night != null ? null : RackSystem(_map, random);
    storm = level.flood <= 0 || night != null
        ? null
        : (StormSystem(floodTop: level.flood, riseSeconds: level.timeLimit * .6)
          ..field = size.clone());
    lostReason = 'HẾT GIỜ RỒI!';
    bait.reset(limit: level.fishLimit);
    bait.field = size.clone();
    bait.blocked = (p) => _isMapBlocked(p - Vector2.all(12), Vector2.all(24));
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
          isPlaying: () => hud.status == RoundStatus.playing, map: () => _map));
    }
    await _addCats();
    await _addShelters();
    final weather = storm;
    if (weather != null) {
      add(StormLayer(weather.renderBack, priority: -50));
      add(StormLayer((c) => weather.renderFront(c, shelters), priority: 79));
    }
    if (level.isTutorial) {
      add(CatchTutorialComponent(
        cat: () => children.whereType<CatComponent>().firstOrNull,
        shelter: () => shelters.single,
        screenSize: () => size,
        isPlaying: () => hud.status == RoundStatus.playing,
      ));
    }
    if ((level.darkness || moon != null) && night == null) {
      add(DarknessComponent(
          lights: _lights,
          visible: () => hud.status == RoundStatus.playing,
          shade:
              moon == null ? const Color(0xF0101828) : const Color(0xE8101828),
          additionalLights: moon?.cutLight));
    }
    add(hud);
    if (level.twistLines.isNotEmpty && !level.isTutorial) {
      hud.showBanner(level.twistLines, 4);
    }
    // The kitchen tray offers three dishes; elsewhere it is one fish.
    final tray = night != null
        ? [Dish.fish]
        : level.dishes
            ? Dish.foods
            : level.toys
                ? [Dish.fish, Dish.yarn]
                : [Dish.fish];
    for (var i = 0; i < tray.length; i++) {
      final toy = tray[i] == Dish.yarn;
      add(FishItemComponent(
        enabled: () => toy ? canPlaceToy : canPlaceFish,
        visible: () => hud.status == RoundStatus.playing,
        placeFish: (point) => _placeFish(point, tray[i]),
        remaining: !toy && (i == tray.length - 1 || tray.last == Dish.yarn)
            ? () => bait.limited ? bait.fishCount : null
            : null,
        dish: tray[i],
        slot: i,
        slots: tray.length,
      ));
    }
    night?.beginNight();
  }

  Future<void> _addCats() async {
    // The night controller spawns its own quota.
    if (level.isInfinite) return;
    var bossLeft = level.bossType;
    final queue = <(String, bool)>[];
    for (final type in level.catTypes) {
      final boss = level.bossParade || type == bossLeft;
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
      trapCapture: night?.scene.noCarry ?? false,
      onCaptureTap: night == null ? null : (cat) => night!.scene.tapCat(cat),
      // Night maps draw darkness, moon and lamp controls up to 86.
      priority: night == null ? 0 : 87,
      isBlocked: _isMapBlocked,
      terrainSpeed: _terrainSpeed,
      lureWaypoint: night?.lureWaypoint,
      onFed: night?.cardEffects.onFed,
      lightTimeScale: night?.run?.lightTimeScale ?? .5,
      onStartled: (cat) {
        stats.startles += 1;
        night?.onMistake();
        bushes?.noise(cat.center, BushSystem.startleNoise);
      },
      moonlit: moon?.lit,
      napMat: _map.napMats.isEmpty ? null : _onNapMat,
      onKickToy: (cat) {
        stats.distractions += 1;
        bait.kickYarn(cat.center, _randomRoll(170));
      },
      onTantrum: (cat) {
        stats.offBeats += 1;
        // The boss knocks two balls of yarn across the room.
        for (var i = 0; i < 2; i++) {
          bait.kickYarn(cat.center, _randomRoll(260));
        }
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
        visible: () => night?.scene.noCarry != true,
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
    final storm = this.storm;
    // The parked rescue truck takes any cat.
    if (storm != null && storm.onTruck(cat)) return true;
    final isCorrect = shelters.any((shelter) =>
        shelter.accepts(cat) && (storm == null || !storm.flooded(shelter)));
    if (!isCorrect &&
        storm != null &&
        shelters.any((s) => s.accepts(cat) && storm.flooded(s))) {
      hud.showBanner(['Ổ ngập rồi! Đưa bé lên xe cứu hộ'], 2);
    }
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
        hud.showBanner(level.bossParade
            ? [
                'Trùm ${CatBreed.of(type).name} xuất hiện!',
                CatCatchRule.bossHint(type)
              ]
            : ['Trùm xuất hiện!', level.twistLines.first]);
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
    bushes?.update(dt, size, children.whereType<CatComponent>());
    moon?.update(dt, size, children.whereType<CatComponent>());
    rack?.update(dt, size, bait, children.whereType<CatComponent>());
    storm
      ?..time += dt
      ..field.setFrom(size);
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

  bool _onNapMat(Vector2 point) => _map.napMats.any((m) => Rect.fromLTWH(
          m.left * size.x, m.top * size.y, m.width * size.x, m.height * size.y)
      .contains(point.toOffset()));

  /// Straw mats glow with "Zz" once the orange boss needs only one more fish.
  void _drawNapMats(Canvas canvas) {
    if (_map.napMats.isEmpty) return;
    final sleepy = children.whereType<CatComponent>().any((cat) =>
        cat.isBoss &&
        !cat.hasEaten &&
        cat.meals >= cat.mealsNeeded - 1 &&
        cat.mealsNeeded > 0);
    if (!sleepy) return;
    final pulse = .5 + .5 * sin(_mapClock * 4);
    for (final m in _map.napMats) {
      final r = Rect.fromLTWH(
          m.left * size.x, m.top * size.y, m.width * size.x, m.height * size.y);
      canvas.drawOval(
          r.inflate(4),
          Paint()
            ..color = Color.fromRGBO(255, 214, 90, .5 + .4 * pulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      final zz = TextPainter(
          text: const TextSpan(
              text: 'Zz',
              style: TextStyle(
                  color: Color(0xFF5A3214),
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr)
        ..layout();
      zz.paint(canvas, r.topCenter + Offset(-zz.width / 2, -18 - pulse * 4));
    }
  }

  /// Yarn is free; it only needs an empty spot to land on.
  bool get canPlaceToy => isLoaded && hud.status == RoundStatus.playing;

  Vector2 _randomRoll(double speed) {
    final angle = random.nextDouble() * pi * 2;
    return Vector2(cos(angle), sin(angle)) * speed;
  }

  void _placeFish(Vector2 point, [Dish dish = Dish.fish]) {
    if (storm?.inWater(point) == true) {
      hud.showBanner(['Cá trôi mất! Thả trên chỗ khô nhé'], 1.5);
      return;
    }
    if (dish == Dish.yarn) {
      final reach = Vector2(catWidth, catHeight);
      if (!canPlaceToy || _isMapBlocked(point - reach / 2, reach)) return;
      // Dropped yarn rolls a little in a random direction before it stops.
      if (bait.place(point, size, children.whereType<CatComponent>(),
          free: true, dish: Dish.yarn, roll: _randomRoll(110))) {
        GameAudio.instance.playRescue(GameSound.baitDrop);
      }
      return;
    }
    if (!canPlaceFish) return;
    if (night?.scene.ownsBait == true) {
      if (night!.scene.placeBait(point.toOffset())) {
        stats.fishUsed++;
        if (bait.limited) hud.fishLeft = bait.fishCount;
      }
      return;
    }
    if (night?.allowsBait(point) == false) {
      hud.showBanner(['Chỉ đặt cá trong vùng đánh dấu trên mái giữa'], 1.5);
      return;
    }
    final reach = Vector2(catWidth, catHeight);
    if (_isMapBlocked(point - reach / 2, reach)) {
      hud.showBanner(['Mèo không tới được chỗ này'], 1.5);
      return;
    }
    final cats = children.whereType<CatComponent>().toList();
    if (bait.place(point, size, cats, dish: dish)) {
      GameAudio.instance.playRescue(GameSound.baitDrop);
      stats.fishUsed += 1;
      if (bait.limited) hud.fishLeft = bait.fishCount;
      if (level.dishes) _judgeDish(point, dish, cats);
      bushes?.noise(point);
    }
  }

  /// A dish served to a hungry Scottish (the closest hungry cat) that
  /// wanted something else counts as a wrong dish, and the cat says so.
  void _judgeDish(Vector2 point, Dish dish, List<CatComponent> cats) {
    CatComponent? nearest;
    for (final cat in cats) {
      if (cat.isDelivered || cat.hasEaten || cat.isCarried) continue;
      if ((cat.center - point).length > wrongDishReach) continue;
      if (nearest == null ||
          (cat.center - point).length2 < (nearest.center - point).length2) {
        nearest = cat;
      }
    }
    // Only the closest hungry cat counts as the one being served.
    final wants = nearest?.craving;
    if (nearest == null || wants == null || wants == dish) return;
    stats.wrongDishes += 1;
    nearest.refuseDish(dish);
    GameAudio.instance.playRescue(GameSound.catWrong);
  }

  /// No fish left, none on the ground, and someone still needs a meal.
  bool get outOfFish {
    if (night?.scene.hasBaitInTransit == true) return false;
    if (night?.scene.usesTraps == true) {
      return bait.limited &&
          bait.fishCount <= 0 &&
          night!.run!.rescuedTonight < night!.run!.quota;
    }
    // The drying rack keeps dropping free fish, so nobody runs out.
    if (rack != null) return false;
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
      // Every cat glows faintly so calico can still be found; in the attic
      // a black cat is only seen in moonlight or once it is busy with you.
      if (moon != null &&
          cat.catType == 'black' &&
          !cat.isLit &&
          !moon!.lit(cat.center)) {
        continue;
      }
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
    return _map.obstacles.any(bounds.overlaps);
  }

  double _terrainSpeed(Vector2 center) {
    return storm?.inWater(center) == true ? .55 : 1;
  }

  /// How close a dish must land to a Scottish to count as offered to it.
  static const wrongDishReach = 150.0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isLoaded || paused || hud.status != RoundStatus.playing) return;
    for (final (point, dish, spin) in bait.dishesOut) {
      if (dish == Dish.yarn) {
        drawYarn(canvas, Offset(point.x, point.y), spin);
      } else {
        drawDish(canvas, Offset(point.x, point.y), dish);
      }
    }
    bushes?.render(canvas);
    moon?.render(canvas);
    rack?.render(canvas);
    _drawNapMats(canvas);
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
