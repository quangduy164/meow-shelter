import 'dart:math' as math;
import 'package:flutter/painting.dart';

class FishingLighting {
  FishingLighting(DateTime time)
      : hour = time.hour + time.minute / 60 + time.second / 3600;
  const FishingLighting.at(this.hour);

  /// Real time for one full in-game day in the fishing world.
  static const dayLength = Duration(minutes: 40);

  /// In-game hour (0..24) for [now]: a 40-minute day that keeps running
  /// while the app is closed, so every visit picks up where the sky is.
  static double gameHour(DateTime now) {
    final cycle = dayLength.inMilliseconds;
    return ((now.millisecondsSinceEpoch + shiftMs) % cycle) / cycle * 24;
  }

  /// Saved jump added to the clock, e.g. after sleeping through the night.
  static int shiftMs = 0;
  static const shiftKey = 'fishing_clock_shift_v1';

  /// Moves the game clock forward to the next [hour] (0..24) and returns
  /// the new shift to save.
  static int skipTo(double hour, DateTime now) {
    final cycle = dayLength.inMilliseconds;
    final ahead = (hour - gameHour(now)) % 24;
    shiftMs = (shiftMs + (ahead / 24 * cycle).round()) % cycle;
    return shiftMs;
  }

  /// "07:30" for an in-game hour.
  static String clock(double hour) {
    final minutes = (hour * 60).floor() % (24 * 60);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(minutes ~/ 60)}:${two(minutes % 60)}';
  }

  /// Vietnamese name for the part of the day.
  static String partOfDay(double hour) => switch (hour) {
        < 5 => 'Đêm khuya',
        < 7 => 'Bình minh',
        < 11 => 'Buổi sáng',
        < 14 => 'Buổi trưa',
        < 17 => 'Buổi chiều',
        < 19 => 'Hoàng hôn',
        < 22 => 'Buổi tối',
        _ => 'Đêm khuya',
      };

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
