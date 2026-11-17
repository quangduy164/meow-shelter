import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_variants.dart';

enum TrapPhase {
  open,
  approaching,
  peeking,
  entering,
  inside,
  closing,
  leaving,
  cooling
}

enum TrapEvent { fed, captured, escaped }

class TrapSlot {
  TrapSlot(this.cage, this.lane, this.area);
  final int cage, lane;
  final Rect area;
  TrapPhase phase = TrapPhase.open;
  bool baited = false, paid = false, chimed = false;
  double elapsed = 0, baitAge = 0, hold = 1.8, cool = 0;
  bool get opensRight => lane == 1;
  bool get occupied => phase != TrapPhase.open && phase != TrapPhase.cooling;
  bool get canBait => phase == TrapPhase.open && !baited;
  bool get showsFish =>
      baited ||
      phase == TrapPhase.approaching ||
      phase == TrapPhase.peeking ||
      phase == TrapPhase.entering ||
      phase == TrapPhase.inside;
}

/// Trap timing owns no sprites or wallet. The scene connects cats and currency.
class WarehouseTraps {
  static const closeSeconds = .75;
  final slots = <TrapSlot>[];
  final cages = <Rect>[];
  double entrySeconds = 1.0, holdBonus = 0, scareRadius = 130;
  bool linked = false;
  int lanes = 1;
  void begin(NightRun run) {
    lanes = run.has(NightCard.twinCages) ? 2 : 1;
    linked = run.has(NightCard.linkedDoors);
    entrySeconds = math.pow(1.25, run.count(NightCard.deepBait)).toDouble();
    holdBonus = .6 * run.count(NightCard.deepBait);
    scareRadius =
        130 * math.pow(.5, run.count(NightCard.quietDoors)).toDouble();
    final centers = run.variant == NightVariant.warehouseStaggered
        ? const [Offset(.17, .47), Offset(.5, .61), Offset(.83, .47)]
        : const [Offset(.17, .54), Offset(.5, .54), Offset(.83, .54)];
    slots.clear();
    cages.clear();
    for (var cage = 0; cage < centers.length; cage++) {
      final c = centers[cage];
      final rect = Rect.fromCenter(center: c, width: .22, height: .24);
      cages.add(rect);
      for (var lane = 0; lane < lanes; lane++) {
        final width = rect.width / lanes;
        final slot = TrapSlot(
            cage,
            lane,
            Rect.fromLTWH(
                rect.left + lane * width, rect.top, width, rect.height));
        if (run.variant == NightVariant.warehouseService && cage == 1) {
          slot.phase = TrapPhase.cooling;
          slot.cool = 8;
        }
        slots.add(slot);
      }
    }
  }

  bool blocks(Rect bounds) =>
      cages.any((cage) => cage.inflate(.012).overlaps(bounds));
  TrapSlot? at(Offset point, Size field) => slots
      .where((s) => s.area
          .contains(Offset(point.dx / field.width, point.dy / field.height)))
      .firstOrNull;
  bool bait(TrapSlot slot, {required bool paid}) {
    if (!slot.canBait) return false;
    slot.baited = true;
    slot.paid = paid;
    slot.baitAge = 0;
    return true;
  }

  void assign(TrapSlot slot, {required bool boss, required bool trusting}) {
    slot.baited = slot.paid = false;
    slot.phase = TrapPhase.approaching;
    slot.elapsed = 0;
    slot.hold = (boss ? 1.2 : 1.8) + holdBonus + (trusting ? 2 : 0);
  }

  void arrive(TrapSlot slot) {
    slot.phase = TrapPhase.peeking;
    slot.elapsed = 0;
  }

  bool shut(TrapSlot slot, {bool forgiving = false}) {
    if (!catchable(slot, forgiving: forgiving)) return false;
    slot.phase = TrapPhase.closing;
    slot.elapsed = 0;
    return true;
  }

  double progress(TrapSlot slot) => switch (slot.phase) {
        TrapPhase.peeking => .22,
        TrapPhase.entering =>
          .22 + .78 * (slot.elapsed / entrySeconds).clamp(0, 1),
        TrapPhase.inside || TrapPhase.closing => 1,
        TrapPhase.leaving => 1 - (slot.elapsed / .8).clamp(0, 1),
        _ => 0,
      };
  double fishLeft(TrapSlot slot) => slot.phase == TrapPhase.inside
      ? 1 - (slot.elapsed / slot.hold).clamp(0, 1)
      : 1;
  double doorClosed(TrapSlot slot) => slot.phase == TrapPhase.closing
      ? (slot.elapsed / .18).clamp(0, 1).toDouble()
      : 0;

  List<(TrapSlot, TrapEvent)> update(double dt,
      {bool frozen = false,
      double windowScale = 1,
      bool Function(TrapSlot)? frozenSlot}) {
    final events = <(TrapSlot, TrapEvent)>[];
    for (final slot in slots) {
      if (slot.phase == TrapPhase.cooling) {
        slot.cool = math.max(0, slot.cool - dt);
        if (slot.cool == 0) slot.phase = TrapPhase.open;
        continue;
      }
      if (slot.phase == TrapPhase.open) {
        if (slot.baited) slot.baitAge += dt;
        continue;
      }
      if (slot.phase == TrapPhase.approaching) continue;
      if (slot.phase == TrapPhase.inside &&
          (frozen || frozenSlot?.call(slot) == true)) {
        continue;
      }
      slot.elapsed += slot.phase == TrapPhase.inside ? dt * windowScale : dt;
      final duration = switch (slot.phase) {
        TrapPhase.peeking => .8,
        TrapPhase.entering => entrySeconds,
        TrapPhase.inside => slot.hold,
        TrapPhase.closing => closeSeconds,
        _ => .8,
      };
      if (slot.elapsed < duration) continue;
      slot.elapsed = 0;
      switch (slot.phase) {
        case TrapPhase.peeking:
          slot.phase = TrapPhase.entering;
        case TrapPhase.entering:
          slot.phase = TrapPhase.inside;
          events.add((slot, TrapEvent.fed));
        case TrapPhase.inside:
          slot.phase = TrapPhase.leaving;
        case TrapPhase.closing:
          reset(slot);
          events.add((slot, TrapEvent.captured));
        case TrapPhase.leaving:
          reset(slot);
          events.add((slot, TrapEvent.escaped));
        default:
          break;
      }
    }
    return events;
  }

  bool catchable(TrapSlot slot, {bool forgiving = false}) =>
      slot.phase == TrapPhase.inside ||
      (forgiving && slot.phase == TrapPhase.entering && progress(slot) >= .7);
  void reset(TrapSlot slot) {
    slot.phase = TrapPhase.cooling;
    slot.cool = 4;
    slot.elapsed = 0;
    slot.baited = slot.paid = false;
    slot.baitAge = 0;
  }

  Iterable<TrapSlot> closingGroup(TrapSlot selected) sync* {
    yield selected;
    if (linked) {
      final other = slots.firstWhere(
          (s) => s.cage == (selected.cage + 1) % 3 && s.lane == selected.lane);
      if (other.occupied && other.phase != TrapPhase.closing) yield other;
    }
  }
}
