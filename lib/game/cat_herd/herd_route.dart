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
      Offset(.33, .44),
      Offset(.555, .355),
      Offset(.33, .44),
      Offset(.27, .34),
      Offset(.20, .58),
      Offset(.42, .72),
      Offset(.19, .78),
      Offset(.21, .885),
      Offset(.62, .885),
      Offset(.82, .79),
      Offset(.905, .70),
      Offset(.905, .33),
      Offset(.90, .28)
    ],
    [],
    [Offset(.27, .34), Offset(.555, .355), Offset(.42, .72), Offset(.82, .79)],
  );
  static const farm = HerdRoute(
    [
      Offset(.05, .60),
      Offset(.24, .82),
      Offset(.06, .42),
      Offset(.26, .53),
      Offset(.26, .38),
      Offset(.26, .30),
      Offset(.26, .53),
      Offset(.06, .42),
      Offset(.20, .66),
      Offset(.37, .74),
      Offset(.37, .86),
      Offset(.41, .58),
      Offset(.55, .60),
      Offset(.55, .74),
      Offset(.55, .83),
      Offset(.55, .60),
      Offset(.41, .62),
      Offset(.37, .74),
      Offset(.70, .60),
      Offset(.86, .74),
      Offset(.63, .55),
      Offset(.63, .38),
      Offset(.90, .28)
    ],
    [],
    [Offset(.24, .82), Offset(.26, .30), Offset(.55, .83), Offset(.86, .74)],
  );
  static const station = HerdRoute(
    [
      Offset(.06, .33),
      Offset(.18, .33),
      Offset(.22, .42),
      Offset(.22, .54),
      Offset(.22, .67),
      Offset(.24, .82),
      Offset(.72, .80),
      Offset(.78, .67),
      Offset(.78, .54),
      Offset(.78, .41),
      Offset(.68, .32),
      Offset(.90, .28)
    ],
    [],
    [Offset(.18, .33), Offset(.24, .82), Offset(.72, .80), Offset(.68, .32)],
  );
  static const grandma = HerdRoute(
    [
      Offset(.07, .50),
      Offset(.18, .42),
      Offset(.30, .37),
      Offset(.42, .365),
      Offset(.53, .28),
      Offset(.55, .83),
      Offset(.625, .72),
      Offset(.625, .45),
      Offset(.635, .34),
      Offset(.72, .34),
      Offset(.84, .47),
      Offset(.84, .66),
      Offset(.88, .78),
      Offset(.84, .62),
      Offset(.84, .47),
      Offset(.88, .33)
    ],
    [],
    [Offset(.18, .42), Offset(.53, .28), Offset(.55, .83), Offset(.88, .78)],
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
