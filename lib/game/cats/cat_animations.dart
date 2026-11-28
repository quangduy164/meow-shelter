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
    CatState.idle: await loadAnimation('cat-$catType-idle.webp', framesIdle),
    CatState.walk: await loadAnimation('cat-$catType-walk.webp', framesWalk),
    CatState.run: await loadAnimation('cat-$catType-run.webp', framesRun),
    CatState.turnAround: await loadAnimation(
      'cat-$catType-turn-around.webp',
      framesTurnAround,
    ),
    CatState.dashEscape: await loadAnimation(
      'cat-$catType-dash-escape.webp',
      framesDashEscape,
    ),
    CatState.panic: await loadAnimation('cat-$catType-panic.webp', framesPanic),
    CatState.dragged: await loadAnimation(
      'cat-$catType-dragged.webp',
      framesDragged,
    ),
    CatState.dropSuccess: await loadAnimation(
      'cat-$catType-drop-success.webp',
      framesDropSuccess,
    ),
    CatState.celebrate: await loadAnimation(
      'cat-$catType-celebrate.webp',
      framesCelebrate,
    ),
    CatState.dropWrong: await loadAnimation(
      'cat-$catType-drop-wrong.webp',
      framesDropWrong,
    ),
    CatState.vanish: await loadAnimation(
      'cat-$catType-vanish.webp',
      framesVanish,
      stepTime: vanishStepTime,
    ),
    CatState.sleep: await loadAnimation(
      'cat-$catType-sleep.webp',
      framesSleep,
      stepTime: sleepStepTime,
    ),
  };
}
