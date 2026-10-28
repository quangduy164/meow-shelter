import 'dart:math' as math;
import 'package:flutter/painting.dart';

class FishingLighting {
  FishingLighting(DateTime time)
      : hour = time.hour + time.minute / 60 + time.second / 3600;

  final double hour;

  static double _smooth(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  double get daylight =>
      _smooth((hour - 5) / 2) * (1 - _smooth((hour - 17) / 2));
  double get warmth => math.max((1 - (hour - 6).abs() / 1.5).clamp(0.0, 1.0),
      (1 - (hour - 18).abs() / 1.5).clamp(0.0, 1.0));
  double get night => 1 - daylight;
  bool get moonVisible => hour < 6 || hour >= 18;

  Offset get celestialPosition {
    final progress = moonVisible
        ? ((hour >= 18 ? hour - 18 : hour + 6) / 12).clamp(0.0, 1.0)
        : ((hour - 6) / 12).clamp(0.0, 1.0);
    return Offset(
        .14 + progress * .72, .43 - math.sin(progress * math.pi) * .34);
  }

  Color get skyTop => Color.lerp(
      Color.lerp(const Color(0xFF142932), const Color(0xFF8BD5ED), daylight),
      const Color(0xFF8A849F),
      warmth * .55)!;
  Color get skyBottom => Color.lerp(
      Color.lerp(const Color(0xFF536374), const Color(0xFFE8F2D5), daylight),
      const Color(0xFFF4AC7C),
      warmth * .85)!;
  Color get reflection => moonVisible
      ? const Color(0xFFCEE8E4)
      : Color.lerp(const Color(0xFFFFF3C4), const Color(0xFFFFBF83), warmth)!;

  ColorFilter get terrainFilter {
    final brightness = .40 + daylight * .60;
    return ColorFilter.matrix([
      brightness,
      0,
      0,
      0,
      night * 7 + warmth * 18,
      0,
      brightness,
      0,
      0,
      night * 15 + warmth * 5,
      0,
      0,
      brightness,
      0,
      night * 25,
      0,
      0,
      0,
      1,
      0,
    ]);
  }
}
