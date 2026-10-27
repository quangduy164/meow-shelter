import 'package:flame/components.dart';
import 'package:flame/cache.dart';
import '../constants.dart';
import 'cat_state.dart';

Future<Map<CatState, SpriteAnimation>> loadCatAnimations(
    Images images, String catType) async {
  final folder = 'Cat/${catType[0].toUpperCase()}${catType.substring(1)}';
  Future<SpriteAnimation> loadAnimation(String name, int count,
      {double stepTime = animationStepTime}) async {
    final image = await images.load('$folder/$name');
    return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
            amount: count, stepTime: stepTime, textureSize: Vector2(256, 256)));
  }

  return {
    CatState.idle: await loadAnimation('cat-$catType-idle.png', framesIdle),
    CatState.walk: await loadAnimation('cat-$catType-walk.png', framesWalk),
    CatState.run: await loadAnimation('cat-$catType-run.png', framesRun),
    CatState.turnAround: await loadAnimation(
      'cat-$catType-turn-around.png',
      framesTurnAround,
    ),
    CatState.dashEscape: await loadAnimation(
      'cat-$catType-dash-escape.png',
      framesDashEscape,
    ),
    CatState.panic: await loadAnimation('cat-$catType-panic.png', framesPanic),
    CatState.dragged: await loadAnimation(
      'cat-$catType-dragged.png',
      framesDragged,
    ),
    CatState.dropSuccess: await loadAnimation(
      'cat-$catType-drop-success.png',
      framesDropSuccess,
    ),
    CatState.celebrate: await loadAnimation(
      'cat-$catType-celebrate.png',
      framesCelebrate,
    ),
    CatState.dropWrong: await loadAnimation(
      'cat-$catType-drop-wrong.png',
      framesDropWrong,
    ),
    CatState.vanish: await loadAnimation(
      'cat-$catType-vanish.png',
      framesVanish,
      stepTime: vanishStepTime,
    ),
  };
}
