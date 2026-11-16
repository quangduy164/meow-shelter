import 'package:flame/components.dart';
import '../components/cat_component.dart';

class _Bait {
  _Bait(this.point, this.portions, this.refundable);
  final Vector2 point;
  int portions;
  final bool refundable;
  double age = 0;
  bool used = false;
  CatComponent? eater;
}

/// One bait may have several portions, consumed in sequence at the same spot.
class BaitSystem {
  int fishCount = 0;
  final _baits = <_Bait>[];
  int _portions = 1;
  double _refundAfter = 0;
  bool limited = false;

  Iterable<Vector2> get positions sync* {
    for (final bait in _baits) {
      if (bait.eater == null) {
        yield bait.point;
      } else if (bait.eater!.fishTarget != null) {
        yield bait.eater!.fishTarget!;
      }
    }
  }

  bool get hasBaitOut => positions.isNotEmpty;
  bool get canPlace => !limited || fishCount > 0;

  void reset({int limit = 0, int portions = 1, double refundAfter = 0}) {
    limited = limit > 0;
    fishCount = limit;
    _portions = portions;
    _refundAfter = refundAfter;
    _baits.clear();
  }

  void update(Iterable<CatComponent> cats, {double dt = 0}) {
    _baits.removeWhere((bait) =>
        bait.eater != null &&
        bait.eater!.fishTarget == null &&
        bait.portions <= 0);
    for (final bait in _baits) {
      if (bait.eater != null && bait.eater!.fishTarget == null) {
        bait.eater = null;
        bait.age = 0;
      }
    }
    final all = cats.toList();
    final candidates = all.where((cat) => cat.canLure).toList();
    for (final bait in List<_Bait>.of(_baits)) {
      if (bait.eater != null) continue;
      final willing =
          candidates.where((cat) => cat.acceptsBait(bait.point, all)).toList();
      if (willing.isEmpty) {
        bait.age += dt;
        if (_refundAfter > 0 && !bait.used && bait.age >= _refundAfter) {
          if (bait.refundable) fishCount++;
          _baits.remove(bait);
        }
        continue;
      }
      willing.sort((a, b) => (a.center - bait.point)
          .length2
          .compareTo((b.center - bait.point).length2));
      final cat = willing.first;
      candidates.remove(cat);
      bait.eater = cat;
      bait.used = true;
      bait.portions--;
      cat.lure(bait.point);
    }
  }

  /// The market cart can take only unclaimed bait, never food a cat is chasing.
  bool takeWaitingNear(Vector2 point, double radius) {
    final match = _baits
        .where((b) => b.eater == null && (b.point - point).length <= radius)
        .firstOrNull;
    return match != null && _baits.remove(match);
  }

  bool place(Vector2 point, Vector2 size, Iterable<CatComponent> cats,
      {bool free = false}) {
    if ((!free && !canPlace) ||
        point.y < size.y * .25 ||
        point.y > size.y - 12 ||
        point.x < 12 ||
        point.x > size.x - 12) {
      return false;
    }
    _baits.add(_Bait(point.clone(), _portions, limited && !free));
    if (limited && !free) fishCount--;
    for (final cat in cats) {
      cat.startleBy(point);
    }
    update(cats);
    return true;
  }
}
