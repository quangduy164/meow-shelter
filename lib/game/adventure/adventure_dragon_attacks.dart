part of 'adventure_dragon.dart';

// ===========================================================================
// Dragon attacks. Each runs on the dragon's clock (tick), so time stop
// freezes them in place.
// ===========================================================================

abstract class DragonAttack extends PositionComponent {
  DragonAttack({super.position, super.priority = 7});

  double t = 0;
  void tick(double dt) => t += dt;

  /// Still showing its warning (an interrupt cancels it).
  bool get warning;
  bool get done;

  /// Whether it hurts a cat with hitbox [box] this frame.
  bool hits(Rect box);
}

/// Ground target follows briefly, locks, then the same body lands on that mark.
class DragonDive extends DragonAttack {
  DragonDive(
      {required this.home,
      required this.road,
      required this.left,
      required this.barrierX,
      required Vector2 target})
      : spot = target.clone() {
    follow(target);
  }
  final Vector2 home, spot;
  final AdventureRoad road;
  final double left, barrierX;
  static const lockAt = .85, impactAt = 1.6, endAt = 2.8, radius = 52.0;
  bool impactNow = false;
  bool get airborne => t >= .45 && (t < impactAt || t >= 1.95);
  @override
  bool get warning => t < .45;
  @override
  bool get done => t >= endAt;
  void follow(Vector2 target) {
    if (t >= lockAt) return;
    spot.x = target.x.clamp(left + radius, barrierX - 55);
    final half = max(10.0, road.halfWidth(spot.x) - radius * .55);
    final c = road.centerY(spot.x);
    spot.y = target.y.clamp(c - half, c + half);
  }

  @override
  void tick(double dt) {
    final previous = t;
    super.tick(dt);
    impactNow = previous < impactAt && t >= impactAt;
  }

  Vector2 get groundOffset {
    if (t < .45) return Vector2.zero();
    if (t < impactAt) return (spot - home) * _smoothUnit((t - .45) / .9);
    if (t < 1.95) return spot - home;
    return (spot - home) * (1 - _smoothUnit((t - 1.95) / (endAt - 1.95)));
  }

  double get lift {
    if (t < .45) return 0;
    if (t < 1.15) return -165 * _smoothUnit((t - .45) / .45);
    if (t < impactAt) return -165 * (1 - _smoothUnit((t - 1.15) / .45));
    if (t >= 1.95) {
      return -75 * sin(pi * ((t - 1.95) / (endAt - 1.95)).clamp(0.0, 1.0));
    }
    return 0;
  }

  @override
  bool hits(Rect box) =>
      impactNow &&
      inGroundEllipse(Vector2(box.center.dx, box.center.dy), spot, radius,
          margin: 8);
  @override
  void render(Canvas canvas) {
    if (t < impactAt) {
      final zone = groundEllipse(spot, radius);
      canvas.drawOval(zone,
          Paint()..color = Color.fromRGBO(238, 64, 44, t < lockAt ? .18 : .38));
      canvas.drawOval(
          zone,
          Paint()
            ..color = const Color(0xFFED603F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = t < lockAt ? 2 : 4);
      final c = Offset(spot.x, spot.y);
      final pen = Paint()
        ..color = const Color(0xFFFFE3A1)
        ..strokeWidth = 2.5;
      canvas.drawLine(c - const Offset(10, 0), c + const Offset(10, 0), pen);
      canvas.drawLine(c - const Offset(0, 7), c + const Offset(0, 7), pen);
    } else if (t < 1.95) {
      final k = ((t - impactAt) / .35).clamp(0.0, 1.0);
      canvas.drawOval(
          groundEllipse(spot, radius * (1 + k)),
          Paint()
            ..color = const Color(0xFFFFCF85).withValues(alpha: 1 - k)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * (1 - k) + 1);
      for (var i = 0; i < 10; i++) {
        final a = i * pi / 5;
        canvas.drawCircle(
            Offset(spot.x + cos(a) * radius * k,
                spot.y + sin(a) * radius * k * .5 - 12 * k),
            3 * (1 - k) + 1,
            Paint()
              ..color =
                  const Color(0xFFC6A980).withValues(alpha: (1 - k) * .7));
      }
    }
  }
}

/// A hatchling's small, dodgeable shot flies toward a snapshot of its target.
class DragonEmber extends DragonAttack {
  DragonEmber({required Vector2 from, required Vector2 target})
      : from = from.clone(),
        destination = target.clone();
  final Vector2 from, destination;
  bool blocked = false;
  static const flight = .95;
  Vector2 get point =>
      from + (destination - from) * (t / flight).clamp(0.0, 1.0);
  @override
  bool get warning => false;
  @override
  bool get done => blocked || t > flight + .12;
  @override
  bool hits(Rect box) =>
      !done && box.inflate(9).contains(Offset(point.x, point.y));
  @override
  void render(Canvas canvas) {
    if (done) return;
    final p = point;
    final dir = destination - from;
    final n = dir.length2 > .01 ? dir.normalized() : Vector2(1, 0);
    canvas.drawLine(
        Offset(p.x - n.x * 21, p.y - n.y * 21),
        Offset(p.x, p.y),
        Paint()
          ..color = const Color(0x99F77F35)
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(
        Offset(p.x, p.y), 8, Paint()..color = const Color(0xFFE96334));
    canvas.drawCircle(Offset(p.x - 1, p.y - 1), 4.5,
        Paint()..color = const Color(0xFFFFE5A3));
  }
}

/// A band of fire across the lane, from the dragon's mouth to the arena edge.
/// Warns for [warn] seconds, then burns. A stone wall standing in the band
/// stops the flames at [blockedAt].
class DragonFlameLane extends DragonAttack {
  DragonFlameLane(
      {required this.laneY,
      required this.left,
      required this.right,
      required this.warn,
      this.sweepTo})
      : startY = laneY;

  final double startY;
  final double? sweepTo;
  double get burnDuration => sweepTo == null ? burn : 1.25;
  @override
  void tick(double dt) {
    super.tick(dt);
    if (sweepTo != null && t >= warn) {
      laneY = startY +
          (sweepTo! - startY) * ((t - warn) / burnDuration).clamp(0.0, 1.0);
    }
  }

  double laneY;
  final double left, warn;
  double right;
  Vector2? emitter;
  static const double halfHeight = 24;
  static const double burn = .7;

  /// World x where a wall stops the fire (flames only right of it).
  double? blockedAt;

  @override
  bool get warning => t < warn;
  bool get burning => t >= warn && t < warn + burnDuration;
  @override
  bool get done => t >= warn + burnDuration + .15;

  double get _from => max(left, blockedAt ?? left);
  double get _front =>
      right - (right - _from) * ((t - warn) / .12).clamp(0.0, 1.0);

  @override
  bool hits(Rect box) =>
      burning &&
      box.overlaps(
          Rect.fromLTRB(_front, laneY - halfHeight, right, laneY + halfHeight));

  @override
  void render(Canvas canvas) {
    final band =
        Rect.fromLTRB(left, laneY - halfHeight, right, laneY + halfHeight);
    if (warning) {
      if (sweepTo != null) {
        final zone = Rect.fromLTRB(left, min(startY, sweepTo!) - halfHeight,
            right, max(startY, sweepTo!) + halfHeight);
        canvas.drawRect(zone, Paint()..color = const Color(0x33FF5638));
        final x = left + (right - left) * .5;
        final arrow = Paint()
          ..color = const Color(0xDDFFF2CE)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final sign = (sweepTo! - startY).sign;
        canvas.drawPath(
            Path()
              ..moveTo(x, startY)
              ..lineTo(x, sweepTo!)
              ..moveTo(x - 7, sweepTo! - sign * 8)
              ..lineTo(x, sweepTo!)
              ..lineTo(x + 7, sweepTo! - sign * 8),
            arrow);
      }
      final k = t / warn;
      final pulse = .5 + .5 * sin(t * 26);
      canvas.drawRect(
          band,
          Paint()
            ..color = Color.fromARGB(
                (50 + 60 * k + 30 * pulse).round(), 0xFF, 0x3A, 0x2A));
      final edge = Paint()
        ..color = Color.fromARGB((160 + 90 * pulse).round(), 0xFF, 0x5A, 0x3A)
        ..strokeWidth = 2.5;
      canvas.drawLine(band.topLeft, band.topRight, edge);
      canvas.drawLine(band.bottomLeft, band.bottomRight, edge);
      // Fill sweeping from the mouth shows when it fires.
      canvas.drawRect(
          Rect.fromLTRB(
              right - (right - left) * k, band.top, right, band.bottom),
          Paint()..color = const Color(0x33FF2A1A));
      final chevron = Paint()
        ..color = const Color(0xCCFFF4DA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var x = right - 30 - (t * 160) % 60; x > left + 10; x -= 60) {
        canvas.drawPath(
            Path()
              ..moveTo(x + 8, laneY - 10)
              ..lineTo(x, laneY)
              ..lineTo(x + 8, laneY + 10),
            chevron);
      }
      return;
    }
    final e = t - warn;
    final fade =
        (e < burnDuration ? 1.0 : 1 - (e - burnDuration) / .15).clamp(0.0, 1.0);
    if (done || fade <= 0) return;
    final start = _front;
    final mouth = emitter ?? Vector2(right, laneY);
    final source = Offset(mouth.x, mouth.y);
    Color tint(int value) => Color(value).withAlpha((255 * fade).round());
    final length = max(1.0, source.dx - start);
    Offset center(double k) => Offset(source.dx - length * k,
        source.dy + (laneY - source.dy) * min(1.0, k * 6));
    Path jet(double thickness) {
      final path = Path()..moveTo(source.dx, source.dy);
      for (var i = 0; i <= 40; i++) {
        final k = i / 40;
        final c = center(k);
        final wave = sin(k * 32 - t * 35) * 2.8 + sin(k * 57 - t * 23) * 1.2;
        final width = (3 + 17 * min(1.0, k * 7) + wave) * thickness * fade;
        path.lineTo(c.dx, c.dy - width);
      }
      for (var i = 40; i >= 0; i--) {
        final k = i / 40;
        final c = center(k);
        final wave = sin(k * 37 - t * 31 + 1.4) * 3;
        final width = (3 + 17 * min(1.0, k * 7) + wave) * thickness * fade;
        path.lineTo(c.dx, c.dy + width);
      }
      return path..close();
    }

    // One continuous stream from the jaw, with layers moving toward the target.
    canvas.drawPath(
        jet(1.25),
        Paint()
          ..color = const Color(0x66FF5A20).withAlpha((90 * fade).round()));
    canvas.drawPath(
        jet(1),
        Paint()
          ..shader = LinearGradient(
            colors: [tint(0xFFFFE67A), tint(0xFFFFA12A), tint(0xFFE9451B)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ).createShader(Rect.fromLTRB(
              start, laneY - halfHeight, right + 1, laneY + halfHeight)));
    canvas.drawPath(jet(.56),
        Paint()..color = Color.fromARGB((240 * fade).round(), 255, 201, 69));
    canvas.drawPath(jet(.23),
        Paint()..color = Color.fromARGB((250 * fade).round(), 255, 247, 203));
    for (var i = 0; i < 12; i++) {
      final k = (t * 1.9 + i / 12) % 1;
      final c = center(k);
      final side = sin(i * 2.4 + t * 8) * (5 + k * 11);
      canvas.drawOval(
          Rect.fromCenter(
              center: c + Offset(0, side),
              width: 15 + 12 * k,
              height: 3 + 4 * k),
          Paint()
            ..color = Color.fromARGB(
                (120 * fade * (1 - k * .6)).round(), 255, 239, 135));
    }
    if (blockedAt != null && blockedAt! > left && start <= _from + 1) {
      for (var i = 0; i < 7; i++) {
        final k = (t * 3 + i / 7) % 1;
        canvas.drawCircle(
            Offset(_from + sin(i * 2.3) * k * 20, laneY - k * 40),
            2.5 * (1 - k) + 1,
            Paint()
              ..color =
                  Color.fromARGB((220 * (1 - k) * fade).round(), 255, 221, 96));
      }
    }
  }
}

void _tongue(Canvas canvas, Offset base, double h, double w, double alpha) {
  if (h <= 1) return;
  Path p(double ww, double hh) => Path()
    ..moveTo(base.dx - ww, base.dy)
    ..quadraticBezierTo(base.dx - ww, base.dy - hh * .6, base.dx, base.dy - hh)
    ..quadraticBezierTo(base.dx + ww, base.dy - hh * .6, base.dx + ww, base.dy)
    ..close();
  canvas.drawPath(p(w, h * 2),
      Paint()..color = Color.fromARGB((220 * alpha).round(), 0xF0, 0x58, 0x2A));
  canvas.drawPath(p(w * .65, h * 1.4),
      Paint()..color = Color.fromARGB((235 * alpha).round(), 0xFF, 0xB1, 0x3A));
  canvas.drawPath(p(w * .3, h * .8),
      Paint()..color = Color.fromARGB((255 * alpha).round(), 0xFF, 0xF2, 0xB0));
}

/// A fireball lobbed onto [target]: its ground shadow grows for [flight]
/// seconds, then it bursts. A stone wall next to the spot catches it.
class DragonMeteor extends DragonAttack {
  DragonMeteor(
      {required Vector2 from, required this.target, required this.flight})
      : _from = from.clone(),
        super(position: target.clone(), priority: 8);

  final Vector2 _from;
  final Vector2 target;
  final double flight;
  static const double radius = 36;
  bool blocked = false;
  bool impactNow = false;

  @override
  void tick(double dt) {
    final before = t;
    super.tick(dt);
    impactNow = before < flight && t >= flight;
  }

  @override
  bool get warning => t < flight;
  @override
  bool get done => t >= flight + .4;

  @override
  bool hits(Rect box) =>
      impactNow &&
      !blocked &&
      inGroundEllipse(Vector2(box.center.dx, box.center.dy), target, radius,
          margin: 10);

  @override
  void render(Canvas canvas) {
    final zone = groundEllipse(Vector2.zero(), radius);
    if (t < flight) {
      final k = t / flight;
      canvas.drawOval(
          zone,
          Paint()
            ..color = Color.fromARGB((40 + 90 * k).round(), 0xE0, 0x30, 0x20));
      canvas.drawOval(
          zone,
          Paint()
            ..color = const Color(0xDDFF5A3A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.drawOval(groundEllipse(Vector2.zero(), radius * k),
          Paint()..color = const Color(0x55801010));
      Offset point(double progress) {
        final ground = (_from + (target - _from) * progress) - target;
        return Offset(ground.x, ground.y - sin(pi * progress) * 90);
      }

      final p = point(k);
      final samples =
          List.generate(10, (i) => point(max(0.0, k - (9 - i) * .016)));
      final ribbon = Path();
      for (var i = 0; i < samples.length; i++) {
        final tangent = samples[min(i + 1, 9)] - samples[max(0, i - 1)];
        final len = tangent.distance;
        final normal = len > .001
            ? Offset(-tangent.dy, tangent.dx) / len
            : const Offset(0, 1);
        final edge = samples[i] + normal * (i / 9 * 12);
        if (i == 0) {
          ribbon.moveTo(edge.dx, edge.dy);
        } else {
          ribbon.lineTo(edge.dx, edge.dy);
        }
      }
      for (var i = 9; i >= 0; i--) {
        final tangent = samples[min(i + 1, 9)] - samples[max(0, i - 1)];
        final len = tangent.distance;
        final normal = len > .001
            ? Offset(-tangent.dy, tangent.dx) / len
            : const Offset(0, 1);
        final edge = samples[i] - normal * (i / 9 * 12);
        ribbon.lineTo(edge.dx, edge.dy);
      }
      ribbon.close();
      canvas.drawPath(ribbon, Paint()..color = const Color(0xDDFF8B25));
      // Hot core and soft halo travel along the same arc as the tail.
      canvas.drawCircle(
          p,
          25,
          Paint()
            ..shader = const RadialGradient(
                    colors: [Color(0x99FFB13A), Color(0x00FF6A20)])
                .createShader(Rect.fromCircle(center: p, radius: 25)));
      canvas.drawCircle(
          p,
          14,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.3, -.3),
              colors: [
                Color(0xFFFFF6CC),
                Color(0xFFFFD45C),
                Color(0xFFFF872A),
                Color(0xFFD93920)
              ],
              stops: [0, .3, .65, 1],
            ).createShader(Rect.fromCircle(center: p, radius: 14)));
      for (var i = 1; i < 6; i++) {
        final progress = max(0.0, k - i * .028);
        if (progress == 0) continue;
        final q = point(progress) +
            Offset(sin(i * 4.2 + t * 12) * 5, cos(i * 2.7 + t * 8) * 5);
        canvas.drawCircle(q, 1.2 + (6 - i) * .3,
            Paint()..color = Color.fromARGB(200 - i * 25, 255, 220, 106));
      }
      return;
    }
    if (done) return;
    final e = ((t - flight) / .4).clamp(0.0, 1.0);
    final fade = 1 - e;
    canvas.drawOval(
        zone.inflate(14 * e),
        Paint()
          ..color = Color.fromARGB((210 * fade).round(), 0xFF, 0x9A, 0x3A));
    canvas.drawOval(
        zone.inflate(26 * e),
        Paint()
          ..color = Color.fromARGB((255 * fade).round(), 0xFF, 0xF4, 0xDA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    for (var i = 0; i < 5; i++) {
      final a = i * 1.26;
      _tongue(canvas, Offset(cos(a) * radius * .5, sin(a) * radius * .3 + 6),
          14 * fade, 7, fade);
    }
  }
}

/// The tail swings across the lane in front of the dragon. Warns with a red
/// zone, then turns counterclockwise, sweeping down its left side.
class DragonTailSweep extends DragonAttack {
  DragonTailSweep({
    required this.road,
    required this.left,
    required this.right,
    required this.root,
    required this.warn,
    this.visualScale = 1,
    this.restClock = 0,
  });

  final AdventureRoad road;
  final double left, right, warn, visualScale;
  final Vector2 root;
  double restClock;
  double bulk = 0;
  static const double sweep = .7;
  static const double recovery = .55;

  @override
  bool get warning => t < warn;
  bool get sweeping => t >= warn && t < warn + sweep;
  @override
  bool get done => t >= warn + sweep + recovery;

  double get _strike => _smoothUnit((t - warn) / sweep);
  double get _recover => _smoothUnit((t - warn - sweep) / recovery);
  double get bodyTurn => warning
      ? -.22 * _smoothUnit(t / warn)
      : sweeping
          ? -.22 + .56 * _strike
          : .34 * (1 - _recover);
  Offset get bodyShift => warning
      ? const Offset(8, 6) * _smoothUnit(t / warn)
      : sweeping
          ? Offset(8 - 20 * _strike, 6 - 6 * _strike)
          : const Offset(-12, 0) * (1 - _recover);
  double get crouch => warning
      ? 6 * _smoothUnit(t / warn)
      : sweeping
          ? 6 * (1 - _strike)
          : 0;
  double get wingSpread => warning
      ? .7 * _smoothUnit(t / warn)
      : sweeping
          ? .7 + .3 * sin(_strike * pi)
          : .7 * (1 - _recover);

  /// One complete turn: left-facing, right-facing, then left-facing again.
  double get bodyYaw => warning
      ? -.28 * _smoothUnit(t / warn)
      : sweeping
          ? -.28 - 2 * pi * _strike
          : -2 * pi - .28 * (1 - _recover);

  List<Offset>? posedCenterline;
  List<Offset> get localCenterline =>
      _dragonTailPoints(const Offset(62, -32), 1, restClock,
          attackTime: t, warn: warn);
  List<Offset> get centerline =>
      posedCenterline ??
      _dragonTailPoints(Offset(root.x, root.y), visualScale, restClock,
          attackTime: t, warn: warn);

  Rect get _zone {
    final mid = (left + right) / 2;
    final half = road.halfWidth(mid) + 14;
    final c = road.centerY(mid);
    return Rect.fromLTRB(left, c - half, right, c + half);
  }

  @override
  bool hits(Rect box) {
    if (!sweeping || !box.overlaps(_zone)) return false;
    final points = centerline;
    for (var i = 0; i < points.length - 1; i++) {
      final radius =
          ((15 + 6 * bulk) * (1 - i / (points.length - 1)) + 2) * visualScale;
      if (_tailSegmentHits(points[i], points[i + 1], box.inflate(radius))) {
        return true;
      }
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    final zone = _zone;
    if (warning) {
      final k = t / warn;
      final pulse = .5 + .5 * sin(t * 24);
      final r = RRect.fromRectAndRadius(zone, const Radius.circular(18));
      canvas.drawRRect(
          r,
          Paint()
            ..color = Color.fromARGB(
                (40 + 60 * k + 30 * pulse).round(), 0xFF, 0x3A, 0x2A));
      canvas.drawRRect(
          r,
          Paint()
            ..color =
                Color.fromARGB((170 + 80 * pulse).round(), 0xFF, 0x5A, 0x3A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      // Follow the counterclockwise turn down the dragon's left side.
      final arrow = Paint()
        ..color = const Color(0xCCFFF4DA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final c = zone.center;
      const startAngle = -pi * .55;
      const sweepAngle = -pi * .9;
      const endAngle = startAngle + sweepAngle;
      canvas.drawArc(
          Rect.fromCenter(
              center: c, width: zone.width * .7, height: zone.height * .8),
          startAngle,
          sweepAngle,
          false,
          arrow);
      final end = c +
          Offset(cos(endAngle) * zone.width * .35,
              sin(endAngle) * zone.height * .4);
      final tangent = Vector2(
          sin(endAngle) * zone.width * .35, -cos(endAngle) * zone.height * .4)
        ..normalize();
      final back = Offset(tangent.x, tangent.y) * -12;
      final side = Offset(-tangent.y, tangent.x) * 6;
      canvas.drawLine(end, end + back + side, arrow);
      canvas.drawLine(end, end + back - side, arrow);
      return;
    }
    // Only wind streaks and ground dust live here. The dragon draws its own
    // attached, tapered tail from this same centerline and attack clock.
    if (done) return;
    final fade = sweeping ? 1.0 : 1 - _recover;
    if (sweeping) {
      final points = centerline;
      final streak = Path();
      for (var i = 12; i < points.length; i++) {
        final p = points[i] + const Offset(8, -6);
        if (i == 12) {
          streak.moveTo(p.dx, p.dy);
        } else {
          streak.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
          streak,
          Paint()
            ..color = const Color(0x88FFF4DA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * visualScale
            ..strokeCap = StrokeCap.round);
    }
    final tip = centerline.last;
    for (var i = 0; i < 5; i++) {
      final p = tip + Offset((i - 2) * 7.0, 12 + sin(i * 2 + t * 7) * 4);
      canvas.drawCircle(p, (3 + i % 3) * visualScale,
          Paint()..color = Color.fromARGB((90 * fade).round(), 216, 200, 164));
    }
  }
}

/// A damage number floating up from where the dragon was hit.
class AdventureDamageText extends PositionComponent {
  AdventureDamageText(
      {required Vector2 position,
      required this.text,
      this.color = const Color(0xFFFFF4DA)})
      : super(position: position, priority: 10);

  final String text;
  final Color color;
  double _t = 0;
  static const double _life = .75;
  TextPainter? _painter;

  @override
  void onRemove() {
    _painter?.dispose();
    _painter = null;
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= 40 * dt;
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = (1 - _t / _life).clamp(0.0, 1.0);
    // Laid out once; the fade is a small layer sized to the text instead of
    // re-laying out the text with a new colour every frame.
    final painter = _painter ??= TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: DS.fontHeading,
          fontWeight: FontWeight.w900,
          color: color,
          shadows: const [Shadow(color: Color(0xFF4A1E14), blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final at = Offset(-painter.width / 2, -painter.height / 2);
    canvas.saveLayer((at & painter.size).inflate(6),
        Paint()..color = Color.fromARGB((255 * fade).round(), 255, 255, 255));
    painter.paint(canvas, at);
    canvas.restore();
  }
}
