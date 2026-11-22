import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'fish_species.dart';

/// Permanent catch counts for the journal, plus the basket of fish that can
/// still be fed to camp cats. Feeding empties the basket, never the journal.
class FishCollection {
  FishCollection(this.preferences) {
    final journal = _loadJournal(preferences);
    _counts = journal.$1;
    _heaviest = journal.$2;
    _basket = _loadBasket(preferences, _counts);
  }
  final SharedPreferences preferences;
  late Map<String, int> _counts;
  late Map<String, int> _heaviest;
  static const _journalKey = 'fish_collection_journal_v2';

  int? heaviestGrams(FishSpecies fish) => _heaviest[fish.name];
  late Map<String, int> _basket;
  static const _key = 'fish_collection_species_v1';
  static const _basketKey = 'fish_basket_v1';

  /// Fish waiting in the basket (lost items never go in).
  int stockOf(FishSpecies fish) => _basket[fish.name] ?? 0;

  /// Edible species with at least one fish in the basket, in journal order.
  List<FishSpecies> get basket => [
        for (final fish in FishSpecies.values)
          if (!fish.isJunk && stockOf(fish) > 0) fish
      ];

  static Map<String, int> _loadBasket(
      SharedPreferences preferences, Map<String, int> counts) {
    final saved = preferences.getString(_basketKey);
    if (saved == null) {
      // Saves from before the basket: everything caught so far is in it.
      return {
        for (final fish in FishSpecies.values)
          if (!fish.isJunk && (counts[fish.name] ?? 0) > 0)
            fish.name: counts[fish.name]!
      };
    }
    try {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          if (e.value is int && (e.value as int) > 0) e.key: e.value as int
      };
    } catch (error) {
      debugPrint('FishCollection: unreadable basket, starting empty ($error)');
      preferences.setString('${_basketKey}_broken', saved);
      return {};
    }
  }

  /// Takes one fish out of the basket for a cat; false if none is left or
  /// the save failed (the fish stays in the basket then).
  Future<bool> takeOne(FishSpecies fish) async {
    final left = stockOf(fish);
    if (fish.isJunk || left <= 0) return false;
    final next = {..._basket, fish.name: left - 1}
      ..removeWhere((_, n) => n <= 0);
    if (!await preferences.setString(_basketKey, jsonEncode(next))) {
      return false;
    }
    _basket = next;
    return true;
  }

  /// Gifts (not catches): fish go into the basket without touching the
  /// journal. False if the save failed; nothing changes then.
  Future<bool> addToBasket(List<FishSpecies> fish) async {
    final next = {..._basket};
    for (final f in fish) {
      if (!f.isJunk) next[f.name] = (next[f.name] ?? 0) + 1;
    }
    if (!await preferences.setString(_basketKey, jsonEncode(next))) {
      return false;
    }
    _basket = next;
    return true;
  }

  static late FishCollection instance;
  int get count => FishSpecies.values
      .where((fish) => !fish.isJunk && fish != FishSpecies.catMew)
      .fold(0, (total, fish) => total + countOf(fish));
  int get junkCount => FishSpecies.values
      .where((fish) => fish.isJunk)
      .fold(0, (total, fish) => total + countOf(fish));
  int countOf(FishSpecies fish) => _counts[fish.name] ?? 0;

  static (Map<String, int>, Map<String, int>) _loadJournal(
      SharedPreferences preferences) {
    final saved = preferences.getString(_journalKey);
    if (saved == null) return (_loadLegacy(preferences), {});
    try {
      final data = jsonDecode(saved) as Map<String, dynamic>;
      final counts = Map<String, int>.from(data['counts'] as Map);
      if (counts.values.any((n) => n < 0)) {
        throw const FormatException('Invalid count');
      }
      final heaviest = <String, int>{};
      try {
        final records = Map<String, int>.from(data['heaviestGrams'] as Map);
        for (final entry in records.entries) {
          final fish =
              FishSpecies.values.where((fish) => fish.name == entry.key).first;
          final range = fish.weightRange;
          if (fish.isJunk || entry.value < range.$1 || entry.value > range.$2) {
            throw const FormatException('Invalid record weight');
          }
        }
        heaviest.addAll(records);
      } catch (error) {
        // A bad weight must not reset the player's valid catch counts.
        debugPrint('FishCollection: unreadable weight records ($error)');
        preferences.setString('${_journalKey}_broken', saved);
      }
      return (counts, heaviest);
    } catch (error) {
      debugPrint('FishCollection: unreadable journal ($error)');
      preferences.setString('${_journalKey}_broken', saved);
      return (_loadLegacy(preferences), {});
    }
  }

  static Map<String, int> _loadLegacy(SharedPreferences preferences) {
    final saved = preferences.getString(_key);
    if (saved == null) {
      return {
        FishSpecies.tilapia.name:
            preferences.getInt('fish_collection_count') ?? 0
      };
    }
    try {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      return decoded.map((key, value) {
        if (value is! int || value < 0) {
          throw const FormatException('Invalid fish count');
        }
        return MapEntry(key, value);
      });
    } catch (error) {
      // Never block app start on a broken save; keep a copy and start empty.
      debugPrint('FishCollection: unreadable save, starting fresh ($error)');
      preferences.setString('${_key}_broken', saved);
      return {};
    }
  }

  /// True only for a heavier catch (or the first measured catch of a species).
  Future<bool> catchFish(FishSpecies fish, {int? grams}) async {
    if (grams != null &&
        (fish.isJunk ||
            grams < fish.weightRange.$1 ||
            grams > fish.weightRange.$2)) {
      throw ArgumentError.value(
          grams, 'grams', 'Outside the species weight range');
    }
    final record = grams != null && grams > (heaviestGrams(fish) ?? 0);
    final heaviest = {..._heaviest, if (record) fish.name: grams};
    final next = {..._counts, fish.name: countOf(fish) + 1};
    // Count and record commit together; a failed save can be retried safely.
    if (!await preferences.setString(
        _journalKey,
        jsonEncode({
          'counts': next,
          'heaviestGrams': heaviest,
        }))) {
      throw StateError('Could not save collection');
    }
    _counts = next;
    _heaviest = heaviest;
    if (fish.isJunk) return false;
    final basket = {..._basket, fish.name: stockOf(fish) + 1};
    // The journal already counts it; a failed basket write only loses the
    // snack, so it is logged instead of failing the catch.
    if (await preferences.setString(_basketKey, jsonEncode(basket))) {
      _basket = basket;
    } else {
      debugPrint('FishCollection: basket save was rejected');
    }
    return record;
  }
}
