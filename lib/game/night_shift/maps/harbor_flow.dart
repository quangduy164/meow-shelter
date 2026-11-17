import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_variants.dart';

class HarborGate {
  HarborGate(this.column, this.lane);
  final int column, lane;
  int direction = 0;
  bool chimed = false;
  double get x => HarborFlow.gateX[column];
  List<int> get choices => [0, if (lane > 0) -1, if (lane < 2) 1];
}

class HarborRaft {
  HarborRaft(this.id, this.lane, this.breed);
  final int id;
  final String breed;
  int lane, fromLane = 0;
  double x = HarborFlow.startX, shift = 1, anchor = 0, stun = 0;
  bool done = false;
  double get y =>
      HarborFlow.laneY[fromLane] +
      (HarborFlow.laneY[lane] - HarborFlow.laneY[fromLane]) *
          shift.clamp(0, 1).toDouble();
  Offset get center => Offset(x, y);
}

enum HarborEvent { docked, crashed, wrongDock, collided }

/// Raft routes only. Cats, fish stock and rewards are attached by the scene.
class HarborFlow {
  static const laneY = [.32, .52, .72];
  static const gateX = [.34, .62];
  static const startX = .05, endX = .93;
  final rafts = <HarborRaft>[];
  final gates = <HarborGate>[];

  /// Dock lane -> breed it accepts. Null means not assigned yet.
  final dockBreeds = <int, String?>{};
  final rocks = <(int, double)>[];
  final columnDirection = [0, 0];
  double speed = .052;
  bool sturdy = false, rope = false, linked = false, collisions = false;
  int? sharedDock;
  int stage = 1, _id = 0;

  void begin(NightRun run) {
    stage = (run.night - 1) ~/ NightRun.mapOrder.length + 1;
    linked = stage >= 2;
    collisions = stage >= 3;
    speed = .052 * math.pow(.8, run.count(NightCard.slowCurrent)).toDouble();
    sturdy = run.has(NightCard.sturdyRaft);
    rope = run.has(NightCard.dockRope);
    dockBreeds
      ..clear()
      ..addAll({
        for (final lane in run.variant == NightVariant.harborTwin
            ? const [0, 2]
            : const [0, 1, 2])
          lane: null
      });
    sharedDock = run.has(NightCard.extraDock)
        ? (dockBreeds.containsKey(1) ? 1 : 0)
        : null;
    rocks
      ..clear()
      ..addAll(run.variant == NightVariant.harborRocks
          ? const [(1, .48), (0, .78), (2, .78)]
          : const []);
    gates
      ..clear()
      ..addAll([
        for (var c = 0; c < gateX.length; c++)
          for (var lane = 0; lane < laneY.length; lane++) HarborGate(c, lane)
      ]);
    columnDirection.setAll(0, const [0, 0]);
    rafts.clear();
    _id = 0;
  }

  bool accepts(int lane, String breed) =>
      dockBreeds.containsKey(lane) &&
      (lane == sharedDock || dockBreeds[lane] == breed);

  /// Makes sure some dock takes [breed]. Returns the relabelled lane, -1 when
  /// nothing changed, or null when every dock is still needed.
  int? assignDock(String breed, Iterable<String> needed) {
    if (dockBreeds.keys.any((lane) => accepts(lane, breed))) return -1;
    final busy = needed.toSet();
    final free = dockBreeds.keys
        .where((lane) => lane != sharedDock && !busy.contains(dockBreeds[lane]))
        .toList();
    if (free.isEmpty) return null;
    final lane =
        free.firstWhere((l) => dockBreeds[l] == null, orElse: () => free.first);
    dockBreeds[lane] = breed;
    return lane;
  }

  HarborRaft launch(int lane, String breed) {
    final raft = HarborRaft(_id++, lane, breed)..fromLane = lane;
    rafts.add(raft);
    return raft;
  }

  bool startClear(int lane) =>
      !rafts.any((r) => !r.done && r.lane == lane && r.x < startX + .13);
  HarborGate gate(int column, int lane) =>
      gates.firstWhere((g) => g.column == column && g.lane == lane);

  /// Swipe sets a direction directly; linked gates move the whole column.
  void setDirection(HarborGate gate, int direction) {
    if (!linked) {
      if (gate.choices.contains(direction)) gate.direction = direction;
      return;
    }
    columnDirection[gate.column] = direction;
    for (final g in gates.where((g) => g.column == gate.column)) {
      g.direction = g.choices.contains(direction) ? direction : 0;
    }
  }

  bool approaching(HarborGate gate) => rafts.any((r) =>
      !r.done && r.lane == gate.lane && r.x < gate.x && r.x > gate.x - .14);

  void turn(HarborGate gate) {
    if (!linked) {
      final options = gate.choices;
      gate.direction =
          options[(options.indexOf(gate.direction) + 1) % options.length];
      return;
    }
    const cycle = [0, -1, 1];
    final next = cycle[(cycle.indexOf(columnDirection[gate.column]) + 1) % 3];
    columnDirection[gate.column] = next;
    for (final g in gates.where((g) => g.column == gate.column)) {
      g.direction = g.choices.contains(next) ? next : 0;
    }
  }

  HarborRaft? near(Offset point) {
    final list = rafts.where((r) => !r.done).toList()
      ..sort((a, b) =>
          (a.center - point).distance.compareTo((b.center - point).distance));
    return list.firstOrNull;
  }

  List<(HarborRaft, HarborEvent)> update(double dt, {double pace = 1}) {
    final events = <(HarborRaft, HarborEvent)>[];
    for (final raft in rafts.where((r) => !r.done)) {
      raft.shift = math.min(1, raft.shift + dt / .9);
      if (raft.anchor > 0 || raft.stun > 0) {
        raft.anchor = math.max(0, raft.anchor - dt);
        raft.stun = math.max(0, raft.stun - dt);
        continue;
      }
      final before = raft.x;
      raft.x += speed * pace * dt;
      for (var column = 0; column < gateX.length; column++) {
        final x = gateX[column];
        if (before < x && raft.x >= x) {
          final direction = gate(column, raft.lane).direction;
          if (direction != 0) {
            raft
              ..fromLane = raft.lane
              ..lane += direction
              ..shift = 0;
          }
        }
      }
      final rock = rocks.where((r) =>
          r.$1 == raft.lane && before < r.$2 - .035 && raft.x >= r.$2 - .035);
      if (rock.isNotEmpty) {
        if (sturdy) {
          raft
            ..x = rock.first.$2 + .04
            ..stun = 1.5;
        } else {
          events.add((raft, HarborEvent.crashed));
          _restart(raft);
        }
        continue;
      }
      if (raft.x < endX) continue;
      final pulled = rope
          ? [raft.lane - 1, raft.lane + 1]
              .where((lane) => accepts(lane, raft.breed))
              .firstOrNull
          : null;
      if (accepts(raft.lane, raft.breed) || pulled != null) {
        raft.done = true;
        events.add((raft, HarborEvent.docked));
      } else {
        events.add((
          raft,
          dockBreeds.containsKey(raft.lane)
              ? HarborEvent.wrongDock
              : HarborEvent.crashed
        ));
        _restart(raft);
      }
    }
    if (collisions) {
      final moving = rafts.where((r) => !r.done && r.x > startX + .02).toList();
      final hit = <HarborRaft>{};
      for (var i = 0; i < moving.length; i++) {
        for (var j = i + 1; j < moving.length; j++) {
          final a = moving[i], b = moving[j];
          if ((a.x - b.x).abs() < .085 && (a.y - b.y).abs() < .07) {
            hit.addAll([a, b]);
          }
        }
      }
      for (final raft in hit) {
        events.add((raft, HarborEvent.collided));
        _restart(raft);
      }
    }
    rafts.removeWhere((r) => r.done);
    return events;
  }

  void _restart(HarborRaft raft) {
    final queued = rafts
        .where((r) =>
            r != raft && !r.done && r.lane == raft.lane && r.x < startX + .13)
        .length;
    raft
      ..x = startX - .12 * queued
      ..fromLane = raft.lane
      ..shift = 1
      ..stun = 1;
  }
}
