import 'dart:ui';

/// Small train station: layout shared by rules and painters, in viewport
/// fractions like every HerdMap.
abstract final class HerdStation {
  /// Rails between the upper and lower platforms. Walkable only inside the
  /// train while its doors are open, or while riding it.
  static const track = Rect.fromLTWH(0, .47, 1, .14);

  /// The ticket hall splits the upper platform into west and east halves.
  static const hall = Rect.fromLTWH(.44, .17, .12, .30);

  static const benches = [
    Rect.fromLTWH(.27, .22, .08, .045),
    Rect.fromLTWH(.30, .70, .08, .045),
    Rect.fromLTWH(.52, .86, .08, .045),
    Rect.fromLTWH(.84, .70, .08, .045),
    Rect.fromLTWH(.76, .20, .08, .045),
  ];

  /// Where Bé Nhát Gan crouches, tucked against each bench.
  static const hideSpots = [
    Offset(.31, .32),
    Offset(.34, .80),
    Offset(.56, .81),
    Offset(.88, .80),
    Offset(.80, .30),
  ];

  static const kiosk = Rect.fromLTWH(.04, .86, .07, .08);
  static const luggage = Rect.fromLTWH(.92, .86, .05, .06);
}

/// One small train, left to right: stops West, then East, then leaves.
abstract final class HerdTrain {
  /// The clock starts mid-cycle so the first west stop comes right after
  /// the opening cluster is gathered (about six seconds in).
  static const period = 14.0, offset = 9.8, length = .30;
  static const westX = .22, eastX = .78;

  // (time, centre x) keyframes; holds are the open-door stops.
  static const _keys = [
    (0.0, -.25),
    (1.8, westX),
    (5.8, westX),
    (7.8, eastX),
    (11.8, eastX),
    (13.6, 1.25),
    (14.0, 1.25),
  ];

  static double phase(double t) => (t + offset) % period;

  static double centerX(double t) {
    final p = phase(t);
    for (var i = 1; i < _keys.length; i++) {
      final (t1, x1) = _keys[i];
      final (t0, x0) = _keys[i - 1];
      if (p <= t1) {
        final k = ((p - t0) / (t1 - t0)).clamp(0.0, 1.0);
        final s = k * k * (3 - 2 * k);
        return x0 + (x1 - x0) * s;
      }
    }
    return _keys.last.$2;
  }

  /// 0 at the west stop, 1 at the east stop, null while moving.
  static int? stop(double t) {
    final p = phase(t);
    if (p >= 1.8 && p < 5.8) return 0;
    if (p >= 7.8 && p < 11.8) return 1;
    return null;
  }

  static bool open(double t) => stop(t) != null;

  /// Seconds the doors stay open before closing, for the countdown light.
  static double closingIn(double t) {
    final p = phase(t);
    if (p >= 1.8 && p < 5.8) return 5.8 - p;
    if (p >= 7.8 && p < 11.8) return 11.8 - p;
    return 0;
  }

  /// Horn just before each arrival: id per blast, or null.
  static int? horn(double t) {
    final p = phase(t);
    final cycle = ((t + offset) / period).floor();
    if (p >= .5 && p < .9) return cycle * 2;
    if (p >= 6.8 && p < 7.2) return cycle * 2 + 1;
    return null;
  }

  /// The whole train in fractions; height is the track band.
  static Rect rect(double t, Rect track) => Rect.fromCenter(
      center: Offset(centerX(t), track.center.dy),
      width: length,
      height: track.height);
}

abstract final class HerdShy {
  /// Horn heard within this fraction of the field width; coaxing time, the
  /// dash to cover, and how long a coaxed cat stays brave.
  static const hearing = .3, coaxSeconds = 1.2, runSpeed = 165.0;
  static const calmSeconds = 12.0;
}
