import 'dart:ui';
import 'package:flame/components.dart';

/// Suggested sightseeing paths and authored cat groups in an open field.
class HerdRoute {
  const HerdRoute(this.main, this.detour, this.groups);
  final List<Offset> main, detour, groups;
  Vector2 point(Offset p, Vector2 size) =>
      Vector2(p.dx * size.x, p.dy * size.y);

  static const market = HerdRoute(
    [
      Offset(.12, .28),
      Offset(.48, .28),
      Offset(.48, .63),
      Offset(.86, .63),
      Offset(.86, .28),
      Offset(.90, .28)
    ],
    [Offset(.70, .63), Offset(.70, .85), Offset(.84, .85)],
    [Offset(.27, .28), Offset(.48, .58), Offset(.77, .63), Offset(.84, .85)],
  );
  static const desert = HerdRoute(
    [
      Offset(.12, .28),
      Offset(.28, .28),
      Offset(.28, .68),
      Offset(.63, .68),
      Offset(.63, .28),
      Offset(.90, .28)
    ],
    [Offset(.63, .68), Offset(.84, .68), Offset(.84, .85)],
    [Offset(.25, .28), Offset(.28, .62), Offset(.58, .68), Offset(.84, .85)],
  );
  static const snow = HerdRoute(
    [
      Offset(.12, .28),
      Offset(.46, .28),
      Offset(.46, .68),
      Offset(.85, .68),
      Offset(.85, .28),
      Offset(.90, .28)
    ],
    [Offset(.68, .68), Offset(.68, .85)],
    [Offset(.25, .28), Offset(.46, .62), Offset(.78, .68), Offset(.68, .85)],
  );
  static const playground = HerdRoute(
    [
      Offset(.12, .28),
      Offset(.40, .28),
      Offset(.40, .70),
      Offset(.84, .70),
      Offset(.84, .28),
      Offset(.90, .28)
    ],
    [Offset(.64, .70), Offset(.64, .86)],
    [Offset(.26, .28), Offset(.40, .63), Offset(.76, .70), Offset(.64, .86)],
  );
}
