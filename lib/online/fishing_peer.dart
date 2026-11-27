import 'visual_state.dart';
import '../camp/camp_state.dart';
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

  String get displayName {
    final value = display['name'];
    if (value is! String) return CatBreed.of(cat).name;
    final name = value.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
    if (name.isEmpty) return CatBreed.of(cat).name;
    return String.fromCharCodes(name.runes.take(40));
  }

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
        stamp: stamp,
        display: {
          'name': CampState.instance.nameOf(p.cat),
          'animating': p.pose.$1 != 'fish-reel' || c.pulling,
          'pose': c.phase.name
        });
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
        boatPosition = target.boatPosition,
        _firstFrame = target.pose.$3;
  final String uid;
  FishingPeerSnapshot target;
  Offset position, boatPosition;
  double _animationTime = 0;
  int _firstFrame;

  FishingPlayerPose get pose {
    final (action, frames, _) = target.pose;
    if (target.display['animating'] == false) return target.pose;
    final fps = switch (action) {
      'idle' => 7.0,
      'walk' || 'run' => 10.0,
      'sleep' => 3.0,
      'fish-wait' || 'fish-reel' => 5.0,
      'fish-cast' => frames / .65,
      _ => 8.0,
    };
    if (action == 'row') {
      return (action, frames, rowingFrame((_animationTime / 1.65) % 1));
    }
    final frame = _firstFrame + (_animationTime * fps).floor();
    final once =
        const {'jump', 'roll', 'fish-cast', 'drop-wrong'}.contains(action);
    if (action == 'fish-hold') {
      return (
        action,
        frames,
        _animationTime < 1 && _firstFrame == 0
            ? 0
            : 1 +
                (((_animationTime - 1).clamp(0, double.infinity)) * 3).floor() %
                    (frames - 1)
      );
    }
    return (action, frames, once ? frame.clamp(0, frames - 1) : frame % frames);
  }

  void accept(FishingPeerSnapshot next) {
    if (next.stamp < target.stamp) return;
    if (next.location != target.location ||
        (next.position - position).distance > 600) {
      position = next.position;
    }
    if ((next.boatPosition - boatPosition).distance > 600) {
      boatPosition = next.boatPosition;
    }
    if (next.cat != target.cat ||
        next.location != target.location ||
        next.pose.$1 != target.pose.$1 ||
        next.display['animating'] != target.display['animating'] ||
        next.display['pose'] != target.display['pose']) {
      _animationTime = 0;
      _firstFrame = next.pose.$3;
    }
    target = next;
  }

  void update(double dt) {
    _animationTime += dt;
    final k = 1 - math.exp(-14 * dt);
    position = Offset.lerp(position, target.position, k)!;
    boatPosition = Offset.lerp(boatPosition, target.boatPosition, k)!;
  }
}
