import 'dart:math' as math;
import 'dart:ui';

/// A fenced pen whose gate opens while its plate is pressed.
class HerdPen {
  const HerdPen(this.area, this.gate, this.plate, {this.heavy = false});

  /// Inside of the pen, the gate gap in its fence, and the plate centre.
  final Rect area, gate;
  final Offset plate;

  /// Heavy plates only go down under Bé Mập.
  final bool heavy;
}

/// A goose walking back and forth on a line; three walk in a row.
class HerdGoose {
  const HerdGoose(this.from, this.to, {this.period = 7.0});
  final Offset from, to;
  final double period;

  static const flock = 3, gap = .45, radius = 24.0;

  /// Position of goose [k] in the flock, in fractions.
  Offset at(double t, int k) {
    final s = .5 - .5 * math.cos(2 * math.pi * (t - k * gap) / period);
    return from + (to - from) * s;
  }

  bool facingLeft(double t, int k) =>
      math.sin(2 * math.pi * (t - k * gap) / period) * (to.dx - from.dx) < 0;
}

abstract final class HerdPlate {
  /// Pixel radius of a plate; a plate rests after its sitter leaves so the
  /// rest of the herd can walk past without another cat sitting down.
  static const radius = 16.0, restSeconds = 5.0, rejoinCooldown = 0.0;
}

abstract final class HerdSulk {
  /// A sulking cat backs away from the leader and is coaxed by staying close.
  static const walkSpeed = 62.0, avoidRange = 80.0, coaxRange = 36.0;
  static const coaxSeconds = 1.0;
}

/// Uncle Ba's farm layout, in viewport fractions.
abstract final class HerdFarm {
  static const sheepPen = HerdPen(Rect.fromLTWH(.16, .17, .20, .28),
      Rect.fromLTWH(.22, .45, .08, .025), Offset(.06, .42));
  static const coop = HerdPen(Rect.fromLTWH(.46, .685, .18, .315),
      Rect.fromLTWH(.51, .66, .08, .025), Offset(.37, .74),
      heavy: true);

  static const fences = [
    // Sheep pen.
    Rect.fromLTWH(.14, .17, .02, .305),
    Rect.fromLTWH(.36, .17, .02, .305),
    Rect.fromLTWH(.14, .45, .08, .025),
    Rect.fromLTWH(.30, .45, .08, .025),
    // Chicken coop.
    Rect.fromLTWH(.44, .66, .02, .34),
    Rect.fromLTWH(.64, .66, .02, .34),
    Rect.fromLTWH(.44, .66, .07, .025),
    Rect.fromLTWH(.59, .66, .08, .025),
  ];

  static const hay = Rect.fromLTWH(.46, .22, .07, .07);
  static const trough = Rect.fromLTWH(.57, .24, .08, .04);
  static const well = Rect.fromLTWH(.03, .88, .05, .07);

  static const geese = HerdGoose(Offset(.72, .47), Offset(.96, .47));
}
