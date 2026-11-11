import 'dart:ui';
import 'package:flame/components.dart';
import 'herd_map.dart';

/// Visibility graph around solid rectangles. Only rebuilt when map/size changes.
/// Cats route to their assigned trail point; terrain still controls movement.
class HerdNavigation {
  HerdMap? _map;
  final _size = Vector2.zero();
  final _walls = <Rect>[];
  final _corners = <Vector2>[];
  final _edges = <List<(int, double)>>[];

  void _prepare(HerdMap map, Vector2 size) {
    if (identical(map, _map) && size == _size) return;
    _map = map;
    _size.setFrom(size);
    _walls
      ..clear()
      ..addAll(map.walls.map((r) => map.pixels(r, size).inflate(15)));
    _corners.clear();
    _edges.clear();
    for (final r in _walls) {
      // Extra clearance lets turning cats reach a corner without scraping it.
      final outer = r.inflate(3);
      for (final p in [
        outer.topLeft,
        outer.topRight,
        outer.bottomLeft,
        outer.bottomRight
      ]) {
        final v = Vector2(p.dx, p.dy);
        if (v.x < 24 ||
            v.x > size.x - 24 ||
            v.y < 66 ||
            v.y > size.y - 30 ||
            map.blocked(v, size)) continue;
        _corners.add(v);
      }
    }
    for (var i = 0; i < _corners.length; i++) {
      _edges.add([]);
    }
    for (var i = 0; i < _corners.length; i++) {
      for (var j = i + 1; j < _corners.length; j++) {
        if (!_clear(_corners[i], _corners[j])) continue;
        final d = _corners[i].distanceTo(_corners[j]);
        _edges[i].add((j, d));
        _edges[j].add((i, d));
      }
    }
  }

  bool clearLine(HerdMap map, Vector2 size, Vector2 from, Vector2 to) {
    _prepare(map, size);
    return _clear(from, to);
  }

  bool _clear(Vector2 from, Vector2 to) =>
      !_walls.any((r) => _crosses(r, from, to));

  // Exact segment/rectangle intersection avoids missing thin obstacle corners.
  static bool _crosses(Rect r, Vector2 a, Vector2 b) {
    var enter = 0.0, leave = 1.0;
    for (final (start, delta, low, high) in [
      (a.x, b.x - a.x, r.left, r.right),
      (a.y, b.y - a.y, r.top, r.bottom),
    ]) {
      if (delta.abs() < 1e-9) {
        if (start < low || start > high) return false;
      } else {
        final t1 = (low - start) / delta, t2 = (high - start) / delta;
        final near = t1 < t2 ? t1 : t2, far = t1 > t2 ? t1 : t2;
        if (near > enter) enter = near;
        if (far < leave) leave = far;
        if (enter > leave) return false;
      }
    }
    return true;
  }

  Vector2 nextWaypoint(HerdMap map, Vector2 size, Vector2 from, Vector2 goal) {
    _prepare(map, size);
    if (_clear(from, goal)) return goal;
    final count = _corners.length;
    final distance = List<double>.filled(count, double.infinity);
    final previous = List<int>.filled(count, -1);
    final visited = List<bool>.filled(count, false);
    for (var i = 0; i < count; i++) {
      if (_clear(from, _corners[i])) distance[i] = from.distanceTo(_corners[i]);
    }
    var bestDistance = double.infinity, best = -1;
    for (var step = 0; step < count; step++) {
      var current = -1, minDistance = double.infinity;
      for (var i = 0; i < count; i++) {
        if (!visited[i] && distance[i] < minDistance) {
          current = i;
          minDistance = distance[i];
        }
      }
      if (current < 0 || minDistance >= bestDistance) break;
      visited[current] = true;
      if (_clear(_corners[current], goal)) {
        final total = minDistance + _corners[current].distanceTo(goal);
        if (total < bestDistance) {
          bestDistance = total;
          best = current;
        }
      }
      for (final (next, cost) in _edges[current]) {
        if (minDistance + cost < distance[next]) {
          distance[next] = minDistance + cost;
          previous[next] = current;
        }
      }
    }
    if (best < 0) return from;
    while (previous[best] >= 0) {
      best = previous[best];
    }
    return _corners[best];
  }
}
