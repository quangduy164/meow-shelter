import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fishing_lighting.dart';
import 'fishing_weather.dart';

/// A world's time offset and the end of its introductory sunny period.
/// Once initialized, wall-clock time advances even while the app is closed.
class FishingEnvironment {
  const FishingEnvironment({required this.shiftMs, required this.sunnyUntil});
  final int shiftMs, sunnyUntil;
  static const key = 'fishing_environment_v1';
  static const sunnyKey = 'fishing_sunny_until_v1';

  static Future<void> initialize(SharedPreferences prefs, DateTime now,
      {required bool firstTrip}) async {
    if (prefs.getBool(key) == true) {
      FishingLighting.shiftMs = prefs.getInt(FishingLighting.shiftKey) ?? 0;
      return;
    }
    final cycle = FishingLighting.dayLength.inMilliseconds;
    final fresh = firstTrip && !prefs.containsKey(FishingLighting.shiftKey);
    FishingLighting.shiftMs = fresh
        ? ((cycle ~/ 3) - now.millisecondsSinceEpoch) % cycle
        : prefs.getInt(FishingLighting.shiftKey) ?? 0;
    try {
      final shiftSaved =
          await prefs.setInt(FishingLighting.shiftKey, FishingLighting.shiftMs);
      final sunSaved = await prefs.setInt(
          sunnyKey,
          fresh
              ? now.add(const Duration(minutes: 5)).millisecondsSinceEpoch
              : 0);
      if (shiftSaved && sunSaved) {
        if (!await prefs.setBool(key, true)) {
          debugPrint('FishingEnvironment: could not save marker');
        }
      } else {
        debugPrint('FishingEnvironment: could not save initial time');
      }
    } catch (e) {
      debugPrint('FishingEnvironment: could not initialize ($e)');
    }
  }

  static FishingEnvironment local(SharedPreferences prefs) =>
      FishingEnvironment(
          shiftMs: FishingLighting.shiftMs,
          sunnyUntil: prefs.getInt(sunnyKey) ?? 0);

  FishingEnvironment toServer(int offset) => FishingEnvironment(
      shiftMs: (shiftMs - offset) % FishingLighting.dayLength.inMilliseconds,
      sunnyUntil: sunnyUntil == 0 ? 0 : sunnyUntil + offset);

  double hourAt(DateTime now) =>
      ((now.millisecondsSinceEpoch + shiftMs) %
          FishingLighting.dayLength.inMilliseconds) /
      FishingLighting.dayLength.inMilliseconds *
      24;
  FishingWeather weatherAt(DateTime now) =>
      now.millisecondsSinceEpoch < sunnyUntil
          ? FishingWeather.clear
          : FishingWeather.at(now);

  Map<String, Object> toJson() =>
      {'shiftMs': shiftMs, 'sunnyUntil': sunnyUntil};
  static FishingEnvironment? parse(Object? value) {
    if (value is! Map) return null;
    final shift = value['shiftMs'], sunny = value['sunnyUntil'];
    if (shift is! int ||
        shift < 0 ||
        shift >= FishingLighting.dayLength.inMilliseconds ||
        sunny is! int ||
        sunny < 0 ||
        sunny > 8640000000000000) {
      return null;
    }
    return FishingEnvironment(shiftMs: shift, sunnyUntil: sunny);
  }
}
