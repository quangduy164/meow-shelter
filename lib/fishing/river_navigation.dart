import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'fishing_river.dart';
import 'river_props.dart';

/// A* runs on a click only; sampled edges share bank and rock clearance.
List<Offset> riverDetour(RiverProps props, Offset start, Offset goal) {
  const step = 32.0;
  final columns = (FishingRiver.length / step).ceil() + 1;
  final rows = (FishingRiver.height / step).ceil() + 1;
  Offset point(int id) => Offset((id % columns) * step, (id ~/ columns) * step);
  final costs = <int, double>{}, previous = <int, int>{};
  final queue = SplayTreeMap<double, List<int>>();
  final closed = <int>{};
  void enqueue(int id, double cost, int parent) {
    if (cost >= (costs[id] ?? double.infinity)) return;
    costs[id] = cost;
    previous[id] = parent;
    final priority = cost + (point(id) - goal).distance;
    (queue[priority] ??= []).add(id);
  }

  final sx = (start.dx / step).round(), sy = (start.dy / step).round();
  for (var y = sy - 2; y <= sy + 2; y++) {
    for (var x = sx - 2; x <= sx + 2; x++) {
      if (x < 0 || x >= columns || y < 0 || y >= rows) continue;
      final id = y * columns + x;
      if (props.clearLine(start, point(id))) {
        enqueue(id, (start - point(id)).distance, -1);
      }
    }
  }
  while (queue.isNotEmpty) {
    final key = queue.firstKey()!;
    final bucket = queue[key]!;
    final id = bucket.removeLast();
    if (bucket.isEmpty) queue.remove(key);
    if (!closed.add(id)) continue;
    final p = point(id);
    if ((p - goal).distance < step * 2.5 && props.clearLine(p, goal)) {
      final result = <Offset>[goal];
      var current = id;
      while (current >= 0) {
        result.add(point(current));
        current = previous[current]!;
      }
      final route = result.reversed.toList();
      // Collapse straight stretches without cutting rocks or bends.
      final smooth = <Offset>[];
      var anchor = start, i = 0;
      while (i < route.length) {
        var last = i;
        for (var j = i + 1; j < route.length; j++) {
          if (!props.clearLine(anchor, route[j])) break;
          last = j;
        }
        anchor = route[last];
        smooth.add(anchor);
        i = last + 1;
      }
      return smooth;
    }
    final x = id % columns, y = id ~/ columns;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx, ny = y + dy;
        if (nx < 0 || nx >= columns || ny < 0 || ny >= rows) continue;
        final next = ny * columns + nx;
        if (closed.contains(next)) continue;
        if (props.clearLine(p, point(next))) {
          enqueue(next,
              costs[id]! + step * (dx != 0 && dy != 0 ? math.sqrt2 : 1), id);
        }
      }
    }
  }
  return [];
}
