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
import 'world/moonlit_yard.dart';
import 'systems/bait_system.dart';
import 'night_shift.dart';
import 'cats/cat_catch_rule.dart';

class MeowShelterGame extends FlameGame {
  MeowShelterGame({required this.level, this.onNextLevel});

  final LevelConfig level;
  final void Function()? onNextLevel;
  final _random = Random();
  final _shelters = <ShelterZoneComponent>[];
  late HudComponent _hud;
  RoundStatus get roundStatus => _hud.status;
  bool _restarting = false;
  double _secondAccumulator = 0;
  final _bait = BaitSystem();
  ShelterMap _map = ShelterMap.none;

  // Infinite mode: map clock drives gates and crates; twists change per map.
  double _mapClock = 0;
  bool _darkTwist = false, _bedTwist = false;

  /// Camp cats brought along on the night shift (chosen before the run).
  List<String> helpers = const ['orange'];

  /// The current night-shift run; null outside infinite mode.
  NightRun? run;
  final assist = CatAssist();

  /// Seconds until each helper's skill is ready again.
  final helperCooldown = <String, double>{};

  /// Running helper effects by breed, with seconds left.
  final _effects = <String, double>{};

  /// The night map's lanterns and moonlight.
  final yard = MoonlitYard();
  final _lanterns = <LanternComponent>[];
  bool _thickClouds = false;

  /// Cards offered at the end of a night.
  List<NightCard> cardOffer = const [];

  /// Whether the run that just ended beat the saved record.
  bool newRecord = false;
  Vector2 _bedSize = Vector2.zero();

  /// Counters for the level goals of the current round.
  RoundStats stats = RoundStats();

  /// Cats still waiting to enter on wave levels: (breed, isBoss).
  final _pending = <(String, bool)>[];

  /// Seconds until the beds swap on moving-bed levels.
  double _bedTimer = 0;
  bool _bedWarned = false;
  static const _bedInterval = 18.0;

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
    overlays.remove('nightCards');
    removeAll(children.toList());
    _shelters.clear();
    _secondAccumulator = 0;
    stats = RoundStats();
    _pending.clear();
    _bedTimer = _bedInterval;
    _bedWarned = false;
    _map = level.isInfinite ? ShelterMap.none : level.map ?? ShelterMap.none;
    _lanterns.clear();
    _mapClock = 0;
    _darkTwist = false;
    _bedTwist = false;
    run = level.isInfinite ? NightRun(helpers) : null;
    newRecord = false;
    assist.reset();
    _effects.clear();
    helperCooldown
      ..clear()
      ..addAll({for (final helper in helpers) helper: 0});
    lostReason = 'HẾT GIỜ RỒI!';
    _bait.reset(limit: level.fishLimit);
    _hud = HudComponent()..size = size;
    _hud.totalCats = level.catTypes.length;
    _hud.secondsLeft = level.timeLimit;
    _hud.isTutorial = level.isTutorial;
    _hud.isInfinite = level.isInfinite;
    _hud.goals = level.goals;
    _hud.stats = () => stats;
    _hud.fishLeft = _bait.limited ? _bait.fishCount : null;

    if (level.isInfinite) {
      add(MoonlitYardBackground());
      add(MoonlitYardOverlay(
          yard: yard, cats: () => children.whereType<CatComponent>()));
    } else {
      add(ShelterGardenComponent(
          isPlaying: () => _hud.status == RoundStatus.playing,
          map: () => _map,
          mapTime: () => _mapClock));
    }
    await _addCats();
    await _addShelters();
    if (level.isTutorial) {
      add(CatchTutorialComponent(
        cat: () => children.whereType<CatComponent>().firstOrNull,
        shelter: () => _shelters.single,
        screenSize: () => size,
        isPlaying: () => _hud.status == RoundStatus.playing,
      ));
    }
    if (level.darkness || level.isInfinite) {
      add(DarknessComponent(
          lights: level.isInfinite ? _yardLights : _lights,
          visible: () =>
              _hud.status == RoundStatus.playing &&
              (level.darkness || _darkTwist || level.isInfinite),
          shade: level.isInfinite
              ? const Color(0x9A0E1430)
              : const Color(0xF0101828)));
    }
    add(_hud);
    if (level.twistLines.isNotEmpty && !level.isTutorial) {
      _hud.showBanner(level.twistLines, 4);
    }
    add(FishItemComponent(
      enabled: () => canPlaceFish,
      visible: () => _hud.status == RoundStatus.playing,
      placeFish: _placeFish,
    ));
    if (run != null) _beginNight();
  }

  Future<void> _addCats() async {
    // Night-shift cats arrive night by night (see _fillField).
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
      _spawnCat(type, boss: boss);
    }
    _pending.addAll(queue.skip(first));
  }

  void _spawnCat(String type, {bool boss = false}) {
    final catLevel = run != null ? _nightLevel() : level;
    add(CatComponent(
      position: level.isTutorial
          ? Vector2(size.x * .43 - catWidth / 2, size.y * .43 - catHeight / 2)
          : _randomCatPosition(),
      catType: type,
      level: catLevel,
      isBoss: boss,
      isBlocked: _isMapBlocked,
      terrainSpeed: _terrainSpeed,
      onStartled: (_) => stats.startles += 1,
      onDrop: _handleDrop,
      onDelivered: _handleDelivered,
      onEscaped: _handleEscape,
      isPlaying: () => _hud.status == RoundStatus.playing,
      assist: run != null ? assist : null,
      // On the night yard, cats in the light are calmer and wait longer.
      inLight: run != null
          ? (cat) => yard.isLit(
              (cat.position + cat.size / 2).toOffset(), size.toSize())
          : null,
    ));
  }

  Future<void> _addShelters() async {
    final bedSize = Vector2(size.x * 0.20, size.x * 0.133);
    _bedSize = bedSize;
    final shelters = shelterLayout(level.catTypes);
    for (final shelter in shelters) {
      final component = ShelterZoneComponent(
        catType: shelter.type,
        label: shelter.label,
        size: bedSize,
        position: level.isTutorial
            ? Vector2(size.x * .74, size.y * .42)
            : Vector2(size.x * shelter.x, size.y * shelter.y),
      );
      _shelters.add(component);
      add(component);
    }
  }

  bool _handleDrop(CatComponent cat) {
    if (_hud.status != RoundStatus.playing) return false;
    // Calico helper: any bed bounces the cat into its own.
    if (_effects.containsKey('calico') &&
        _shelters.any((shelter) => shelter.covers(cat))) {
      return true;
    }
    final isCorrect = _shelters.any((shelter) => shelter.accepts(cat));
    if (!isCorrect && _shelters.any((shelter) => shelter.covers(cat))) {
      stats.wrongDrops += 1;
    }
    return isCorrect;
  }

  void _handleDelivered(CatComponent cat) {
    if (_hud.status != RoundStatus.playing) return;
    _hud.delivered += 1;
    // Practice rounds are replayable, so they do not pay out coins.
    if (!level.isTutorial) unawaited(CampState.instance.rescue(cat.catType));
    final run = this.run;
    if (run != null) {
      run.rescuedTonight += 1;
      run.totalRescued += 1;
      _hud.tonight = run.rescuedTonight;
      // Deal cards pay extra on top of the usual 5 coins per cat.
      final bonus = (5 * run.coinBonus).round();
      run.coins += 5 + bonus;
      if (bonus > 0) unawaited(CampState.instance.addCoins(bonus));
      if (run.rescuedTonight >= run.quota) {
        _endNight();
      } else {
        _fillField();
      }
    } else if (_hud.delivered >= _hud.totalCats) {
      _showResult(RoundStatus.won);
    } else if (_pending.isNotEmpty) {
      final (type, boss) = _pending.removeAt(0);
      _spawnCat(type, boss: boss);
      if (boss) {
        GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
        _hud.showBanner(['Trùm xuất hiện!', level.twistLines.first]);
      }
    }
  }

  void _handleEscape(CatComponent cat) {
    if (_hud.status != RoundStatus.playing) return;
    if (level.isInfinite) {
      lostReason = 'MÈO ĐÃ CHẠY MẤT!';
      _showResult(RoundStatus.lost);
      return;
    }
    // Mèo chạy ra ngoài được thay bằng một mèo cùng loại để màn vẫn có thể thắng.
    _spawnCat(cat.catType, boss: cat.isBoss);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || _hud.status != RoundStatus.playing) return;
    _bait.update(children.whereType<CatComponent>());
    _mapClock += dt;
    if (level.isInfinite) {
      _updateInfinite(dt);
      return;
    }
    // Let the last rescued cat finish its success animations before ending.
    if (_hud.delivered >= _hud.totalCats) return;
    if (level.isTutorial || level.isInfinite) return;
    if (level.movingBeds) _updateMovingBeds(dt);
    if (_outOfFish) {
      lostReason = 'HẾT CÁ RỒI!';
      _showResult(RoundStatus.lost);
      return;
    }
    _secondAccumulator += dt;
    if (_secondAccumulator >= 1) {
      _secondAccumulator -= 1;
      _hud.secondsLeft -= 1;
      if (_hud.secondsLeft == 10) {
        GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
      }
      if (_hud.secondsLeft <= 0) _showResult(RoundStatus.lost);
    }
  }

  int lastStars = 0;

  /// Cats rescued this round, for the result board.
  int get rescued => _hud.delivered;

  void _showResult(RoundStatus status) {
    if (_hud.status != RoundStatus.playing) return;
    GameAudio.instance.playRescue(
        status == RoundStatus.won ? GameSound.rescueWin : GameSound.rescueLose,
        important: true);
    _hud.status = status;
    final run = this.run;
    if (run != null) {
      newRecord =
          CampState.instance.recordNightShift(run.night, run.totalRescued);
    }
    if (status == RoundStatus.won && !level.isInfinite) {
      stats.secondsLeft = _hud.secondsLeft;
      lastStars = starsFor(level, stats);
      unawaited(CampState.instance.recordLevel(level.id, lastStars));
    }
    overlays.add('roundResult');
  }

  bool get canPlaceFish =>
      isLoaded &&
      _hud.status == RoundStatus.playing &&
      _bait.canPlace &&
      (!level.isTutorial ||
          (_bait.positions.isEmpty &&
              !children.whereType<CatComponent>().any((cat) => cat.hasEaten)));

  void _placeFish(Vector2 point) {
    if (!canPlaceFish) return;
    final reach = Vector2(catWidth, catHeight);
    if (_isMapBlocked(point - reach / 2, reach)) {
      _hud.showBanner(['Mèo không tới được chỗ này'], 1.5);
      return;
    }
    if (_bait.place(point, size, children.whereType<CatComponent>())) {
      GameAudio.instance.playRescue(GameSound.baitDrop);
      stats.fishUsed += 1;
      if (_bait.limited) _hud.fishLeft = _bait.fishCount;
    }
  }

  /// No fish left, none on the ground, and someone still needs a meal.
  bool get _outOfFish {
    if (!_bait.limited || _bait.fishCount > 0 || _bait.hasBaitOut) {
      return false;
    }
    final cats = children.whereType<CatComponent>().toList();
    if (cats.any((cat) => cat.isLit || cat.isDelivered)) return false;
    return cats.any((cat) => cat.catType != 'calico') ||
        _pending.any((entry) => entry.$1 != 'calico');
  }

  void _updateMovingBeds(double dt) {
    _bedTimer -= dt;
    if (!_bedWarned && _bedTimer <= 3) {
      GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
      _bedWarned = true;
      _hud.showBanner(['Ổ sắp dời chỗ!'], 2.5);
    }
    // Never pull a bed away while the player is carrying a cat.
    if (_bedTimer > 0 ||
        children.whereType<CatComponent>().any((cat) => cat.isCarried)) {
      return;
    }
    _bedTimer = _bedInterval;
    _bedWarned = false;
    final spots = [for (final shelter in _shelters) shelter.position.clone()];
    if (spots.length < 2) return;
    for (var i = 0; i < _shelters.length; i++) {
      _shelters[i].add(MoveToEffect(spots[(i + 1) % spots.length],
          EffectController(duration: .7, curve: Curves.easeInOutCubic)));
    }
  }

  /// Light pools for the night yard: lanterns and moonlight do the real
  /// lighting; fish, beds and cats glow just enough to be found.
  Iterable<(Offset, double)> _yardLights() sync* {
    yield* yard.lights(size.toSize());
    for (final fish in _bait.positions) {
      yield (Offset(fish.x, fish.y), 55);
    }
    for (final shelter in _shelters) {
      yield (shelter.center.toOffset(), 75);
    }
    for (final cat in children.whereType<CatComponent>()) {
      yield (cat.center.toOffset(), cat.catchWindow.canCatch ? 48 : 34);
    }
  }

  void _tapLantern(YardLantern lantern) {
    if (_hud.status != RoundStatus.playing || overlays.isActive('nightCards')) {
      return;
    }
    if (yard.light(lantern)) {
      GameAudio.instance.playRescue(GameSound.baitDrop);
    } else if (!lantern.lit) {
      _hud.showBanner(['Đèn đang nguội, chờ một chút'], 1.2);
    }
  }

  /// Light pools for dark levels.
  Iterable<(Offset, double)> _lights() sync* {
    for (final fish in _bait.positions) {
      yield (Offset(fish.x, fish.y), 120);
    }
    for (final shelter in _shelters) {
      yield (shelter.center.toOffset(), 80);
    }
    for (final cat in children.whereType<CatComponent>()) {
      // Every cat glows faintly so calico can still be found.
      yield (cat.center.toOffset(), cat.isLit ? 85 : 40);
    }
  }

  void _shuffleShelters() {
    final slots = shelterLayout(level.catTypes)
        .map((shelter) => Vector2(size.x * shelter.x, size.y * shelter.y))
        .toList()
      ..shuffle(_random);
    for (var i = 0; i < _shelters.length && i < slots.length; i++) {
      _shelters[i].position = slots[i];
    }
  }

  bool _isMapBlocked(Vector2 position, Vector2 size) {
    final bounds = Rect.fromLTWH(position.x / this.size.x,
        position.y / this.size.y, size.x / this.size.x, size.y / this.size.y);
    return _map.blockersAt(_mapClock).any(bounds.overlaps);
  }

  double _terrainSpeed(Vector2 center) {
    final point = Offset(center.x / size.x, center.y / size.y);
    return _map.mud.any((mud) => mud.contains(point)) ? ShelterMap.mudSpeed : 1;
  }

  /// Difficulty of the current night, with the run's card bonuses.
  LevelConfig _nightLevel() {
    final run = this.run!;
    final wave = run.night - 1;
    return LevelConfig(
      id: level.id,
      name: level.name,
      catTypes: level.catTypes,
      timeLimit: 0,
      speedMultiplier: (.8 + wave * .08).clamp(.8, 1.5) * run.speed,
      readySeconds: (3 - wave * .15).clamp(1.5, 3.0) * run.ready,
      gripSeconds: (4 - wave * .12).clamp(2.4, 4.0) * run.grip,
      skillTier: wave.clamp(0, 3),
      isInfinite: true,
    );
  }

  /// Harder breeds turn up more often as the nights go on, and the same
  /// breed never comes three times in a row.
  String _nightCatType() {
    final night = run!.night;
    final weights = {
      'orange': 3.0,
      'himalaya': 2.0 + night * .1,
      'scottish': 2.0 + night * .1,
      'calico': 1.0 + night * .2,
      'black': 1.0 + night * .2,
    };
    if (_recentTypes.length >= 2 && _recentTypes[0] == _recentTypes[1]) {
      weights.remove(_recentTypes[0]);
    }
    var roll = _random.nextDouble() * weights.values.reduce((a, b) => a + b);
    var type = weights.keys.last;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) {
        type = entry.key;
        break;
      }
    }
    _recentTypes.insert(0, type);
    if (_recentTypes.length > 2) _recentTypes.removeLast();
    return type;
  }

  final _recentTypes = <String>[];

  /// Tops the field up to the night's crowd size until the quota is out.
  void _fillField() {
    final run = this.run!;
    // Counted from the run, not from children: removals and additions are
    // only applied on the next tick.
    var onField = run.spawnedTonight - run.rescuedTonight;
    while (onField < run.fieldSize && run.spawnedTonight < run.quota) {
      run.spawnedTonight += 1;
      onField += 1;
      // The last cat of a boss night is the boss.
      if (run.bossNight && run.spawnedTonight == run.quota) {
        final type = _nightCatType();
        _spawnCat(type, boss: true);
        GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
        _hud.showBanner(['Trùm xuất hiện!', CatCatchRule.bossHint(type)]);
      } else {
        _spawnCat(_nightCatType());
      }
    }
  }

  /// Sets up the next night: map, twist, beds, fish, clock and first cats.
  void _beginNight() {
    final run = this.run!;
    final night = run.night;
    run
      ..rescuedTonight = 0
      ..spawnedTonight = 0;
    _mapClock = 0;
    if (night > 1) _shuffleShelters();
    for (final shelter in _shelters) {
      final center = shelter.position + shelter.size / 2;
      shelter.size = _bedSize * run.bedScale;
      shelter.position = center - shelter.size / 2;
    }
    var twist = night == 1 ? 0 : _random.nextInt(4);
    if (twist == 1 && run.has(NightCard.fullMoon)) twist = 0;
    if (twist == 2 && run.has(NightCard.nailedBeds)) twist = 0;
    _thickClouds = twist == 1;
    _bedTwist = twist == 2;
    yard.setup(
        count: run.lanterns,
        burnTime: run.lanternBurn,
        lightScale: run.lanternLight,
        fullMoon: run.has(NightCard.fullMoon),
        thickClouds: _thickClouds);
    removeAll(_lanterns);
    _lanterns
      ..clear()
      ..addAll([
        for (final lantern in yard.lanterns)
          LanternComponent(lantern: lantern, onTapLantern: _tapLantern)
      ]);
    addAll(_lanterns);
    _bedTimer = _bedInterval;
    _bedWarned = false;
    var fish = twist == 3 ? 6 : 0;
    if (run.has(NightCard.hiddenFish)) fish = fish == 0 ? 8 : min(fish, 8);
    if (fish > 0) fish += run.extraFish;
    _bait.reset(limit: fish);
    _hud
      ..fishLeft = _bait.limited ? _bait.fishCount : null
      ..night = night
      ..tonight = 0
      ..totalCats = run.quota
      ..secondsLeft = run.seconds;
    _secondAccumulator = 0;
    _effects.clear();
    _syncAssist();
    _hud
      ..bossNight = run.bossNight
      ..nightNotes = [
        '${run.map.title}: ${run.map.rule}',
        if (night == 1) 'Mèo trong vùng sáng ngoan hơn, chờ bế lâu gấp đôi',
        if (_thickClouds) 'Mây dày: trăng bị che lâu hơn',
        if (_bedTwist) 'Các ổ dời chỗ sau mỗi ${_bedInterval.round()} giây',
        if (_bait.limited) 'Chỉ có ${_bait.fishCount} cá mồi cả đêm',
        if (run.bossNight) 'Con mèo cuối cùng là mèo trùm',
      ]
      ..nightTags = [
        if (_thickClouds) 'Mây dày',
        if (_bedTwist) 'Ổ dời chỗ',
        if (_bait.limited) '${_bait.fishCount} cá',
        if (run.bossNight) 'Có trùm',
      ]
      ..startNight();
    _fillField();
  }

  /// Quota met: bank the night bonus and offer the cards.
  void _endNight() {
    final run = this.run!;
    GameAudio.instance.playRescue(GameSound.rescueMilestone, important: true);
    final bonus = (5 * run.night * (1 + run.coinBonus)).round();
    run.coins += bonus;
    unawaited(CampState.instance.addCoins(bonus));
    _bait.reset();
    _effects.clear();
    _syncAssist();
    cardOffer = run.offer(_random, run.mapFor(run.night + 1));
    overlays.add('nightCards');
    pauseEngine();
  }

  /// Takes a card from the end-of-night offer and starts the next night.
  void chooseCard(NightCard card) {
    final run = this.run;
    if (run == null || !overlays.isActive('nightCards')) return;
    run.cards.add(card);
    run.night += 1;
    _beginNight();
    overlays.remove('nightCards');
    resumeEngine();
  }

  /// Full recharge time of a helper's skill.
  double helperCooldownTotal(String type) =>
      NightHelperSkill.of[type]!.cooldownFor(
          bonded: CampState.instance.bonded(type),
          scale: run?.cooldownScale ?? 1);

  /// Seconds left on a running helper effect (0 when off).
  double effectLeft(String type) => _effects[type] ?? 0;

  /// Fires a helper's skill if it is ready.
  void useHelper(String type) {
    final skill = NightHelperSkill.of[type];
    if (run == null ||
        skill == null ||
        _hud.status != RoundStatus.playing ||
        overlays.isActive('nightCards') ||
        (helperCooldown[type] ?? 1) > 0) {
      return;
    }
    helperCooldown[type] = helperCooldownTotal(type);
    GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
    _hud.showBanner([CampState.instance.nameOf(type), skill.effect], 2.5);
    if (skill.duration > 0) {
      _effects[type] = skill.duration;
      _syncAssist();
      return;
    }
    // Himalaya: two hungry cats are full at once.
    final cats = children
        .whereType<CatComponent>()
        .where((cat) => cat.canBless)
        .toList()
      ..shuffle(_random);
    for (final cat in cats.take(2)) {
      cat.bless();
    }
  }

  void _syncAssist() {
    assist
      ..pace = _effects.containsKey('scottish') ? .5 : 1
      ..lure = run?.lure ?? 1
      ..calm = _effects.containsKey('black')
      ..frozen = _effects.containsKey('orange');
    _hud.anyBed = _effects.containsKey('calico');
  }

  void _updateInfinite(double dt) {
    yard.update(dt);
    for (final type in helperCooldown.keys.toList()) {
      helperCooldown[type] = max(0, helperCooldown[type]! - dt);
    }
    for (final type in _effects.keys.toList()) {
      final left = _effects[type]! - dt;
      if (left > 0) {
        _effects[type] = left;
      } else {
        _effects.remove(type);
        _syncAssist();
      }
    }
    if (_bedTwist) _updateMovingBeds(dt);
    if (_outOfFish) {
      lostReason = 'HẾT CÁ RỒI!';
      _showResult(RoundStatus.lost);
      return;
    }
    _secondAccumulator += dt;
    if (_secondAccumulator >= 1) {
      _secondAccumulator -= 1;
      _hud.secondsLeft -= 1;
      if (_hud.secondsLeft == 10) {
        GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
      }
      if (_hud.secondsLeft <= 0) {
        lostReason = 'TRỜI SÁNG MẤT RỒI!';
        _showResult(RoundStatus.lost);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isLoaded || _hud.status != RoundStatus.playing) return;
    for (final fish in _bait.positions) {
      drawFish(canvas, Offset(fish.x, fish.y));
    }
  }

  Vector2 _randomCatPosition() {
    for (var i = 0;; i++) {
      final x =
          size.x * .22 + _random.nextDouble() * max(0, size.x * .56 - catWidth);
      final y = size.y * 0.28 + _random.nextDouble() * (size.y * 0.32);
      final spot = Vector2(x, y);
      if (i >= 20 || !_isMapBlocked(spot, Vector2(catWidth, catHeight))) {
        return spot;
      }
    }
  }
}
