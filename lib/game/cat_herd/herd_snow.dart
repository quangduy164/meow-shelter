import 'dart:ui';
import 'package:flame/components.dart';

/// Snow-only tuning: thin ice that cracks under a crowd, and one-way chutes.
abstract final class HerdThinIce {
  /// Up to [safeLoad] followers may stand on one sheet. Each extra follower
  /// adds [crackRate] per second; a light sheet refreezes at [healRate].
  static const safeLoad = 2, crackRate = .35, healRate = .5;
  static const warnAt = .55, chillSeconds = 3.0, splashSeconds = 1.6;
}

/// Ripple left where a cat fell through, drawn for [HerdThinIce.splashSeconds].
class HerdSplash {
  HerdSplash(this.at);
  final Vector2 at;
  double age = 0;
}

/// A slick lane: anything inside slides along [direction] at [speed] and
/// cannot steer until it leaves the lane. Entering against it pushes you out.
class HerdChute {
  const HerdChute(this.area, this.direction);
  final Rect area;
  final Offset direction;
  static const speed = 230.0;
}
