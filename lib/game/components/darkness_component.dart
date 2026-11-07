import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Lights-off layer for dark levels: the field is night-dark except for
/// soft pools of light at [lights] (fish, beds and cats that are ready).
class DarknessComponent extends PositionComponent with HasGameRef {
  DarknessComponent({required this.lights, required this.visible})
      : super(priority: 80);

  final Iterable<(Offset, double)> Function() lights;
  final bool Function() visible;
  double _clock = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!visible()) return;
    final area = Offset.zero & Size(gameRef.size.x, gameRef.size.y);
    canvas.saveLayer(area, Paint());
    canvas.drawRect(area, Paint()..color = const Color(0xF0101828));
    for (final (center, radius) in lights()) {
      final r = radius * (1 + math.sin(_clock * 2.4 + center.dx) * .04);
      canvas.drawCircle(
          center,
          r,
          Paint()
            ..blendMode = BlendMode.dstOut
            ..shader = Gradient.radial(center, r, const [
              Color(0xFF000000),
              Color(0xCC000000),
              Color(0x00000000),
            ], const [
              0,
              .55,
              1
            ]));
    }
    canvas.restore();
    // Faint fireflies so the dark field does not feel empty.
    for (var i = 0; i < 7; i++) {
      final t = _clock * .4 + i * 1.7;
      final p = Offset(gameRef.size.x * (.1 + .8 * ((i * .37 + (t * .13)) % 1)),
          gameRef.size.y * (.25 + .45 * (.5 + .5 * _wave(t * 1.3 + i))));
      final glow = .4 + .6 * (.5 + .5 * _wave(t * 3 + i * 2));
      canvas.drawCircle(
          p, 5, Paint()..color = Color.fromRGBO(255, 236, 140, .18 * glow));
      canvas.drawCircle(
          p, 1.6, Paint()..color = Color.fromRGBO(255, 244, 190, .9 * glow));
    }
  }

  static double _wave(double x) => math.sin(x);
}
