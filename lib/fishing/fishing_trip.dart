import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fishing_river.dart';

/// Last fishing trip: chosen cat, boat spot and explored minimap cells.
/// A cat that was ashore resumes in its parked boat.
class FishingTrip {
  static const key = 'fishing_trip_v1';

  static Map<String, dynamic>? _read(SharedPreferences preferences) {
    final saved = preferences.getString(key);
    if (saved == null) return null;
    try {
      return jsonDecode(saved) as Map<String, dynamic>;
    } catch (error) {
      debugPrint('FishingTrip: unreadable save, starting fresh ($error)');
      return null;
    }
  }

  static String? lastCat(SharedPreferences preferences) =>
      _read(preferences)?['cat'] as String?;

  static void restore(SharedPreferences preferences, FishingRiverRound round) {
    final data = _read(preferences);
    if (data == null) return;
    final x = data['x'], y = data['y'], map = data['map'];
    final heading = data['h'];
    round.restore(
      boat: x is num && y is num ? Offset(x.toDouble(), y.toDouble()) : null,
      heading: heading is num ? heading.toDouble() : null,
      explored: map is String ? [for (final c in map.codeUnits) c == 49] : null,
    );
  }

  static Future<void> save(SharedPreferences preferences,
      FishingRiverRound round, String cat) async {
    round.mapChanged = false;
    final ok = await preferences.setString(
        key,
        jsonEncode({
          'cat': cat,
          'x': round.boat.dx.roundToDouble(),
          'y': round.boat.dy.roundToDouble(),
          'h': round.heading.direction,
          'map': String.fromCharCodes(
              [for (final seen in round.explored) seen ? 49 : 48]),
        }));
    if (!ok) round.mapChanged = true;
  }
}
