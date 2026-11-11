import 'package:flame/components.dart';

/// A warned snowball pass, followed by a long safe gap.
class HerdSnowball {
  HerdSnowball(this.from, this.to, this.delay);
  final Vector2 from, to;
  final double delay;
  static const period = 14.0, warningSeconds = 1.5, rollingSeconds = 4.0;
  double phase(double time) => (time - delay) % period;
  bool warning(double time) => phase(time) < warningSeconds;
  bool active(double time) =>
      phase(time) >= warningSeconds &&
      phase(time) < warningSeconds + rollingSeconds;
  Vector2 position(double time) =>
      from +
      (to - from) *
          ((phase(time) - warningSeconds) / rollingSeconds).clamp(0.0, 1.0);
  Vector2 warningPosition(double time) =>
      from -
      (to - from).normalized() * (50 * (1 - phase(time) / warningSeconds));
  double distanceToPath(Vector2 at) {
    final delta = to - from;
    final t = ((at - from).dot(delta) / delta.length2).clamp(0.0, 1.0);
    return at.distanceTo(from + delta * t);
  }
}
