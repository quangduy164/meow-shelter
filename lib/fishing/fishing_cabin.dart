import 'dart:math' as math;

import 'package:flutter/painting.dart';
import '../audio/game_audio.dart';

/// A moored vessel with a separate, session-only walkable cabin.
class FishingCabin {
  static const radius = 130.0;
  static const ship = Offset(11500, 1000);
  static const mooring = Offset(11500, 1195);
  static const roomSize = Size(800, 480);
  static const exit = Offset(400, 410);
  static const floor = Rect.fromLTRB(155, 205, 650, 414);

  /// Bedroom to the right: [door] on the main room's right wall leads to
  /// [bedroomDoor] on the bedroom's left wall. The bed sits right of its floor.
  static const door = Offset(650, 257);
  static const bedroomDoor = Offset(155, 257);
  static const bedroomFloor = Rect.fromLTRB(155, 205, 520, 414);
  static const doorTap = Rect.fromLTRB(650, 200, 760, 315);
  static const bedroomDoorTap = Rect.fromLTRB(40, 200, 155, 315);

  /// Half height of the wall opening drawn around [door] / [bedroomDoor].
  static const doorHalfHeight = 45.0;

  /// Treasure chest footprint in the bedroom (lid top to base); art and tap
  /// area both derive from it.
  static const chest = Rect.fromLTRB(66, 338, 148, 418);
  static final chestTap = chest.inflate(10);
  static const chestSpot = Offset(172, 384);

  /// Captain's double bed, fitted between the wall post (x 528) and the
  /// right wall (x 746). Art and tap area both derive from [bed].
  static const bed = Rect.fromLTRB(552, 198, 724, 400);
  static const bedTap = Rect.fromLTRB(546, 104, 730, 404);

  /// One sleeping place per side of the double bed: the local cat takes the
  /// left; the right is reserved for a second (online) player's cat.
  static const bedSpots = [Offset(596, 300), Offset(681, 300)];

  /// Tap the bed and the cat walks to [bedSide], hops onto [bedSpot] on the
  /// quilt and falls asleep.
  static const bedSide = Offset(515, 300);
  static const bedSpot = Offset(596, 300);
  static const hopTime = .55;

  /// Sleeping long enough fades to black, jumps the clock to morning and
  /// fades back in. [dawnDue] is raised once at the darkest moment for the
  /// screen to move the game clock.
  static const sleepFade = 1.2, sleepHold = .6, sleepWake = 1.2;
  double sleptFor = 0;
  bool dawnDue = false;

  /// 0..1 darkness of the sleep fade.
  double get sleepDark {
    if (!sleeping) return 0;
    if (sleptFor < sleepFade) return sleptFor / sleepFade;
    if (sleptFor < sleepFade + sleepHold) return 1;
    return (1 - (sleptFor - sleepFade - sleepHold) / sleepWake).clamp(0.0, 1.0);
  }

  int room = 0;
  bool chestRequested = false, bedRequested = false, sleeping = false;

  /// 0..1 through a hop onto or off the bed.
  double hop = 0;
  Offset _hopFrom = bedSide;
  Offset? _hopTo;
  void Function()? _afterHop;
  bool get hopping => _hopTo != null;

  /// Walks to the bed; on arrival the cat hops up and sleeps.
  void goToBed() {
    if (room != 1 || sleeping || hopping) return;
    walkTo(bedSide);
    bedRequested = true;
  }

  void _startHop(Offset from, Offset to, [void Function()? then]) {
    GameAudio.instance.playGameplay(GameSound.fishingJump);
    _hopFrom = from;
    _hopTo = to;
    hop = 0;
    _afterHop = then;
    facingRight = to.dx > from.dx;
  }

  /// A sleeping cat hops down first, then does [then]. False when awake.
  bool _leaveBed(void Function() then) {
    if (!sleeping) return false;
    sleeping = false;
    _startHop(bedSpot, bedSide, then);
    return true;
  }

  bool get atChest =>
      chestRequested && room == 1 && !walking && (cat - chestSpot).distance < 1;

  /// Walks to the bedroom chest; the room UI opens it on arrival.
  void goToChest() {
    if (room != 1) return;
    walkTo(chestSpot);
    chestRequested = true;
  }

  int? _nextRoom;
  Rect get currentFloor => room == 0 ? floor : bedroomFloor;
  static bool hit(Offset point) =>
      Rect.fromLTWH(ship.dx - 150, ship.dy - 150, 300, 230).contains(point);
  bool pending = false, inside = false, leaving = false, facingRight = true;
  Offset cat = exit;
  Offset? destination;
  double clock = 0;
  bool get walking => destination != null;
  void enter() {
    GameAudio.instance.playGameplay(GameSound.nightDoor);
    pending = false;
    inside = true;
    leaving = false;
    room = 0;
    _nextRoom = null;
    cat = exit;
    destination = null;
    sleeping = bedRequested = false;
    _hopTo = null;
    _afterHop = null;
  }

  void walkTo(Offset p) {
    if (!inside || hopping || _leaveBed(() => walkTo(p))) return;
    leaving = false;
    chestRequested = false;
    bedRequested = false;
    _nextRoom = null;
    final f = currentFloor;
    destination =
        Offset(p.dx.clamp(f.left, f.right), p.dy.clamp(f.top, f.bottom));
  }

  /// Walks through the connecting door to the other room.
  void switchRoom() {
    if (!inside || hopping || _leaveBed(switchRoom)) return;
    leaving = false;
    chestRequested = false;
    bedRequested = false;
    _nextRoom = 1 - room;
    destination = room == 0 ? door : bedroomDoor;
  }

  void requestExit() {
    if (!inside || hopping || _leaveBed(requestExit)) return;
    leaving = true;
    chestRequested = false;
    bedRequested = false;
    _nextRoom = room == 1 ? 0 : null;
    destination = room == 1 ? bedroomDoor : exit;
  }

  void update(double dt) {
    clock += dt;
    if (sleeping) {
      final before = sleptFor;
      sleptFor += dt;
      if (before < sleepFade + sleepHold / 2 &&
          sleptFor >= sleepFade + sleepHold / 2) {
        dawnDue = true;
        GameAudio.instance.playGameplay(GameSound.moonReveal);
      }
    } else {
      sleptFor = 0;
    }
    final hopTo = _hopTo;
    if (hopTo != null) {
      hop = math.min(1, hop + dt / hopTime);
      cat = Offset.lerp(_hopFrom, hopTo, hop)!;
      if (hop >= 1) {
        _hopTo = null;
        sleeping = hopTo == bedSpot;
        if (sleeping) GameAudio.instance.playGameplay(GameSound.catNap);
        final then = _afterHop;
        _afterHop = null;
        then?.call();
      }
      return;
    }
    final target = destination;
    if (target == null) return;
    final delta = target - cat;
    if (delta.dx.abs() > .01) facingRight = delta.dx > 0;
    if (delta.distance <= 145 * dt) {
      cat = target;
      destination = null;
      final next = _nextRoom;
      if (next != null) {
        _nextRoom = null;
        GameAudio.instance.playGameplay(GameSound.nightDoor);
        room = next;
        cat = next == 1 ? bedroomDoor : door;
        if (leaving) destination = exit;
        return;
      }
      if (leaving) {
        GameAudio.instance.playGameplay(GameSound.nightDoor);
        inside = false;
        leaving = false;
      }
      if (bedRequested && room == 1 && cat == bedSide) {
        bedRequested = false;
        _startHop(bedSide, bedSpot);
      }
    } else {
      cat += delta / delta.distance * 145 * dt;
    }
  }
}
