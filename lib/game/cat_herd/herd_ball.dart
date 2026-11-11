import 'dart:math' as math;
import 'package:flame/components.dart';

/// Bouncing toy ball. Contact is on the ground footprint, independent of art.
class HerdBall {
  HerdBall(this.from, this.to, this.phase);
  final Vector2 from, to;
  final double phase;
  Vector2 position(double time) =>
      from + (to - from) * (.5 + .5 * math.sin(time * 1.4 + phase));
  double height(double time) => math.sin(time * 5 + phase).abs() * 18;
}
