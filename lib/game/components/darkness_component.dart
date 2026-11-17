import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Lights-off layer for dark levels: the field is night-dark except for
/// soft pools of light at [lights] (fish, beds and cats that are ready).
class DarknessComponent extends PositionComponent with HasGameReference {
  DarknessComponent(
      {required this.lights,
      required this.visible,
      this.shade = const Color(0xF0101828),
      this.additionalLights})
      : super(priority: 80);

  /// Colour of the dark; a lighter shade keeps the scenery faintly visible.
  final Color shade;

  /// Non-circular light sources erase their footprint from this dark layer.
  final void Function(Canvas canvas, Size size)? additionalLights;

  final Iterable<(Offset, double)> Function() lights;
  final bool Function() visible;
  double _clock = 0;
  static final _layerPaint = Paint();
  static final _shadePaint = Paint();
  static final _flyPaint = Paint();
  static final _holePaint = Paint()
    ..blendMode = BlendMode.dstOut
    ..shader = Gradient.radial(Offset.zero, 1, const [
      Color(0xFF000000),
      Color(0xCC000000),
      Color(0x00000000),
    ], const [
      0,
      .55,
      1
    ]);

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!visible()) return;
    final area = Offset.zero & Size(game.size.x, game.size.y);
    canvas.saveLayer(area, _layerPaint);
    canvas.drawRect(area, _shadePaint..color = shade);
    for (final (center, radius) in lights()) {
      final r = radius * (1 + math.sin(_clock * 2.4 + center.dx) * .04);
      // One unit-size gradient, scaled per light: no shader per light per frame.
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..scale(r)
        ..drawCircle(Offset.zero, 1, _holePaint)
        ..restore();
    }
    additionalLights?.call(canvas, area.size);
    canvas.restore();
    // Faint fireflies so the dark field does not feel empty.
    for (var i = 0; i < 7; i++) {
      final t = _clock * .4 + i * 1.7;
      final p = Offset(game.size.x * (.1 + .8 * ((i * .37 + (t * .13)) % 1)),
          game.size.y * (.25 + .45 * (.5 + .5 * _wave(t * 1.3 + i))));
      final glow = .4 + .6 * (.5 + .5 * _wave(t * 3 + i * 2));
      canvas.drawCircle(
          p, 5, _flyPaint..color = Color.fromRGBO(255, 236, 140, .18 * glow));
      canvas.drawCircle(
          p, 1.6, _flyPaint..color = Color.fromRGBO(255, 244, 190, .9 * glow));
    }
  }

  static double _wave(double x) => math.sin(x);
}
