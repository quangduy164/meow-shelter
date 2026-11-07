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

  /// Whether [fishCount] runs down as fish are placed (fish-limit levels).
  /// Otherwise bait is unlimited.
  bool limited = false;

  /// Fish lying on the ground that no cat has claimed or is walking to.
  bool get hasBaitOut => positions.isNotEmpty;

  bool get canPlace => !limited || fishCount > 0;
  void reset({int limit = 0}) {
    limited = limit > 0;
    fishCount = limit;
    _waiting.clear();
    _attracted.clear();
  }

  void update(Iterable<CatComponent> cats) {
    _attracted.removeWhere((cat) => cat.fishTarget == null);
    final all = cats.toList();
    final candidates = all.where((cat) => cat.canLure).toList();
    for (final point in List<Vector2>.of(_waiting)) {
      final willing =
          candidates.where((cat) => cat.acceptsBait(point, all)).toList();
      if (willing.isEmpty) continue;
      _waiting.remove(point);
      willing.sort((a, b) => (a.position + a.size / 2 - point)
          .length2
          .compareTo((b.position + b.size / 2 - point).length2));
      final cat = willing.first;
      candidates.remove(cat);
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
    if (limited) fishCount -= 1;
    for (final cat in cats) {
      cat.startleBy(point);
    }
    update(cats);
    return true;
  }
}
