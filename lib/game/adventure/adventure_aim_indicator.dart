part of 'adventure_skills.dart';

// ===========================================================================
// Aim preview.
// ===========================================================================

/// World-space preview while a skill button is held, MOBA style: the big
/// range ring around the cat plus the exact shape the skill will hit. Turns
/// red when the cast would be wasted (e.g. blinking into water).
class AdventureAimIndicator extends Component {
  AdventureAimIndicator() : super(priority: 9);

  HomeAttack? attack;

  /// Cat center (range ring, self skills) and mouth (skill shots).
  Vector2 origin = Vector2.zero();
  Vector2 castFrom = Vector2.zero();
  Vector2 direction = Vector2(1, 0);
  Vector2 target = Vector2.zero();
  bool valid = true;

  /// Visible world rect, for screen-wide skills.
  Rect view = Rect.zero;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final attack = this.attack;
    if (attack == null) return;
    final color = valid ? attack.color : const Color(0xFFE0483F);
    final fill = Paint()..color = _a(color, .3);
    final edge = Paint()
      ..color = _a(Color.lerp(color, const Color(0xFFFFFFFF), .55)!, .95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final o = Offset(origin.x, origin.y);
    if (attack.shape != AimShape.self && attack.shape != AimShape.global) {
      _rangeRing(canvas, o, attack.range);
    }
    switch (attack.shape) {
      case AimShape.line:
        final from = attack == HomeAttack.iceBridge ? origin : castFrom;
        final angle = atan2(direction.y, direction.x);
        canvas.save();
        canvas.translate(from.x, from.y);
        canvas.rotate(angle);
        final w = attack.radius;
        final lane = RRect.fromRectAndRadius(
            Rect.fromLTRB(0, -w, attack.range, w), Radius.circular(min(w, 10)));
        canvas.drawRRect(lane, fill);
        canvas.drawRRect(lane, edge);
        // Chevrons running along the lane.
        final chevron = Paint()
          ..color = _a(const Color(0xFFFFFFFF), .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        const step = 46.0;
        final shift = (_t * 90) % step;
        final h = min(w * .7, 9.0);
        for (var x = shift + 14; x < attack.range - 20; x += step) {
          canvas.drawPath(
              Path()
                ..moveTo(x - h * .7, -h)
                ..lineTo(x, 0)
                ..lineTo(x - h * .7, h),
              chevron);
        }
        // Arrow head at the end.
        final head = Path()
          ..moveTo(attack.range + 10, 0)
          ..lineTo(attack.range - 10, -w - 6)
          ..lineTo(attack.range - 10, w + 6)
          ..close();
        canvas.drawPath(head, Paint()..color = _a(color, .9));
        canvas.restore();
      case AimShape.cone:
        final angle = atan2(direction.y, direction.x);
        final rect = Rect.fromCircle(
            center: Offset(castFrom.x, castFrom.y), radius: attack.range);
        final cone = Path()
          ..moveTo(castFrom.x, castFrom.y)
          ..arcTo(rect, angle - attack.radius, attack.radius * 2, false)
          ..close();
        canvas.drawPath(cone, fill);
        canvas.drawPath(cone, edge);
        // Sweep line showing reach.
        final k = (_t * 1.4) % 1;
        canvas.drawArc(
            Rect.fromCircle(
                center: Offset(castFrom.x, castFrom.y),
                radius: attack.range * k),
            angle - attack.radius,
            attack.radius * 2,
            false,
            Paint()
              ..color = _a(const Color(0xFFFFFFFF), .6 * (1 - k))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case AimShape.area:
        final zone = groundEllipse(target, attack.radius);
        canvas.drawOval(zone, fill);
        canvas.drawOval(zone, edge);
        final pulse = (_t * 1.5) % 1;
        canvas.drawOval(
            groundEllipse(target, attack.radius * pulse),
            Paint()
              ..color = _a(const Color(0xFFFFFFFF), .5 * (1 - pulse))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        _crosshair(canvas, Offset(target.x, target.y), color);
        if (attack == HomeAttack.decoy) {
          // Where the copy will stand.
          final t = Offset(target.x, target.y);
          canvas.drawOval(Rect.fromCenter(center: t, width: 30, height: 12),
              Paint()..color = _a(color, .6));
          canvas.drawCircle(t + const Offset(0, -20), 12, edge);
          canvas.drawPath(
              Path()
                ..moveTo(t.dx - 10, t.dy - 26)
                ..lineTo(t.dx - 8, t.dy - 38)
                ..lineTo(t.dx - 2, t.dy - 31)
                ..moveTo(t.dx + 10, t.dy - 26)
                ..lineTo(t.dx + 8, t.dy - 38)
                ..lineTo(t.dx + 2, t.dy - 31),
              edge);
        }
      case AimShape.wall:
        final corners =
            AdventureStoneWall.footprint(target, direction, attack.radius);
        final wall = Path()..addPolygon(corners, true);
        canvas.drawPath(wall, Paint()..color = _a(color, .55));
        canvas.drawPath(wall, edge);
        // Arrow showing which way the wall faces.
        final t = Offset(target.x, target.y);
        final d = Offset(direction.x, direction.y);
        canvas.drawLine(
            o,
            t - d * 16,
            Paint()
              ..color = _a(const Color(0xFFFFFFFF), .5)
              ..strokeWidth = 2);
      case AimShape.blink:
        final t = Offset(target.x, target.y);
        final dash = Paint()
          ..color = _a(const Color(0xFFFFFFFF), .8)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        final d = t - o;
        final length = d.distance;
        if (length > 1) {
          final dir = d / length;
          for (var x = (_t * 60) % 18; x < length - 18; x += 18) {
            canvas.drawLine(o + dir * x, o + dir * min(x + 8, length), dash);
          }
        }
        canvas.drawOval(
            Rect.fromCenter(
                center: t,
                width: attack.radius * 2.4,
                height: attack.radius * 1.2),
            fill);
        canvas.drawOval(
            Rect.fromCenter(
                center: t,
                width: attack.radius * 2.4,
                height: attack.radius * 1.2),
            edge);
        _crosshair(canvas, t, color);
        if (!valid) {
          final x = Paint()
            ..color = const Color(0xFFFFFFFF)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
              t + const Offset(-8, -30), t + const Offset(8, -14), x);
          canvas.drawLine(
              t + const Offset(8, -30), t + const Offset(-8, -14), x);
        }
      case AimShape.self:
        final pulse = 1 + sin(_t * 6) * .02;
        canvas.drawCircle(o, attack.radius * pulse, fill);
        canvas.drawCircle(o, attack.radius * pulse, edge);
      case AimShape.global:
        canvas.drawRect(view, Paint()..color = _a(color, .16));
        canvas.drawRect(
            view.deflate(4),
            Paint()
              ..color = _a(color, .8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6);
        canvas.drawCircle(o, 46, edge);
        for (var i = 0; i < 12; i++) {
          final a = i * pi / 6;
          canvas.drawLine(o + Offset(cos(a), sin(a)) * 38,
              o + Offset(cos(a), sin(a)) * 46, edge);
        }
        final hand = _t * 2;
        canvas.drawLine(o, o + Offset(cos(hand), sin(hand)) * 32, edge);
    }
  }

  void _rangeRing(Canvas canvas, Offset c, double range) {
    canvas.drawCircle(c, range, Paint()..color = const Color(0x1AFFFFFF));
    canvas.drawCircle(
        c,
        range,
        Paint()
          ..color = const Color(0x99E8F6FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }

  void _crosshair(Canvas canvas, Offset c, Color color) {
    canvas.drawCircle(c, 5, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(
        c,
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
}
