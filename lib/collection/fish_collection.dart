import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'fish_species.dart';

/// Permanent catches, never consumed by feeding cats.
class FishCollection {
  FishCollection(this.preferences) : _counts = _load(preferences);
  final SharedPreferences preferences;
  Map<String, int> _counts;
  static const _key = 'fish_collection_species_v1';
  static late FishCollection instance;
  int get count => FishSpecies.values
      .where((fish) => !fish.isJunk && fish != FishSpecies.catMew)
      .fold(0, (total, fish) => total + countOf(fish));
  int get junkCount => FishSpecies.values
      .where((fish) => fish.isJunk)
      .fold(0, (total, fish) => total + countOf(fish));
  int countOf(FishSpecies fish) => _counts[fish.name] ?? 0;

  static Map<String, int> _load(SharedPreferences preferences) {
    final saved = preferences.getString(_key);
    if (saved == null) {
      return {
        FishSpecies.tilapia.name:
            preferences.getInt('fish_collection_count') ?? 0
      };
    }
    final decoded = jsonDecode(saved) as Map<String, dynamic>;
    return decoded.map((key, value) {
      if (value is! int || value < 0) {
        throw const FormatException('Invalid fish count');
      }
      return MapEntry(key, value);
    });
  }

  Future<void> catchFish(FishSpecies fish) async {
    final next = {..._counts, fish.name: countOf(fish) + 1};
    if (!await preferences.setString(_key, jsonEncode(next))) {
      throw StateError('Could not save collection');
    }
    _counts = next;
  }
}
