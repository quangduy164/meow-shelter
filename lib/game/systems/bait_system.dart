import 'dart:math';
import 'package:flame/components.dart';
import '../components/cat_component.dart';
import '../cats/dish.dart';

class _Bait {
  _Bait(this.point, this.portions, this.refundable, this.dish);
  final Vector2 point;
  final Dish dish;

  /// Yarn rolls after it lands; nobody chases it until it stops.
  final velocity = Vector2.zero();
  double spin = 0;
  bool get rolling => velocity.length2 > 1;
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

  /// Waiting dishes and what they are, for drawing (yarn also its spin).
  Iterable<(Vector2, Dish, double)> get dishesOut sync* {
    for (final bait in _baits) {
      if (bait.eater == null) {
        yield (bait.point, bait.dish, bait.spin);
      } else if (bait.eater!.fishTarget != null) {
        yield (bait.eater!.fishTarget!, bait.dish, bait.spin);
      }
    }
  }

  bool get hasBaitOut => positions.isNotEmpty;
  bool get canPlace => !limited || fishCount > 0;
  bool spend() {
    if (!canPlace) return false;
    if (limited) fishCount--;
    return true;
  }

  void reset({int limit = 0, int portions = 1, double refundAfter = 0}) {
    limited = limit > 0;
    fishCount = limit;
    _portions = portions;
    _refundAfter = refundAfter;
    _baits.clear();
  }

  /// Field size and walls for rolling yarn; set by the game each round.
  Vector2 field = Vector2.zero();
  bool Function(Vector2 point)? blocked;

  void _roll(_Bait bait, double dt) {
    final next = bait.point + bait.velocity * dt;
    const margin = 20.0;
    if (next.x < margin || next.x > field.x - margin) {
      bait.velocity.x = -bait.velocity.x;
    } else if (next.y < field.y * .28 || next.y > field.y - margin) {
      bait.velocity.y = -bait.velocity.y;
    } else if (blocked?.call(next) == true) {
      bait.velocity.scale(-.6);
    } else {
      bait.point.setFrom(next);
    }
    bait.spin += bait.velocity.length * dt / 12;
    // Carpet friction: stops in about a second.
    bait.velocity.scale(max(0, 1 - 2.4 * dt));
    if (!bait.rolling) bait.velocity.setZero();
  }

  void update(Iterable<CatComponent> cats, {double dt = 0}) {
    for (final bait in _baits) {
      if (bait.rolling) _roll(bait, dt);
    }
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
      if (bait.eater != null || bait.rolling) continue;
      final willing = candidates
          .where((cat) => cat.acceptsBait(bait.point, all, bait.dish))
          .toList();
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
      cat.lure(bait.point, bait.dish);
    }
  }

  /// A batted or knocked-over ball of yarn rolling away from [from].
  void kickYarn(Vector2 from, Vector2 velocity) {
    final bait = _Bait(from.clone(), 1, false, Dish.yarn)
      ..velocity.setFrom(velocity);
    _baits.add(bait);
  }

  /// The market cart can take only unclaimed bait, never food a cat is chasing.
  bool takeWaitingNear(Vector2 point, double radius) {
    final match = _baits
        .where((b) => b.eater == null && (b.point - point).length <= radius)
        .firstOrNull;
    return match != null && _baits.remove(match);
  }

  bool place(Vector2 point, Vector2 size, Iterable<CatComponent> cats,
      {bool free = false, Dish dish = Dish.fish, Vector2? roll}) {
    if ((!free && !canPlace) ||
        point.y < size.y * .25 ||
        point.y > size.y - 12 ||
        point.x < 12 ||
        point.x > size.x - 12) {
      return false;
    }
    final added = _Bait(point.clone(), _portions, limited && !free, dish);
    if (roll != null) added.velocity.setFrom(roll);
    _baits.add(added);
    if (limited && !free) fishCount--;
    for (final cat in cats) {
      cat.startleBy(point);
    }
    update(cats);
    return true;
  }
}
