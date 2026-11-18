import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../components/cat_component.dart';
import '../world/shelter_map.dart';

class _Hider {
  _Hider(this.cat, this.bush);
  final CatComponent cat;
  int bush;
  bool hidden = true, running = false;
  double quiet = 0, rustle = 0;

  /// The boss's next bush while it sneaks across the open lawn.
  int? travelTo;
}

/// Chapter 2 garden: Himalaya cats hide in bushes and only come out after a
/// few quiet seconds. Fish dropped near a bush, a carried cat passing by or a
/// startled cat counts as noise. The boss hops from bush to bush.
class BushSystem {
  BushSystem(this.map, {this.onRetreat});
  final ShelterMap map;

  /// Called when noise sends a visible Himalaya back into a bush.
  final void Function()? onRetreat;
  final _hiders = <_Hider>[];
  final _random = Random();
  Vector2 _size = Vector2.zero();
  double _clock = 0;

  /// Seconds of quiet a hiding cat needs; noise reach for each source.
  static const quietSeconds = 3.0, bossQuietSeconds = 4.0;
  static const fishNoise = 150.0, carryNoise = 110.0, startleNoise = 150.0;
  static const runSpeed = 230.0, sneakSpeed = 70.0;

  List<Vector2> get _centers =>
      [for (final b in map.bushes) Vector2(b.dx * _size.x, b.dy * _size.y)];

  double _radius() => map.bushRadius * _size.x;

  Vector2 _hideSpot(int bush, CatComponent cat) =>
      _centers[bush] - cat.size / 2 + Vector2(0, -6);

  void update(double dt, Vector2 size, Iterable<CatComponent> cats) {
    _size = size;
    _clock += dt;
    _hiders.removeWhere((h) => !h.cat.isMounted || h.cat.isDelivered);
    for (final cat in cats) {
      if (cat.catType != 'himalaya' ||
          !cat.isLoaded ||
          cat.isDelivered ||
          _hiders.any((h) => h.cat == cat)) {
        continue;
      }
      final hider = _Hider(cat, _freeBush(cat.center));
      _hiders.add(hider);
      cat.hideInCover(_hideSpot(hider.bush, cat));
    }
    for (final cat in cats) {
      if (cat.isCarried) noise(cat.center, carryNoise);
    }
    final centers = _centers;
    for (final h in _hiders) {
      final cat = h.cat;
      h.rustle = max(0, h.rustle - dt);
      if (h.running) {
        if (_walk(cat, centers[h.bush], runSpeed, dt)) {
          h.running = false;
          cat.ignoresBait = false;
          _hide(h);
        }
      } else if (h.hidden) {
        h.quiet += dt;
        if (h.quiet >= (cat.isBoss ? bossQuietSeconds : quietSeconds)) {
          _emerge(h, centers);
        }
      } else if (cat.isBoss) {
        _sneak(h, centers, dt);
      }
    }
  }

  /// The boss keeps sneaking to another bush until fish stops it.
  void _sneak(_Hider h, List<Vector2> centers, double dt) {
    final cat = h.cat;
    final busy = cat.fishTarget != null ||
        cat.hasEaten ||
        cat.catchWindow.canCatch ||
        cat.isCarried;
    if (busy) {
      if (cat.trapManaged) cat.trapManaged = false;
      h.travelTo = null;
      return;
    }
    h.travelTo ??= _otherBush(h.bush);
    final target = h.travelTo!;
    if (_walk(cat, centers[target], sneakSpeed, dt)) {
      h.bush = target;
      h.travelTo = null;
      _hide(h);
    }
  }

  /// Moves [cat] under system control; true once it reaches [to].
  bool _walk(CatComponent cat, Vector2 to, double speed, double dt) {
    if (!cat.trapManaged) cat.enterTrap();
    final goal = to - cat.size / 2 + Vector2(0, -6);
    final delta = goal - cat.position;
    if (delta.length <= speed * dt + 1) {
      cat.positionInTrap(goal, walking: false);
      return true;
    }
    cat.positionInTrap(cat.position + delta.normalized() * speed * dt,
        walking: true);
    return false;
  }

  void _hide(_Hider h) {
    h.hidden = true;
    h.quiet = 0;
    h.rustle = .6;
    h.cat.hideInCover(_hideSpot(h.bush, h.cat));
  }

  void _emerge(_Hider h, List<Vector2> centers) {
    h.hidden = false;
    final bush = centers[h.bush];
    final middle = Vector2(_size.x / 2, _size.y * .45);
    final away = middle - bush;
    final out = bush +
        (away.length < 1 ? Vector2(0, 1) : away.normalized()) *
            (_radius() + 18);
    h.cat.emergeFromCover(out - h.cat.size / 2);
    if (h.cat.isBoss) h.travelTo = _otherBush(h.bush);
  }

  int _freeBush(Vector2 near) {
    final centers = _centers;
    var best = 0;
    var bestScore = double.infinity;
    for (var i = 0; i < centers.length; i++) {
      final taken = _hiders.where((h) => h.bush == i).length;
      final score = taken * 10000 + centers[i].distanceTo(near);
      if (score < bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  int _otherBush(int from) {
    final options = [
      for (var i = 0; i < map.bushes.length; i++)
        if (i != from) i
    ];
    return options[_random.nextInt(options.length)];
  }

  /// A noise at [point]: hiding cats in reach start counting again, and an
  /// unfed Himalaya out in the open runs back to its bush.
  void noise(Vector2 point, [double reach = fishNoise]) {
    final centers = _centers;
    if (centers.isEmpty) return;
    for (final h in _hiders) {
      final cat = h.cat;
      if (h.hidden) {
        if (centers[h.bush].distanceTo(point) < reach) {
          if (h.quiet > .3) h.rustle = .6;
          h.quiet = 0;
        }
        continue;
      }
      if (h.running ||
          cat.hasEaten ||
          cat.catchWindow.canCatch ||
          cat.fishTarget != null ||
          cat.isCarried ||
          cat.center.distanceTo(point) >= reach) {
        continue;
      }
      h.running = true;
      h.travelTo = null;
      cat.ignoresBait = true;
      // The nearest bush is the safest place to bolt to.
      var best = 0;
      for (var i = 1; i < centers.length; i++) {
        if (centers[i].distanceTo(cat.center) <
            centers[best].distanceTo(cat.center)) {
          best = i;
        }
      }
      h.bush = best;
      cat.flinch();
      onRetreat?.call();
    }
  }

  /// Peeking eyes and a quiet ring on every bush with a cat inside.
  void render(Canvas canvas) {
    final centers = _centers;
    for (final h in _hiders) {
      if (!h.hidden) continue;
      final c = centers[h.bush].toOffset();
      final shake = h.rustle > 0 ? sin(_clock * 40) * 3 * h.rustle : 0.0;
      final limit = h.cat.isBoss ? bossQuietSeconds : quietSeconds;
      final calm = (h.quiet / limit).clamp(0.0, 1.0);
      final eyes = c + Offset(shake, -4);
      final blink = (_clock * .7 + h.bush * .37) % 1 > .93;
      for (final dx in [-7.0, 7.0]) {
        canvas.drawOval(
            Rect.fromCenter(
                center: eyes + Offset(dx, 0),
                width: 9,
                height: blink ? 1.5 : 7 + calm * 3),
            Paint()..color = const Color(0xFFFFFDF2));
        if (!blink) {
          canvas.drawCircle(eyes + Offset(dx + (calm - .5) * 2, 1), 2.4,
              Paint()..color = const Color(0xFF3B6FA8));
        }
      }
      if (h.cat.isBoss) {
        final crown = eyes + const Offset(0, -12);
        canvas.drawPath(
            Path()
              ..moveTo(crown.dx - 8, crown.dy + 4)
              ..lineTo(crown.dx - 9, crown.dy - 3)
              ..lineTo(crown.dx - 4, crown.dy)
              ..lineTo(crown.dx, crown.dy - 5)
              ..lineTo(crown.dx + 4, crown.dy)
              ..lineTo(crown.dx + 9, crown.dy - 3)
              ..lineTo(crown.dx + 8, crown.dy + 4)
              ..close(),
            Paint()..color = const Color(0xFFFFC24D));
      }
      // The ring fills while it stays quiet; it turns red right after noise.
      final ring = Rect.fromCircle(center: c + const Offset(0, -34), radius: 9);
      canvas.drawCircle(
          ring.center, 11, Paint()..color = const Color(0xCCFFF4DA));
      canvas.drawArc(
          ring,
          -pi / 2,
          pi * 2 * calm,
          false,
          Paint()
            ..color =
                h.rustle > 0 ? const Color(0xFFE0533E) : const Color(0xFF6FB86A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(
          ring.center, 2.5, Paint()..color = const Color(0xFF8A6446));
    }
  }
}
