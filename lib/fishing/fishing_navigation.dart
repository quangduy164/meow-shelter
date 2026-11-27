import 'package:flutter/painting.dart';
import 'fishing_river.dart';
import 'fishing_island.dart';
import 'fishing_place.dart';

/// Tap routing and destination arrival; no inventory, fish rolls or UI dialogs.
class FishingNavigation {
  FishingNavigation(this.river);
  final FishingRiverRound river;
  FishingVisit? _requested, _arrived;
  FishingVisit? get requested => _requested;

  FishingVisit? takeArrival() {
    final arrived = _arrived;
    _arrived = null;
    return arrived;
  }

  bool tap(Offset point,
      {required void Function(bool clearLoss) beforeMove,
      required void Function() returnToBoat}) {
    river.cabin.pending = false;
    final island = river.island;
    _requested = null;
    if (island.lookout) {
      island.climbDown();
      return true;
    }
    final place = FishingVisit.hitAt(point);
    if (place != null && _goTo(place, beforeMove)) {
      return true;
    }
    if (island.ashore) {
      beforeMove(false);
      if (!island.onBank && FishingIslandVisit.hitsLighthouse(point)) {
        island.climbLighthouse();
      } else if (!island.onBank && FishingIslandVisit.inMountain(point)) {
        island.goToCave();
      } else if ((point - river.boat).distance < 70) {
        returnToBoat();
      } else if (island.landContains(point)) {
        island.walkTo(point);
      }
      return true;
    }
    final docking = FishingIslandVisit.contains(point) ||
        (point - FishingIslandVisit.dockTap).distance < 45;
    final bank = point.dx >= 80 &&
        point.dx <= FishingRiver.length - 80 &&
        point.dy >= 150 &&
        point.dy <= FishingRiver.height - 30 &&
        (point.dy < FishingRiver.top(point.dx) - 10 ||
            point.dy > FishingRiver.bottom(point.dx) + 10);
    if (!docking && !bank && !FishingRiver.contains(point)) return false;
    beforeMove(true);
    if (bank && !docking) {
      island.chooseBank(point);
      island.bankMooring = river.props.resolve(island.visitMooring);
    } else if (docking) {
      island.chooseIsland();
    }
    island.dockRequested = docking || bank;
    river.sailTo(island.dockRequested ? island.visitMooring : point);

    return true;
  }

  /// Rows (or, for the boathouse, also walks along the near bank) to
  /// [visit]; its screen only opens there. False when it cannot be reached
  /// from here (e.g. the market while ashore), so the tap is handled as usual.
  bool _goTo(FishingVisit visit, void Function(bool clearLoss) beforeMove) {
    final island = river.island;
    final walk = island.ashore;
    if (walk && (visit.bankDoor == null || island.northBank != false)) {
      return false;
    }
    beforeMove(true);
    if (visit == FishingVisit.cabinShip) {
      river.sailTo(visit.mooring);
      river.cabin.pending = true;
      return true;
    }
    _requested = visit;
    if (walk) {
      island.walkTo(visit.bankDoor!);
    } else {
      river.sailTo(visit.mooring);
    }
    return true;
  }

  void update() {
    final visit = _requested;
    if (visit == null) return;
    final island = river.island;
    if (island.ashore ? island.walking : river.moving) return;
    _requested = null;
    final arrived = island.ashore
        ? visit.bankDoor != null &&
            (island.cat - visit.bankDoor!).distance < 110
        : (river.boat - visit.mooring).distance < 30;
    if (arrived) _arrived = visit;
  }
}
