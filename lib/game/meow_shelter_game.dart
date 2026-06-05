import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/components.dart';

import 'components/orange_cat.dart';
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

    // Spawn vài con mèo cam ở vị trí random
    const catCount = 4;
    for (var i = 0; i < catCount; i++) {
      final x = _random.nextDouble() * (size.x - catWidth);
      final y = size.y * 0.3 + _random.nextDouble() * (size.y * 0.5);
      add(OrangeCat(position: Vector2(x, y)));
    }
  }
}
