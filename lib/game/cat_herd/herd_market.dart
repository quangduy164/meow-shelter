import 'dart:math' as math;
import 'dart:ui';

/// Market vendor: watches a sweeping cone, then turns away to rest.
class HerdVendor {
  const HerdVendor(this.at, this.facing, this.sweep, this.phase);
  final Offset at;
  final double facing, sweep, phase;
  static const period = 9.0, watchSeconds = 4.5, warningSeconds = .8;
  static const halfAngle = .5;

  double _cycle(double t) => (t + phase) % period;
  bool watching(double t) => _cycle(t) < watchSeconds;
  bool warning(double t) => _cycle(t) >= period - warningSeconds;
  double angle(double t) => facing + math.sin(t * .9 + phase) * sweep;
}

/// Lantern zones turn off in turn; vendors cannot see cats in the dark.
abstract final class HerdLanterns {
  static const period = 12.0, onSeconds = 7.0, flickerSeconds = 1.0;
  static double _cycle(int zone, double t) => (t + zone * 4) % period;
  static bool lit(int zone, double t) => _cycle(zone, t) < onSeconds;
  static bool flickering(int zone, double t) {
    final c = _cycle(zone, t);
    return c >= onSeconds - flickerSeconds && c < onSeconds;
  }
}
