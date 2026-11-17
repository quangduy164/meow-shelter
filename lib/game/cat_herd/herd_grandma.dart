import 'dart:ui';

/// Grandma's house: room layout and timing shared by rules and painters.
/// Rects are fractions of the playable viewport, like every HerdMap.
abstract final class HerdHouse {
  /// Interior walls; gaps are the big doors and the cat flaps.
  static const walls = [
    // Living room | bedroom (flap high, big door low).
    Rect.fromLTWH(.36, .17, .025, .13),
    Rect.fromLTWH(.36, .43, .025, .19),
    Rect.fromLTWH(.36, .78, .025, .22),
    // Bedroom | right wing (big door high, flap low into the kitchen).
    Rect.fromLTWH(.66, .17, .025, .09),
    Rect.fromLTWH(.66, .42, .025, .28),
    Rect.fromLTWH(.66, .83, .025, .17),
    // Fireplace room above, kitchen below.
    Rect.fromLTWH(.685, .555, .095, .03),
    Rect.fromLTWH(.90, .555, .10, .03),
  ];

  /// Narrow flaps: normal cats pass, Bé Mập gets stuck.
  static const flaps = [
    Rect.fromLTWH(.355, .30, .035, .13),
    Rect.fromLTWH(.655, .70, .035, .13),
  ];

  static const sofa = Rect.fromLTWH(.05, .19, .18, .075);
  static const clock = Rect.fromLTWH(.29, .18, .05, .12);
  static const coffeeTable = Rect.fromLTWH(.15, .60, .08, .09);
  static const wardrobe = Rect.fromLTWH(.40, .18, .06, .12);
  static const bed = Rect.fromLTWH(.39, .79, .075, .16);
  static const kitchenTable = Rect.fromLTWH(.73, .85, .07, .09);
  static const fridge = Rect.fromLTWH(.94, .62, .045, .14);
  static const furniture = [
    sofa,
    clock,
    coffeeTable,
    wardrobe,
    bed,
    kitchenTable,
    fridge
  ];

  /// Yarn in the fireplace room, fish dish beside the kitchen door.
  static const yarn = Offset(.75, .38), fishDish = Offset(.72, .66);

  /// Robot vacuum circuit in the bedroom.
  static const robotLoop = Rect.fromLTWH(.44, .47, .13, .15);

  /// The cuckoo wakes every sleeping cat in the living room.
  static const livingRoom = Rect.fromLTWH(0, .17, .36, .83);

  /// Rooms for floor art.
  static const bedroom = Rect.fromLTWH(.385, .17, .275, .83);
  static const fireRoom = Rect.fromLTWH(.685, .17, .315, .385);
  static const kitchen = Rect.fromLTWH(.685, .585, .315, .415);
}

/// Curious followers this close to a lure run to it.
abstract final class HerdLure {
  static const radius = 50.0;
}

abstract final class HerdCuckoo {
  static const period = 15.0, ringSeconds = 1.8, offset = 9.0;
  static double _cycle(double t) => (t + offset) % period;
  static bool ringing(double t) => _cycle(t) < ringSeconds;

  /// Ring number, used to wake cats once per ring.
  static int number(double t) => ((t + offset) / period).floor();
}

/// Robot vacuum driving clockwise around a rectangle at constant speed.
abstract final class HerdRobot {
  static const lapSeconds = 7.0, radius = 16.0;

  static Offset at(Rect loop, double t) {
    final perimeter = 2 * (loop.width + loop.height);
    var d = (t / lapSeconds % 1) * perimeter;
    if (d < loop.width) return Offset(loop.left + d, loop.top);
    d -= loop.width;
    if (d < loop.height) return Offset(loop.right, loop.top + d);
    d -= loop.height;
    if (d < loop.width) return Offset(loop.right - d, loop.bottom);
    d -= loop.width;
    return Offset(loop.left, loop.bottom - d);
  }

  /// Unit heading, for drawing the bumper in front.
  static Offset heading(Rect loop, double t) {
    final a = at(loop, t), b = at(loop, t + .05);
    final d = b - a;
    return d.distance < .001 ? const Offset(1, 0) : d / d.distance;
  }

  static double distanceToLoop(Rect loop, Offset p) {
    final inside = loop.contains(p);
    final dx = p.dx < loop.left
        ? loop.left - p.dx
        : (p.dx > loop.right ? p.dx - loop.right : 0.0);
    final dy = p.dy < loop.top
        ? loop.top - p.dy
        : (p.dy > loop.bottom ? p.dy - loop.bottom : 0.0);
    if (!inside) return Offset(dx, dy).distance;
    return [
      p.dx - loop.left,
      loop.right - p.dx,
      p.dy - loop.top,
      loop.bottom - p.dy
    ].reduce((a, b) => a < b ? a : b);
  }
}
