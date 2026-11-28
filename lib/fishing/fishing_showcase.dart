import 'dart:math' as math;
import '../collection/fish_species.dart';

/// A cosmetic journal record; never grants or consumes inventory.
class FishingShowcase {
  const FishingShowcase(
      {required this.fish,
      required this.grams,
      required this.startedAt,
      this.measured = true});
  static const durationMs = 6000;
  final FishSpecies fish;
  final bool measured;
  final int grams, startedAt;
  bool activeAt(int now) =>
      now >= startedAt - 5000 && now < startedAt + durationMs;

  /// Legends stay imposing even at low weight; heavier records grow within each tier.
  double get width {
    if (FishSpecies.legendary.contains(fish)) {
      final fraction = measured ? fish.weightFraction(grams) : .4;
      return 145 + 85 * math.pow(fraction, 1 / 3).toDouble();
    }
    return (48 + 32 * math.pow(grams / 1000, 1 / 3)).clamp(54, 145).toDouble();
  }

  Map<String, Object> toJson() => {
        'fish': fish.name,
        'grams': grams,
        'startedAt': startedAt,
        'measured': measured
      };
  static FishingShowcase? parse(Object? value, int now) {
    if (value is! Map) return null;
    final fish =
        FishSpecies.values.where((f) => f.name == value['fish']).firstOrNull;
    final grams = value['grams'], started = value['startedAt'];
    if (fish == null ||
        fish.isJunk ||
        grams is! int ||
        started is! int ||
        started < 0 ||
        grams < fish.weightRange.$1 ||
        grams > fish.weightRange.$2) {
      return null;
    }
    final result = FishingShowcase(
        fish: fish,
        grams: grams,
        startedAt: started,
        measured: value['measured'] != false);
    return result.activeAt(now) ? result : null;
  }
}
