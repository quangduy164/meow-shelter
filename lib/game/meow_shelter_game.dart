import 'dart:async';
import 'dart:math';

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
import 'systems/bait_system.dart';

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
  int _nextCatType = 0;
  bool _darkTwist = false, _bedTwist = false;

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

  Future<void> restartRound() async {
    if (_restarting) return;
    _restarting = true;
    try {
      await _startRound();
    } finally {
      _restarting = false;
    }
  }

  Future<void> _startRound() async {
    overlays.remove('roundResult');
    removeAll(children.toList());
    _shelters.clear();
    _secondAccumulator = 0;
    stats = RoundStats();
    _pending.clear();
    _bedTimer = _bedInterval;
    _bedWarned = false;
    _map =
        level.isInfinite ? ShelterMap.maps.first : level.map ?? ShelterMap.none;
    _mapClock = 0;
    _nextCatType = 0;
    _darkTwist = false;
    _bedTwist = false;
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

    add(ShelterGardenComponent(
        isPlaying: () => _hud.status == RoundStatus.playing,
        map: () => _map,
        mapTime: () => _mapClock));
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
          lights: _lights,
          visible: () =>
              _hud.status == RoundStatus.playing &&
              (level.darkness || _darkTwist)));
    }
    add(_hud);
    if (level.twistLines.isNotEmpty && !level.isTutorial) {
      _hud.showBanner(level.twistLines, 4);
    }
    if (level.isInfinite) {
      _hud.showBanner(['BẢN ĐỒ: ${_map.name.toUpperCase()}', _map.rule], 4);
    }
    add(FishItemComponent(
      enabled: () => canPlaceFish,
      visible: () => _hud.status == RoundStatus.playing,
      placeFish: _placeFish,
    ));
  }

  Future<void> _addCats() async {
    if (level.isInfinite) {
      for (var i = 0; i < 2; i++) {
        _spawnCat(_nextInfiniteType());
      }
      return;
    }
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
    final catLevel =
        level.isInfinite ? level.forInfiniteProgress(_hud.delivered) : level;
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
    ));
  }

  Future<void> _addShelters() async {
    final bedSize = Vector2(size.x * 0.20, size.x * 0.133);
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
    if (level.isInfinite) {
      if (_hud.delivered % 5 == 0) _enterNextMap();
      _spawnCat(_nextInfiniteType());
      if (_hud.delivered % 5 == 0 &&
          children.whereType<CatComponent>().length < 5) {
        _spawnCat(_nextInfiniteType());
      }
    } else if (_hud.delivered >= _hud.totalCats) {
      _showResult(RoundStatus.won);
    } else if (_pending.isNotEmpty) {
      final (type, boss) = _pending.removeAt(0);
      _spawnCat(type, boss: boss);
      if (boss) _hud.showBanner(['Trùm xuất hiện!', level.twistLines.first]);
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
      if (_hud.secondsLeft <= 0) _showResult(RoundStatus.lost);
    }
  }

  int lastStars = 0;

  /// Cats rescued this round, for the result board.
  int get rescued => _hud.delivered;

  void _showResult(RoundStatus status) {
    _hud.status = status;
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

  String _nextInfiniteType() =>
      level.catTypes[_nextCatType++ % level.catTypes.length];

  void _updateInfinite(double dt) {
    if (_bedTwist) _updateMovingBeds(dt);
    if (_outOfFish) {
      lostReason = 'HẾT CÁ RỒI!';
      _showResult(RoundStatus.lost);
    }
  }

  /// Every five rescues: next map, shuffled beds and a random twist.
  void _enterNextMap() {
    _map = ShelterMap.maps[(_hud.delivered ~/ 5) % ShelterMap.maps.length];
    _mapClock = 0;
    _shuffleShelters();
    final twist = _random.nextInt(4);
    _darkTwist = twist == 1;
    _bedTwist = twist == 2;
    _bedTimer = _bedInterval;
    _bedWarned = false;
    _bait.limited = twist == 3;
    _bait.fishCount = twist == 3 ? 6 : 0;
    _hud.fishLeft = _bait.limited ? _bait.fishCount : null;
    for (final cat in children.whereType<CatComponent>()) {
      if (!cat.isCarried && _isMapBlocked(cat.position, cat.size)) {
        cat.position = _randomCatPosition();
      }
    }
    _hud.showBanner([
      'BẢN ĐỒ: ${_map.name.toUpperCase()}',
      _map.rule,
      if (twist == 1) 'Tắt đèn! Thả cá để soi đường',
      if (twist == 2) 'Các ổ sẽ dời chỗ',
      if (twist == 3) 'Chỉ có 6 cá mồi',
    ], 4);
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
