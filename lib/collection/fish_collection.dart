import 'package:shared_preferences/shared_preferences.dart';

/// Permanent catches, never consumed by feeding cats.
class FishCollection {
  FishCollection(this.preferences);
  final SharedPreferences preferences;
  static late FishCollection instance;
  int get count => preferences.getInt('fish_collection_count') ?? 0;
  Future<void> catchFish() async {
    if (!await preferences.setInt('fish_collection_count', count + 1)) {
      throw StateError('Could not save collection');
    }
  }
}
