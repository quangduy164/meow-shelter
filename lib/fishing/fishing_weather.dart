import 'dart:math' as math;
import '../collection/fish_species.dart';

enum WeatherKind { sunny, cloudy, rain, fog }

/// Weather follows the real clock in 5-minute slots, so everyone sees the
/// same sky and nothing needs saving. Mostly sunny; now and then one slot
/// of cloud, rain or fog. Each slot eases in over 30 seconds.
class FishingWeather {
  const FishingWeather(this.kind, this.cloud, this.rain, this.fog);
  static const clear = FishingWeather(WeatherKind.sunny, 0, 0, 0);
  static const slotMinutes = 5;

  final WeatherKind kind;

  /// 0..1 strengths, blended across slot changes.
  final double cloud, rain, fog;

  static WeatherKind kindForSlot(int slot) {
    final v = math.sin(slot * 12.9898 + 4.1) * 43758.5453;
    final r = v - v.floorToDouble();
    return r < .8
        ? WeatherKind.sunny
        : r < .88
            ? WeatherKind.cloudy
            : r < .95
                ? WeatherKind.rain
                : WeatherKind.fog;
  }

  static (double, double, double) _levels(WeatherKind k) => switch (k) {
        WeatherKind.sunny => (0, 0, 0),
        WeatherKind.cloudy => (.8, 0, 0),
        WeatherKind.rain => (1, 1, 0),
        WeatherKind.fog => (.3, 0, 1),
      };

  static FishingWeather at(DateTime now) {
    final minutes = now.millisecondsSinceEpoch / 60000;
    final slot = (minutes / slotMinutes).floor();
    final seconds = (minutes - slot * slotMinutes) * 60;
    final t = (seconds / 30).clamp(0.0, 1.0);
    final s = t * t * (3 - 2 * t);
    final a = _levels(kindForSlot(slot - 1)), b = _levels(kindForSlot(slot));
    double mix(double x, double y) => x + (y - x) * s;
    return FishingWeather(
        kindForSlot(slot), mix(a.$1, b.$1), mix(a.$2, b.$2), mix(a.$3, b.$3));
  }

  /// Catch weight multiplier for [fish] in this weather.
  double boost(FishSpecies fish) => switch (fish) {
        FishSpecies.catfish ||
        FishSpecies.carp ||
        FishSpecies.goby ||
        FishSpecies.mudskipper ||
        FishSpecies.grouper =>
          1 + rain * .5,
        FishSpecies.koi ||
        FishSpecies.cavefish ||
        FishSpecies.lanternfish =>
          1 + fog * .6,
        _ => 1,
      };
}
