import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'components/cat_component.dart';
import 'components/fish_item_component.dart';
import 'components/catch_tutorial_component.dart';
import '../collection/fish_collection.dart';
import 'components/hud_component.dart';
import 'components/shelter_zone_component.dart';
import 'constants.dart';
import '../levels/level_config.dart';
import 'world/shelter_layout.dart';
import 'systems/bait_system.dart';

class MeowShelterGame extends FlameGame with TapCallbacks {
  MeowShelterGame({required this.level, this.onNextLevel});

  final LevelConfig level;
  final void Function()? onNextLevel;
  final _random = Random();
  final _shelters = <ShelterZoneComponent>[];
  late HudComponent _hud;
  double _secondAccumulator = 0;
  final _bait = BaitSystem();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _startRound();
  }

  Future<void> _startRound() async {
    removeAll(children.toList());
    _shelters.clear();
    _secondAccumulator = 0;
    _bait.reset(
        ownedFish: level.isTutorial
            ? max(1, FishCollection.instance.count)
            : FishCollection.instance.count);
    _hud = HudComponent()..size = size;
    _hud.totalCats = level.catTypes.length;
    _hud.secondsLeft = level.timeLimit;
    _hud.isTutorial = level.isTutorial;
    _hud.hasNextLevel = onNextLevel != null;
    _hud.levelTitle = 'MÀN ${level.id} · ${level.name.toUpperCase()}';

    final background =
        await loadSprite('Background/shelter-yard-background.png');
    add(SpriteComponent(sprite: background, size: size, priority: -100));
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
    add(_hud);
    add(FishItemComponent(
      enabled: () => canPlaceFish,
      visible: () => _hud.status == RoundStatus.playing,
      placeFish: _placeFish,
    ));
  }

  Future<void> _addCats() async {
    for (final type in level.catTypes) {
      _spawnCat(type);
    }
  }

  void _spawnCat(String type) {
    add(CatComponent(
      position: level.isTutorial
          ? Vector2(size.x * .43 - catWidth / 2, size.y * .5 - catHeight / 2)
          : _randomCatPosition(),
      catType: type,
      level: level,
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
            ? Vector2(size.x * .74, size.y * .43)
            : Vector2(size.x * shelter.x, size.y * shelter.y),
      );
      _shelters.add(component);
      add(component);
    }
  }

  bool _handleDrop(CatComponent cat) {
    if (_hud.status != RoundStatus.playing) return false;
    final isCorrect = _shelters.any((shelter) => shelter.accepts(cat));
    if (isCorrect) {
      _hud.delivered += 1;
    }
    return isCorrect;
  }

  void _handleDelivered(CatComponent cat) {
    if (_hud.status == RoundStatus.playing &&
        _hud.delivered >= _hud.totalCats) {
      _hud.status = RoundStatus.won;
    }
  }

  void _handleEscape(CatComponent cat) {
    if (_hud.status != RoundStatus.playing) return;
    // Mèo chạy ra ngoài được thay bằng một bé cùng loại để màn vẫn có thể thắng.
    _spawnCat(cat.catType);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || _hud.status != RoundStatus.playing) return;
    _bait.update(children.whereType<CatComponent>());
    // Let the last rescued cat finish its success animations before ending.
    if (_hud.delivered >= _hud.totalCats) return;
    if (level.isTutorial) return;
    _secondAccumulator += dt;
    if (_secondAccumulator >= 1) {
      _secondAccumulator -= 1;
      _hud.secondsLeft -= 1;
      if (_hud.secondsLeft <= 0) _hud.status = RoundStatus.lost;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (isLoaded && _hud.status != RoundStatus.playing) {
      if (!_hud.actionButton
          .contains(Offset(event.localPosition.x, event.localPosition.y))) {
        return;
      }
      if (_hud.status == RoundStatus.won && onNextLevel != null) {
        onNextLevel!();
      } else {
        _startRound();
      }
      return;
    }
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
    _bait.place(point, size, children.whereType<CatComponent>());
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
    final x =
        size.x * .22 + _random.nextDouble() * max(0, size.x * .56 - catWidth);
    final y = size.y * 0.30 + _random.nextDouble() * (size.y * 0.33);
    return Vector2(x, y);
  }
}
