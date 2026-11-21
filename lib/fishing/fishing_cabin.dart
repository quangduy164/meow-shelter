import 'package:flutter/painting.dart';

/// A moored vessel with a separate, session-only walkable cabin.
class FishingCabin {
  static const radius = 130.0;
  static const ship = Offset(10300, 1050);
  static const mooring = Offset(10300, 1245);
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
  static const chestTap = Rect.fromLTRB(56, 330, 158, 428);
  static const chestSpot = Offset(172, 384);
  int room = 0;
  bool chestRequested = false;
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
      const Rect.fromLTWH(10150, 900, 300, 230).contains(point);
  bool pending = false, inside = false, leaving = false, facingRight = true;
  Offset cat = exit;
  Offset? destination;
  double clock = 0;
  bool get walking => destination != null;
  void enter() {
    pending = false;
    inside = true;
    leaving = false;
    room = 0;
    _nextRoom = null;
    cat = exit;
    destination = null;
  }

  void walkTo(Offset p) {
    if (!inside) return;
    leaving = false;
    chestRequested = false;
    _nextRoom = null;
    final f = currentFloor;
    destination =
        Offset(p.dx.clamp(f.left, f.right), p.dy.clamp(f.top, f.bottom));
  }

  /// Walks through the connecting door to the other room.
  void switchRoom() {
    if (!inside) return;
    leaving = false;
    chestRequested = false;
    _nextRoom = 1 - room;
    destination = room == 0 ? door : bedroomDoor;
  }

  void requestExit() {
    if (!inside) return;
    leaving = true;
    chestRequested = false;
    _nextRoom = room == 1 ? 0 : null;
    destination = room == 1 ? bedroomDoor : exit;
  }

  void update(double dt) {
    clock += dt;
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
        room = next;
        cat = next == 1 ? bedroomDoor : door;
        if (leaving) destination = exit;
        return;
      }
      if (leaving) {
        inside = false;
        leaving = false;
      }
    } else {
      cat += delta / delta.distance * 145 * dt;
    }
  }
}
