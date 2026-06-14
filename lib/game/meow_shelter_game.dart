import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/components.dart';

import 'components/cat_component.dart';
import 'constants.dart';

class MeowShelterGame extends FlameGame {
  final _random = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Background full màn hình
    final bg = await loadSprite('Background/background-lever-1.png');
    add(
      SpriteComponent(
        sprite: bg,
        size: size,
        position: Vector2.zero(),
      ),
    );

    // Spawn 2 mèo cam
    for (var i = 0; i < 2; i++) {
      add(CatComponent(
        position: _randomCatPosition(),
        catType: 'orange',
      ));
    }

    // Spawn 2 mèo himalaya
    for (var i = 0; i < 2; i++) {
      add(CatComponent(
        position: _randomCatPosition(),
        catType: 'himalaya',
      ));
    }

    // Spawn 2 mèo scottish
    for (var i = 0; i < 2; i++) {
      add(CatComponent(
        position: _randomCatPosition(),
        catType: 'scottish',
      ));
    }

    // Spawn 2 mèo calico
    for (var i = 0; i < 2; i++) {
      add(CatComponent(
        position: _randomCatPosition(),
        catType: 'calico',
      ));
    }
  }

  Vector2 _randomCatPosition() {
    final x = _random.nextDouble() * (size.x - catWidth);
    final y = size.y * 0.3 + _random.nextDouble() * (size.y * 0.5);
    return Vector2(x, y);
  }
}
