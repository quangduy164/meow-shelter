import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'components/cat_component.dart';
import 'components/hud_component.dart';
import 'components/shelter_zone_component.dart';
import 'constants.dart';

class MeowShelterGame extends FlameGame with TapCallbacks {
  final _random = Random();
  final _shelters = <ShelterZoneComponent>[];
  late HudComponent _hud;
  double _secondAccumulator = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _startRound();
  }

  Future<void> _startRound() async {
    removeAll(children.toList());
    _shelters.clear();
    _secondAccumulator = 0;
    _hud = HudComponent()..size = size;

    final background = await loadSprite('Background/shelter-yard-background.png');
    add(SpriteComponent(sprite: background, size: size, priority: -100));
    await _addCats();
    await _addShelters();
    add(_hud);
  }

  Future<void> _addCats() async {
    for (final type in ['orange', 'himalaya', 'scottish', 'calico']) {
      for (var i = 0; i < 2; i++) {
        add(CatComponent(
          position: _randomCatPosition(),
          catType: type,
          onDrop: _handleDrop,
          onDelivered: _handleDelivered,
        ));
      }
    }
  }

  Future<void> _addShelters() async {
    final bedSize = Vector2(size.x * 0.20, size.x * 0.133);
    final shelters = <({String type, String label, String asset, double x, double y})>[
      (type: 'orange', label: 'MÈO CAM', asset: 'Bed/bed-orange.png', x: 0.00, y: 0.20),
      (type: 'himalaya', label: 'HIMALAYA', asset: 'Bed/bed-himalaya.png', x: 0.80, y: 0.20),
      (type: 'scottish', label: 'SCOTTISH', asset: 'Bed/bed-scottish.png', x: 0.00, y: 0.59),
      (type: 'calico', label: 'CALICO', asset: 'Bed/bed-calico.png', x: 0.80, y: 0.59),
    ];
    for (final shelter in shelters) {
      final component = ShelterZoneComponent(
        catType: shelter.type,
        sprite: await loadSprite(shelter.asset),
        size: bedSize,
        position: Vector2(size.x * shelter.x, size.y * shelter.y),
      );
      _shelters.add(component);
      add(component);
      add(
        TextComponent(
          text: shelter.label,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFF5B3516),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          anchor: Anchor.center,
          position: component.position +
              Vector2(component.size.x * 0.5, component.size.y * 0.64),
          priority: 1,
        ),
      );
    }
  }

  bool _handleDrop(CatComponent cat) {
    if (_hud.status != RoundStatus.playing) return false;
    final isCorrect = _shelters.any((shelter) => shelter.accepts(cat));
    if (isCorrect) {
      _hud.score += 10;
      _hud.delivered += 1;
    } else {
      _hud.lives -= 1;
      if (_hud.lives <= 0) _hud.status = RoundStatus.lost;
    }
    return isCorrect;
  }

  void _handleDelivered(CatComponent cat) {
    if (_hud.delivered >= _hud.totalCats) _hud.status = RoundStatus.won;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || _hud.status != RoundStatus.playing) return;
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
      _startRound();
    }
  }

  Vector2 _randomCatPosition() {
    final x = _random.nextDouble() * (size.x - catWidth);
    final y = size.y * 0.30 + _random.nextDouble() * (size.y * 0.42);
    return Vector2(x, y);
  }
}
