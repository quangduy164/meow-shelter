import 'package:flame/components.dart';
import '../components/cat_component.dart';

/// Reusable bait. Unclaimed fish wait until a cat becomes available.
class BaitSystem {
  int fishCount = 0;
  final List<Vector2> _waiting = [];
  final Set<CatComponent> _attracted = {};
  Iterable<Vector2> get positions sync* {
    yield* _waiting;
    for (final cat in _attracted) {
      if (cat.fishTarget != null) yield cat.fishTarget!;
    }
  }

  bool get canPlace => fishCount > 0;
  void reset({int ownedFish = 0}) {
    fishCount = ownedFish;
    _waiting.clear();
    _attracted.clear();
  }

  void update(Iterable<CatComponent> cats) {
    _attracted.removeWhere((cat) => cat.fishTarget == null);
    final candidates = cats.where((cat) => cat.canLure).toList();
    while (_waiting.isNotEmpty && candidates.isNotEmpty) {
      final point = _waiting.removeAt(0);
      candidates.sort((a, b) => (a.position + a.size / 2 - point)
          .length2
          .compareTo((b.position + b.size / 2 - point).length2));
      final cat = candidates.removeAt(0);
      cat.lure(point);
      _attracted.add(cat);
    }
  }

  bool place(Vector2 point, Vector2 size, Iterable<CatComponent> cats) {
    if (!canPlace ||
        point.y < size.y * .25 ||
        point.y > size.y - 12 ||
        point.x < 12 ||
        point.x > size.x - 12) return false;
    _waiting.add(point.clone());
    update(cats);
    return true;
  }
}
