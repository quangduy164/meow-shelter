import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meow_shelter/collection/fish_collection.dart';
import 'package:meow_shelter/game/systems/bait_system.dart';
import 'package:meow_shelter/game/components/cat_component.dart';
import 'package:flame/components.dart';

class HungryCat extends CatComponent {
  HungryCat()
      : super(
            position: Vector2(200, 200),
            catType: 'orange',
            onDrop: (_) => true,
            onDelivered: (_) {},
            onEscaped: (_) {},
            isPlaying: () => true);
  @override
  bool get canLure => fishTarget == null;
  @override
  void lure(Vector2 target) {
    fishTarget = target.clone();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Catches persist and feeding/restarting never consumes the collection',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final collection = FishCollection(prefs);
    await collection.catchFish();
    await collection.catchFish();
    expect(FishCollection(prefs).count, 2);
    final bait = BaitSystem()..reset(ownedFish: collection.count);
    final cat = HungryCat();
    expect(bait.place(Vector2(300, 200), Vector2(800, 400), [cat]), isTrue);
    expect(bait.fishCount, 2);
    expect(collection.count, 2);
    expect(bait.canPlace, isTrue);
    expect(bait.place(Vector2(400, 200), Vector2(800, 400), [cat]), isTrue);
    expect(bait.positions.length, 2);
    cat.fishTarget = null;
    bait.update([cat]);
    expect(cat.fishTarget, Vector2(400, 200));
    expect(bait.canPlace, isTrue);
    bait.reset(ownedFish: collection.count);
    expect(bait.fishCount, 2);
  });
}
