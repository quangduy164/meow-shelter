/// Desert-only timing and tuning: sun heat and periodic sandstorms.
abstract final class HerdHeat {
  /// A follower in the sun overheats in about seven seconds; cats further
  /// back heat a little faster, so long herds need more shade stops.
  static const sunRate = 1 / 7, tailBonus = .04, coolRate = .45;
  static const faintSeconds = 3.0;
}

abstract final class HerdSandstorm {
  static const period = 16.0, warningSeconds = 2.0, blowSeconds = 4.5;
  static const offset = 6.0, windSpeed = 70.0, shelterReach = 70.0;

  static double _cycle(double t) => (t + offset) % period;
  static bool blowing(double t) => _cycle(t) < blowSeconds;
  static bool warning(double t) => _cycle(t) >= period - warningSeconds;

  /// Storm number used to announce each storm once.
  static int number(double t) =>
      ((t + offset + warningSeconds) / period).floor();

  /// +1 blows to the right, -1 to the left; alternates every storm.
  static double direction(double t) => number(t).isEven ? 1 : -1;
}
