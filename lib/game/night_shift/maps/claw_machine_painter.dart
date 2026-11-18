import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../../components/fish_item_component.dart';
import '../../text_cache.dart';
import '../static_layer.dart';
import 'claw_machine.dart';
import 'claw_machine_scene.dart';

const _ink = Color(0xFF2A1830);
Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Arcade room and the machine cabinet; drawn once into an image.
class ClawRoomBackground extends PositionComponent with HasGameReference {
  ClawRoomBackground() : super(priority: -100);
  final _layer = StaticLayer();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layer.clear();
  }

  @override
  void onRemove() {
    _layer.clear();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final s = game.size.toSize();
    _layer.draw(canvas, s, (c) => _paint(c, s));
  }

  static void _paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, h),
              const [Color(0xFF241536), Color(0xFF3A2148), Color(0xFF1C1228)],
              const [0, .7, 1]));
    // Neon strips along the arcade wall.
    for (final (y, color) in const [
      (.07, Color(0xFFFF7BC3)),
      (.105, Color(0xFF6FE3FF)),
    ]) {
      c.drawLine(Offset(0, h * y), Offset(w, h * y),
          _stroke(color.withValues(alpha: .25), 9));
      c.drawLine(Offset(0, h * y), Offset(w, h * y), _stroke(color, 2.5));
    }
    // Floor tiles in front of the machine.
    c.drawRect(Rect.fromLTWH(0, h * .88, w, h * .12),
        Paint()..color = const Color(0xFF2B1D35));
    for (var x = 0.0; x < w; x += 40) {
      c.drawLine(Offset(x, h * .88), Offset(x - 20, h),
          _stroke(const Color(0x33FFFFFF), 1));
    }
    // Cabinet.
    final cabinet = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .01, h * .15, w * .98, h * .75),
        const Radius.circular(18));
    c.drawRRect(cabinet.shift(const Offset(0, 6)),
        Paint()..color = const Color(0x66000000));
    c.drawRRect(
        cabinet,
        Paint()
          ..shader = ui.Gradient.linear(
              cabinet.outerRect.topCenter,
              cabinet.outerRect.bottomCenter,
              const [Color(0xFFE85D8F), Color(0xFFB83A6E)]));
    c.drawRRect(cabinet, _stroke(_ink, 3));
    for (var x = cabinet.left + 16; x < cabinet.right - 10; x += 22) {
      c.drawCircle(Offset(x, cabinet.top + 8), 3.2,
          Paint()..color = const Color(0xFFFFE9A8));
    }
    // Glass tank.
    final tank = Rect.fromLTRB(w * (ClawMachine.tankLeft - .02), h * .2,
        w * (ClawMachine.tankRight + .02), h * ClawMachine.floorY + _padDepth);
    c.drawRect(
        tank,
        Paint()
          ..shader = ui.Gradient.linear(tank.topCenter, tank.bottomCenter,
              const [Color(0xFF2A3E63), Color(0xFF3B5578)]));
    // Quilted cushion the cats walk on: soft top roll plus tufted buttons.
    final top = h * ClawMachine.floorY - 3;
    final pad = Rect.fromLTRB(tank.left, top, tank.right, tank.bottom);
    c.drawRect(
        pad,
        Paint()
          ..shader = ui.Gradient.linear(pad.topCenter, pad.bottomCenter,
              const [Color(0xFFF6B7CF), Color(0xFFD9799F)]));
    final seam = _stroke(const Color(0x66A84B74), 1.4);
    final cell = pad.height * 1.1;
    for (var x = pad.left + cell / 2; x < pad.right; x += cell) {
      c.drawLine(Offset(x, top + 4), Offset(x, pad.bottom - 2), seam);
      c.drawCircle(Offset(x, pad.center.dy + 2), 2.2,
          Paint()..color = const Color(0xFFB45A82));
      c.drawCircle(Offset(x - .6, pad.center.dy + 1.4), .9,
          Paint()..color = const Color(0x99FFFFFF));
    }
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(pad.left, top - 4, pad.right, top + 5),
            const Radius.circular(5)),
        Paint()..color = const Color(0xFFFFD3E2));
    c.drawLine(Offset(pad.left + 6, top - 1), Offset(pad.right - 6, top - 1),
        _stroke(const Color(0xAAFFFFFF), 1.5));
    // Back-wall shadow so the cushion reads as the tank floor.
    c.drawRect(
        Rect.fromLTRB(tank.left, top - 26, tank.right, top - 4),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, top - 26), Offset(0, top - 4),
              const [Color(0x00141C30), Color(0x55141C30)]));
    // Glass glare.
    c.drawLine(
        Offset(tank.left + 18, tank.top + 10),
        Offset(tank.left + 50, tank.bottom - 20),
        _stroke(const Color(0x22FFFFFF), 14));
    c.drawRect(tank, _stroke(const Color(0xFFFFE9A8), 3));
    // Control deck below the tank.
    final deck = Rect.fromLTRB(cabinet.left + 8, tank.bottom + 4,
        cabinet.right - 8, cabinet.bottom - 6);
    c.drawRRect(RRect.fromRectAndRadius(deck, const Radius.circular(10)),
        Paint()..color = const Color(0xFF7C2A55));
  }
}

/// Depth of the cushion below [ClawMachine.floorY], in pixels.
const _padDepth = 18.0;

/// Prize chutes: a glass box with a funnel on top; one or two by variant.
class ClawChutes extends PositionComponent with HasGameReference {
  ClawChutes(this.machine) : super(priority: 60);
  final ClawMachine machine;
  double _clock = 0;
  @override
  void update(double dt) => _clock += dt;

  @override
  void render(Canvas canvas) {
    final s = game.size;
    final glow = .5 + math.sin(_clock * 3) * .2;
    for (final x in [
      machine.chuteLeft,
      if (machine.twinChutes) machine.chuteRight
    ]) {
      final box = clawChuteBox(x, s);
      canvas.drawRRect(
          RRect.fromRectAndRadius(box.inflate(8), const Radius.circular(14)),
          Paint()
            ..color = Color.fromRGBO(140, 220, 255, glow * .28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      // Funnel the claw drops into.
      final funnel = Path()
        ..moveTo(box.left - 7, box.top - 12)
        ..lineTo(box.right + 7, box.top - 12)
        ..lineTo(box.right - 3, box.top + 2)
        ..lineTo(box.left + 3, box.top + 2)
        ..close();
      canvas.drawPath(funnel, Paint()..color = const Color(0xFF9AA6B6));
      canvas.drawPath(funnel, _stroke(_ink, 2));
      canvas.drawLine(
          Offset(box.left - 3, box.top - 9),
          Offset(box.right + 3, box.top - 9),
          _stroke(const Color(0xFFE4E9F0), 2));
      // Inside: dark back with a little cushion for the cat to land on.
      final inside = RRect.fromRectAndRadius(box, const Radius.circular(6));
      canvas.drawRRect(
          inside,
          Paint()
            ..shader = ui.Gradient.linear(box.topCenter, box.bottomCenter,
                const [Color(0xFF1E2B45), Color(0xFF2E4064)]));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(
                  box.left + 3, box.bottom - 10, box.right - 3, box.bottom - 2),
              const Radius.circular(4)),
          Paint()..color = const Color(0xFFF2A9C6));
    }
  }
}

/// Glass pane, frame and base of each chute, drawn over a landed cat.
void paintChuteFronts(Canvas canvas, Vector2 s, ClawMachine machine) {
  for (final x in [
    machine.chuteLeft,
    if (machine.twinChutes) machine.chuteRight
  ]) {
    final box = clawChuteBox(x, s);
    final glass = RRect.fromRectAndRadius(box, const Radius.circular(6));
    canvas.drawRRect(glass, Paint()..color = const Color(0x2E9FE3FF));
    canvas.save();
    canvas.clipRRect(glass);
    final shine = _stroke(const Color(0x40FFFFFF), 7);
    canvas.drawLine(Offset(box.left + box.width * .2, box.bottom),
        Offset(box.left + box.width * .55, box.top), shine);
    canvas.drawLine(
        Offset(box.left + box.width * .5, box.bottom),
        Offset(box.left + box.width * .75, box.top),
        _stroke(const Color(0x26FFFFFF), 3));
    canvas.restore();
    canvas.drawRRect(glass, _stroke(_ink, 3.5));
    canvas.drawRRect(glass, _stroke(const Color(0xFFC9D2DE), 2));
    // Metal base with a soft indicator light.
    final base = RRect.fromRectAndRadius(
        Rect.fromLTRB(
            box.left - 4, box.bottom - 1, box.right + 4, box.bottom + 9),
        const Radius.circular(4));
    canvas.drawRRect(base, Paint()..color = const Color(0xFF7D8794));
    canvas.drawRRect(base, _stroke(_ink, 2));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(box.center.dx, box.bottom + 4),
                width: box.width * .45,
                height: 3.5),
            const Radius.circular(2)),
        Paint()..color = const Color(0xFF9DF0FF));
  }
}

/// Cushion front edge, drawn over the cats' paws so they sit in it.
void paintCushionLip(Canvas canvas, Vector2 s) {
  final y = s.y * ClawMachine.floorY;
  final lip = Rect.fromLTRB(s.x * (ClawMachine.tankLeft - .02) + 1.5, y + 3,
      s.x * (ClawMachine.tankRight + .02) - 1.5, y + _padDepth - 1.5);
  canvas.drawRect(
      lip,
      Paint()
        ..shader = ui.Gradient.linear(lip.topCenter, lip.bottomCenter,
            const [Color(0xFFF4AFCB), Color(0xFFCF6E96)]));
  canvas.drawLine(
      lip.topLeft, lip.topRight, _stroke(const Color(0xFFFFD9E6), 2));
}

/// Toys lying on the cushion, and any toy hanging in the claw.
class ClawPrizes extends PositionComponent with HasGameReference {
  ClawPrizes(this.scene) : super(priority: 61);
  final ClawMachineScene scene;

  @override
  void render(Canvas canvas) {
    final s = game.size;
    final m = scene.machine;
    final r = scene.catHeight * .2;
    for (final item in m.items) {
      final at = item.held
          ? scene.clawTip + Offset(0, r * .9)
          : Offset(s.x * item.x, s.y * ClawMachine.floorY - r * .75);
      paintClawPrize(canvas, item.kind, at, r);
    }
  }
}

/// One small toy centred on [c] with radius [r].
void paintClawPrize(Canvas canvas, ClawPrize kind, Offset c, double r) {
  final outline = _stroke(_ink, 2);
  switch (kind) {
    case ClawPrize.yarn:
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFF8FB1));
      final line = _stroke(const Color(0xFFD9577F), 1.4);
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * .7), -2.4, 2.2, false, line);
      canvas.drawArc(
          Rect.fromCircle(center: c + Offset(r * .2, 0), radius: r * .45),
          .5,
          2.4,
          false,
          line);
      canvas.drawLine(
          c + Offset(-r * .7, r * .2), c + Offset(r * .3, -r * .85), line);
      canvas.drawCircle(c, r, outline);
      canvas.drawPath(
          Path()
            ..moveTo(c.dx + r * .8, c.dy + r * .5)
            ..quadraticBezierTo(
                c.dx + r * 1.4, c.dy + r * 1.1, c.dx + r * 1.8, c.dy + r * .7),
          _stroke(const Color(0xFFD9577F), 1.6));
    case ClawPrize.mouse:
      final body = Rect.fromCenter(
          center: c + Offset(0, r * .2), width: r * 2.2, height: r * 1.5);
      canvas.drawPath(
          Path()
            ..moveTo(body.left, body.center.dy)
            ..quadraticBezierTo(body.left - r * .9, body.bottom + r * .3,
                body.left - r * 1.2, body.center.dy - r * .1),
          _stroke(const Color(0xFF8E8A99), 1.6));
      canvas.drawOval(body, Paint()..color = const Color(0xFFB9B5C4));
      canvas.drawOval(body, outline);
      final ear = c + Offset(r * .45, -r * .45);
      canvas.drawCircle(ear, r * .38, Paint()..color = const Color(0xFFFFB3C9));
      canvas.drawCircle(ear, r * .38, outline);
      canvas.drawCircle(
          c + Offset(r * .75, r * .05), r * .13, Paint()..color = _ink);
      canvas.drawCircle(body.centerRight - const Offset(1, 0), r * .14,
          Paint()..color = const Color(0xFFFF7FA6));
    case ClawPrize.can:
      final can = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: r * 2, height: r * 1.7),
          Radius.circular(r * .3));
      canvas.drawRRect(can, Paint()..color = const Color(0xFF5DB6E8));
      canvas.drawRect(Rect.fromCenter(center: c, width: r * 2, height: r * .8),
          Paint()..color = const Color(0xFFFFF1C9));
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(r / 22);
      drawFish(canvas, Offset.zero);
      canvas.restore();
      canvas.drawRRect(can, outline);
  }
}

/// Rail, carriage, cable and three-pronged claw. Drawn above the cats.
class ClawRig extends PositionComponent with HasGameReference {
  ClawRig(this.scene) : super(priority: 89);
  final ClawMachineScene scene;

  @override
  void render(Canvas canvas) {
    final s = game.size;
    final m = scene.machine;
    final railY = s.y * ClawMachine.railY;
    // The rail spans the chutes it serves, inside the cabinet.
    final railLeft = s.x * (m.chuteLeft - .045);
    final railRight =
        s.x * (m.twinChutes ? m.chuteRight + .02 : ClawMachine.tankRight + .03);
    // Steel beam with a lighter top face and bolt mounts at both ends.
    final beam = RRect.fromRectAndRadius(
        Rect.fromLTRB(railLeft, railY - 4, railRight, railY + 4),
        const Radius.circular(3));
    canvas.drawRRect(beam, Paint()..color = const Color(0xFF7D8794));
    canvas.drawRect(
        Rect.fromLTRB(railLeft + 3, railY - 3, railRight - 3, railY),
        Paint()..color = const Color(0xFFD6DBE2));
    canvas.drawRRect(beam, _stroke(_ink, 2));
    for (final x in [railLeft, railRight]) {
      final mount = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, railY), width: 12, height: 20),
          const Radius.circular(4));
      canvas.drawRRect(mount, Paint()..color = const Color(0xFF5B6470));
      canvas.drawRRect(mount, _stroke(_ink, 2));
      canvas.drawCircle(
          Offset(x, railY), 2.2, Paint()..color = const Color(0xFFD6DBE2));
    }
    final tip = scene.clawTip;
    final carriage = Offset(s.x * m.x, railY);
    // Trolley rides on top of the beam: wheels above, body hanging below.
    for (final dx in const [-9.0, 9.0]) {
      final wheel = carriage + Offset(dx, -5);
      canvas.drawCircle(wheel, 4.5, Paint()..color = const Color(0xFF3B3F48));
      canvas.drawCircle(wheel, 4.5, _stroke(_ink, 1.5));
    }
    final cart = RRect.fromRectAndRadius(
        Rect.fromLTRB(
            carriage.dx - 15, railY + 3, carriage.dx + 15, railY + 14),
        const Radius.circular(4));
    canvas.drawRRect(cart, Paint()..color = const Color(0xFFFFC24D));
    canvas.drawRRect(cart, _stroke(_ink, 2));
    canvas.drawLine(carriage + const Offset(0, 14), tip - const Offset(0, 18),
        _stroke(_ink, 3.5));
    canvas.drawLine(carriage + const Offset(0, 14), tip - const Offset(0, 18),
        _stroke(const Color(0xFFDDE2E8), 1.6));
    // Claw head.
    final head = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: tip - const Offset(0, 12), width: 26, height: 12),
        const Radius.circular(5));
    canvas.drawRRect(head, Paint()..color = const Color(0xFFB8C2CC));
    canvas.drawRRect(head, _stroke(_ink, 2));
    final closed = switch (m.phase) {
      ClawPhase.idle || ClawPhase.dropping => 0.0,
      ClawPhase.closing => 1 - m.timer / ClawMachine.closeSeconds,
      ClawPhase.releasing => m.timer / ClawMachine.releaseSeconds,
      _ => 1.0,
    }
        .clamp(0, 1)
        .toDouble();
    final spread = 18 - 10 * closed;
    final prong = _stroke(const Color(0xFFDDE2E8), 4);
    final edge = _stroke(_ink, 6.5);
    for (final dir in const [-1.0, 0.0, 1.0]) {
      final root = tip + Offset(dir * 8, -8);
      final knee = tip + Offset(dir * spread, 8);
      final end = tip + Offset(dir * (spread - 7 * closed) * .6, 20);
      for (final p in [edge, prong]) {
        canvas.drawPath(
            Path()
              ..moveTo(root.dx, root.dy)
              ..lineTo(knee.dx, knee.dy)
              ..lineTo(end.dx, end.dy),
            p..style = PaintingStyle.stroke);
      }
    }
    paintCushionLip(canvas, s);
    paintChuteFronts(canvas, s, m);
    if (m.fishX != null) {
      canvas.save();
      canvas.translate(s.x * m.fishX!, s.y * ClawMachine.floorY - 10);
      canvas.scale(.7);
      drawFish(canvas, Offset.zero);
      canvas.restore();
    }
  }
}

/// Mouth box of a prize chute, shared by the chute art and the scene.
Rect clawChuteBox(double x, Vector2 s) => Rect.fromCenter(
    center: Offset(s.x * x, s.y * .66), width: s.x * .1, height: s.y * .18);

/// Hold-to-move arrow button under the tank.
class ClawSteerButton extends PositionComponent
    with HasGameReference, TapCallbacks {
  ClawSteerButton(this.direction, {required this.onSteer})
      : super(size: Vector2.all(64), priority: 95);
  final int direction;
  final void Function(int direction, bool held) onSteer;
  bool _down = false;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(direction < 0 ? 12 : 84, size.y - this.size.y - 6);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _down = true;
    onSteer(direction, true);
  }

  @override
  void onTapUp(TapUpEvent event) => _release();
  @override
  void onTapCancel(TapCancelEvent event) => _release();
  void _release() {
    _down = false;
    onSteer(direction, false);
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2 - 3);
    final press = _down ? 3.0 : 0.0;
    canvas.drawCircle(
        c + const Offset(0, 5), 27, Paint()..color = const Color(0xFF1D3F66));
    canvas.drawCircle(
        c + Offset(0, press), 27, Paint()..color = const Color(0xFF4FA3E0));
    canvas.drawCircle(c + Offset(0, press), 27, _stroke(_ink, 3));
    canvas.drawCircle(c + Offset(-8, -10 + press), 7,
        Paint()..color = const Color(0x55FFFFFF));
    final d = direction.toDouble();
    final tip = c + Offset(d * 11, press);
    canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - d * 16, tip.dy - 12)
          ..lineTo(tip.dx - d * 16, tip.dy + 12)
          ..close(),
        Paint()..color = const Color(0xFFFFF4DA));
  }
}

/// Big arcade button that drops the claw.
class ClawDropButton extends PositionComponent
    with HasGameReference, TapCallbacks {
  ClawDropButton({required this.onDrop})
      : super(size: Vector2.all(84), priority: 95);
  final VoidCallback onDrop;
  bool _down = false;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - this.size.x - 14, size.y - this.size.y - 6);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _down = true;
    onDrop();
  }

  @override
  void onTapUp(TapUpEvent event) => _down = false;
  @override
  void onTapCancel(TapCancelEvent event) => _down = false;

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2 - 4);
    final press = _down ? 3.0 : 0.0;
    canvas.drawCircle(
        c + const Offset(0, 6), 34, Paint()..color = const Color(0xFF7A1F2E));
    canvas.drawCircle(
        c + Offset(0, press), 34, Paint()..color = const Color(0xFFE5484D));
    canvas.drawCircle(c + Offset(0, press), 34, _stroke(_ink, 3));
    canvas.drawCircle(c + Offset(-10, -12 + press), 9,
        Paint()..color = const Color(0x66FFFFFF));
    final label = TextCache.layout(
        'THẢ',
        const TextStyle(
            color: Color(0xFFFFF4DA),
            fontSize: 18,
            fontWeight: FontWeight.w900));
    label.paint(canvas,
        Offset(c.dx - label.width / 2, c.dy + press - label.height / 2));
  }
}
