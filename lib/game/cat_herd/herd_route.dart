import 'dart:ui';
import 'package:flame/components.dart';

/// Suggested sightseeing paths and authored cat groups in an open field.
class HerdRoute {
  const HerdRoute(this.main, this.detour, this.groups);
  final List<Offset> main, detour, groups;
  Vector2 point(Offset p, Vector2 size) =>
      Vector2(p.dx * size.x, p.dy * size.y);

  static const tutorial = HerdRoute(
    [
      Offset(.17, .50),
      Offset(.29, .32),
      Offset(.32, .60),
      Offset(.45, .72),
      Offset(.49, .39),
      Offset(.64, .32),
      Offset(.69, .64),
      Offset(.80, .74),
      Offset(.88, .30)
    ],
    [],
    [Offset(.29, .32), Offset(.45, .72), Offset(.64, .32), Offset(.80, .74)],
  );

  static const market = HerdRoute(
    [
      Offset(.08, .31),
      Offset(.26, .33),
      Offset(.58, .27),
      Offset(.45, .43),
      Offset(.45, .66),
      Offset(.28, .73),
      Offset(.72, .83),
      Offset(.90, .28)
    ],
    [Offset(.72, .83), Offset(.90, .70)],
    [Offset(.26, .33), Offset(.58, .27), Offset(.28, .73), Offset(.72, .83)],
  );
  static const desert = HerdRoute(
    [
      Offset(.08, .32),
      Offset(.28, .31),
      Offset(.23, .57),
      Offset(.44, .68),
      Offset(.65, .76),
      Offset(.84, .83),
      Offset(.84, .58),
      Offset(.90, .28)
    ],
    [Offset(.65, .30), Offset(.68, .62)],
    [Offset(.28, .31), Offset(.44, .68), Offset(.65, .76), Offset(.84, .83)],
  );
  static const snow = HerdRoute(
    [
      Offset(.08, .32),
      Offset(.27, .34),
      Offset(.37, .39),
      Offset(.56, .35),
      Offset(.74, .49),
      Offset(.40, .74),
      Offset(.82, .79),
      Offset(.90, .28)
    ],
    [Offset(.62, .88), Offset(.94, .88), Offset(.94, .56)],
    [Offset(.27, .34), Offset(.56, .35), Offset(.40, .74), Offset(.82, .79)],
  );
  static const playground = HerdRoute(
    [
      Offset(.08, .55),
      Offset(.29, .52),
      Offset(.29, .34),
      Offset(.29, .52),
      Offset(.64, .52),
      Offset(.64, .34),
      Offset(.82, .55),
      Offset(.72, .73),
      Offset(.90, .28)
    ],
    [Offset(.40, .57), Offset(.40, .79)],
    [Offset(.29, .34), Offset(.64, .34), Offset(.72, .76), Offset(.40, .79)],
  );
}
