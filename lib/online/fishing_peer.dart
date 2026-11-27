import 'visual_state.dart';
import 'dart:math' as math;
import 'package:flutter/painting.dart';

import '../fishing/fishing_boat.dart';
import '../fishing/fishing_controller.dart';
import '../fishing/fishing_player.dart';
import '../fishing/fishing_river.dart';
import '../game/cats/cat_breed.dart';
import '../game/constants.dart';

/// Only visible state crosses the network. No inventory or rewards here.
class FishingPeerSnapshot {
  const FishingPeerSnapshot(
      {required this.cat,
      required this.location,
      required this.position,
      required this.facingRight,
      required this.pose,
      required this.boat,
      required this.boatPosition,
      required this.boatRight,
      required this.rowing,
      required this.stamp,
      this.display = const {}});

  final String cat;
  final FishingPlayerLocation location;
  final Offset position, boatPosition;
  final bool facingRight, boatRight, rowing;
  final FishingPlayerPose pose;
  final FishingBoat boat;
  final int stamp;
  final Map<String, dynamic> display;

  static int framesFor(String action) => switch (action) {
        'idle' => framesIdle,
        'walk' => framesWalk,
        'run' => framesRun,
        'jump' => framesJump,
        'roll' => framesRoll,
        'row' => framesRow,
        'sleep' => framesSleep,
        'panic' => framesPanic,
        'fish-cast' => framesFishCast,
        'fish-wait' => framesFishWait,
        'fish-reel' => framesFishReel,
        'fish-hold' => framesFishHold,
        'drop-wrong' => framesDropWrong,
        _ => 0,
      };

  factory FishingPeerSnapshot.local(FishingController c, int stamp) {
    final p = c.player, r = c.river;
    return FishingPeerSnapshot(
        cat: p.cat,
        location: p.location,
        position: p.position,
        facingRight: p.facingRight,
        pose: p.pose,
        boat: r.boatStyle,
        boatPosition: r.boat,
        boatRight: r.boatFacingRight,
        rowing:
            r.rowing && !r.island.ashore && !r.cabin.inside && !r.cave.inside,
        stamp: stamp);
  }

  Map<String, Object> toJson() => {
        'cat': cat,
        'location': location.name,
        'x': position.dx,
        'y': position.dy,
        'right': facingRight,
        'action': pose.$1,
        'frame': pose.$3,
        'boat': boat.name,
        'bx': boatPosition.dx,
        'by': boatPosition.dy,
        'boatRight': boatRight,
        'rowing': rowing,
        'stamp': stamp,
        if (display.isNotEmpty) 'display': VisualState.encode(display),
      };

  static FishingPeerSnapshot? parse(Object? value) {
    if (value is! Map) return null;
    final cat = value['cat'], action = value['action'];
    final location = FishingPlayerLocation.values
        .where((v) => v.name == value['location'])
        .firstOrNull;
    final boat =
        FishingBoat.values.where((v) => v.name == value['boat']).firstOrNull;
    final frame = value['frame'], stamp = value['stamp'];
    bool coordinate(Object? n, double max) =>
        n is num && n.isFinite && n >= 0 && n <= max;
    if (cat is! String ||
        !CatBreed.all.any((b) => b.id == cat) ||
        action is! String ||
        framesFor(action) == 0 ||
        location == null ||
        boat == null ||
        frame is! int ||
        frame < 0 ||
        frame >= framesFor(action) ||
        stamp is! int ||
        stamp < 0 ||
        value['right'] is! bool ||
        value['boatRight'] is! bool ||
        value['rowing'] is! bool ||
        !coordinate(value['x'], FishingRiver.length) ||
        !coordinate(value['y'], FishingRiver.height) ||
        !coordinate(value['bx'], FishingRiver.length) ||
        !coordinate(value['by'], FishingRiver.height)) {
      return null;
    }
    return FishingPeerSnapshot(
        cat: cat,
        location: location,
        position: Offset(
            (value['x'] as num).toDouble(), (value['y'] as num).toDouble()),
        facingRight: value['right'] as bool,
        pose: (action, framesFor(action), frame),
        boat: boat,
        boatPosition: Offset(
            (value['bx'] as num).toDouble(), (value['by'] as num).toDouble()),
        boatRight: value['boatRight'] as bool,
        rowing: value['rowing'] as bool,
        stamp: stamp,
        display: VisualState.decode(value['display']) ?? const {});
  }
}

/// Interpolated display state; never feeds back into local physics.
class FishingPeer {
  FishingPeer(this.uid, this.target)
      : position = target.position,
        boatPosition = target.boatPosition;
  final String uid;
  FishingPeerSnapshot target;
  Offset position, boatPosition;
  void accept(FishingPeerSnapshot next) {
    if (next.stamp < target.stamp) return;
    if (next.location != target.location ||
        (next.position - position).distance > 600) {
      position = next.position;
    }
    if ((next.boatPosition - boatPosition).distance > 600) {
      boatPosition = next.boatPosition;
    }
    target = next;
  }

  void update(double dt) {
    final k = 1 - math.exp(-14 * dt);
    position = Offset.lerp(position, target.position, k)!;
    boatPosition = Offset.lerp(boatPosition, target.boatPosition, k)!;
  }
}
