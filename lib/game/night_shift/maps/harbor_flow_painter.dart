import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../moonlight.dart';
import '../moonlight_art.dart';
import '../../cats/cat_breed.dart';
import 'harbor_flow.dart';

Offset _px(Offset p, Vector2 size) => Offset(p.dx * size.x, p.dy * size.y);
const _ink = Color(0xFF3B2414);
const _wood = Color(0xFFB97B43);
const _woodDark = Color(0xFF7A4A27);
const _woodLight = Color(0xFFD9A066);

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

class HarborBackground extends PositionComponent with HasGameReference {
  HarborBackground(this.flow) : super(priority: -100);
  final HarborFlow flow;
  ui.Picture? _picture;
  Size _pictureSize = Size.zero;
  double _clock = 0;

  @override
  void update(double dt) => _clock += dt;

  @override
  void onRemove() {
    _picture?.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final s = game.size.toSize();
    if (s.isEmpty) return;
    if (_picture == null || _pictureSize != s) {
      _picture?.dispose();
      final recorder = ui.PictureRecorder();
      _paintStatic(Canvas(recorder), s);
      _picture = recorder.endRecording();
      _pictureSize = s;
    }
    canvas.drawPicture(_picture!);
    _paintFlow(canvas, s);
    _paintDocks(canvas, s);
    _paintRocks(canvas, s);
    if (flow.linked) {
      for (final x in HarborFlow.gateX) {
        final top = Offset(s.width * x, s.height * HarborFlow.laneY.first);
        final bottom = Offset(s.width * x, s.height * HarborFlow.laneY.last);
        canvas.drawLine(top, bottom, _stroke(const Color(0xFF6A4A2A), 4));
        for (var y = top.dy; y < bottom.dy; y += 9) {
          canvas.drawLine(Offset(top.dx - 2, y), Offset(top.dx + 2, y + 5),
              _stroke(const Color(0xFFD7B47A), 1.6));
        }
      }
    }
  }

  Rect _lane(Size s, int lane) => Rect.fromLTWH(
      s.width * .045,
      s.height * (HarborFlow.laneY[lane] - .068),
      s.width * .89,
      s.height * .136);

  void _paintStatic(Canvas c, Size s) {
    c.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, s.height),
              const [Color(0xFF172C45), Color(0xFF29473F), Color(0xFF213C35)],
              const [0, .55, 1]));
    final river = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            s.width * .035, s.height * .225, s.width * .91, s.height * .58),
        const Radius.circular(28));
    c.drawRRect(river.shift(const Offset(0, 5)),
        Paint()..color = const Color(0x55101519));
    c.drawRRect(
        river,
        Paint()
          ..shader = ui.Gradient.linear(
              river.outerRect.topCenter,
              river.outerRect.bottomCenter,
              const [Color(0xFF113C55), Color(0xFF0D3045)]));
    c.drawRRect(river, _stroke(const Color(0xFF7C6A45), 5));
    final grass = _stroke(const Color(0x887CA65E), 1.6);
    for (var i = 0; i < 70; i++) {
      final x = (i * 53 % 997) / 997 * s.width;
      final y = i.isEven
          ? s.height * (.18 - (i % 4) * .012)
          : s.height * (.84 + (i % 5) * .025);
      c.drawLine(Offset(x, y), Offset(x - 3, y - 8), grass);
      c.drawLine(Offset(x, y), Offset(x + 3, y - 7), grass);
    }
    for (var i = 0; i < 12; i++) {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(s.width * (.08 + i * .075),
                  s.height * (.88 + (i % 3) * .025)),
              width: 18 + (i % 3) * 5,
              height: 9),
          Paint()..color = const Color(0x66556A60));
    }
    for (var lane = 0; lane < 3; lane++) {
      final r =
          RRect.fromRectAndRadius(_lane(s, lane), const Radius.circular(22));
      c.drawRRect(
          r,
          Paint()
            ..shader = ui.Gradient.linear(
                r.outerRect.topCenter,
                r.outerRect.bottomCenter,
                const [Color(0xFF2E7F96), Color(0xFF1F617A)]));
      c.drawRRect(r, _stroke(const Color(0x5596DDEB), 2));
    }
    for (final x in HarborFlow.gateX) {
      final pool = RRect.fromRectAndRadius(
          Rect.fromLTWH(s.width * (x - .045), s.height * .27, s.width * .09,
              s.height * .5),
          const Radius.circular(26));
      c.drawRRect(pool, Paint()..color = const Color(0xFF256F87));
      c.drawRRect(pool, _stroke(const Color(0x4496DDEB), 2));
    }
    final pier = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, s.height * .2, s.width * .055, s.height * .64),
        const Radius.circular(8));
    c.drawRRect(pier, Paint()..color = _wood);
    for (var y = pier.top + 12; y < pier.bottom; y += 18) {
      c.drawLine(Offset(4, y), Offset(pier.right - 4, y),
          _stroke(const Color(0x887A4A27), 2));
    }
    c.drawRRect(pier, _stroke(_ink, 3));
  }

  void _paintFlow(Canvas c, Size s) {
    final foam = _stroke(const Color(0x88BFF2FA), 2.2);
    const speed = 34.0;
    for (var lane = 0; lane < 3; lane++) {
      final r = _lane(s, lane);
      for (var row = 0; row < 2; row++) {
        final y = r.top + r.height * (.32 + row * .36);
        for (var i = -1; i < 14; i++) {
          final x = r.left +
              ((i * 74 + _clock * speed + row * 31) % (r.width + 74)) -
              37;
          if (x < r.left + 8 || x > r.right - 30) continue;
          c.drawPath(
              Path()
                ..moveTo(x, y)
                ..quadraticBezierTo(x + 8, y - 4, x + 18, y),
              foam);
        }
      }
    }
  }

  void _paintDocks(Canvas c, Size s) {
    for (var lane = 0; lane < 3; lane++) {
      final y = s.height * HarborFlow.laneY[lane];
      final rect = Rect.fromLTWH(
          s.width * .925, y - s.height * .075, s.width * .075, s.height * .15);
      if (!flow.dockBreeds.containsKey(lane)) {
        c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            Paint()..color = const Color(0xFF173342));
        for (var i = 0; i < 5; i++) {
          final x = rect.left + 6 + i * 7;
          final drop = (_clock * 30 + i * 9) % 18;
          c.drawLine(
              Offset(x, rect.top + 6 + drop * .2),
              Offset(x - 5, rect.bottom - 6),
              _stroke(const Color(0xAAE6FBFF), 2));
        }
        continue;
      }
      final deck = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      c.drawRRect(deck.shift(const Offset(0, 4)),
          Paint()..color = const Color(0x55000000));
      c.drawRRect(deck, Paint()..color = _woodLight);
      for (var x = rect.left + 9; x < rect.right; x += 10) {
        c.drawLine(Offset(x, rect.top + 3), Offset(x, rect.bottom - 3),
            _stroke(const Color(0x887A4A27), 1.5));
      }
      c.drawRRect(deck, _stroke(_ink, 2.5));
      for (final py in [rect.top + 7, rect.bottom - 7]) {
        c.drawCircle(Offset(rect.left + 5, py), 5, Paint()..color = _woodDark);
        c.drawCircle(Offset(rect.left + 5, py), 5, _stroke(_ink, 1.6));
      }
      final breed = flow.dockBreeds[lane];
      final shared = flow.sharedDock == lane;
      final color = shared
          ? const Color(0xFFFFE08A)
          : breed == null
              ? const Color(0xFF8A9A9E)
              : CatBreed.of(breed).color;
      final glow = .45 + math.sin(_clock * 4 + lane) * .15;
      final lamp = Offset(rect.center.dx + 4, rect.top - 11);
      c.drawCircle(
          lamp, 21, Paint()..color = color.withValues(alpha: glow * .5));
      c.drawLine(Offset(lamp.dx, lamp.dy + 9), Offset(lamp.dx, rect.top + 4),
          _stroke(_ink, 2.4));
      c.drawCircle(lamp, 14, Paint()..color = color);
      c.drawCircle(lamp, 14, _stroke(_ink, 2));
      _paw(c, lamp, shared ? const Color(0xFF6A3E1E) : const Color(0xFFFFF4DA));
    }
  }

  void _paintRocks(Canvas c, Size s) {
    for (final (lane, x) in flow.rocks) {
      final center = Offset(s.width * x, s.height * HarborFlow.laneY[lane]);
      for (var i = 0; i < 3; i++) {
        final ring = 23.0 + i * 7 + (_clock * 10 % 7);
        c.drawOval(
            Rect.fromCenter(center: center, width: ring * 2, height: ring * .9),
            _stroke(const Color(0x33BFF2FA), 1.5));
      }
      final rock = Path()
        ..moveTo(center.dx - 23, center.dy + 9)
        ..quadraticBezierTo(
            center.dx - 20, center.dy - 16, center.dx - 2, center.dy - 18)
        ..quadraticBezierTo(
            center.dx + 21, center.dy - 15, center.dx + 23, center.dy + 8)
        ..quadraticBezierTo(
            center.dx, center.dy + 17, center.dx - 23, center.dy + 9)
        ..close();
      c.drawPath(rock.shift(const Offset(0, 4)),
          Paint()..color = const Color(0x66000000));
      c.drawPath(rock, Paint()..color = const Color(0xFF68716B));
      c.drawPath(rock, _stroke(_ink, 2));
      c.drawOval(
          Rect.fromCenter(
              center: center + const Offset(-6, -8), width: 18, height: 6),
          Paint()..color = const Color(0x557BA35E));
    }
  }
}

void _paw(Canvas c, Offset center, Color color) {
  final paint = Paint()..color = color;
  c.drawOval(
      Rect.fromCenter(
          center: center + const Offset(0, 2.5), width: 8, height: 6),
      paint);
  for (final dx in const [-4.0, -1.4, 1.4, 4.0]) {
    c.drawCircle(center + Offset(dx, dx.abs() > 3 ? -1.5 : -4), 1.6, paint);
  }
}

class HarborRaftsComponent extends PositionComponent with HasGameReference {
  HarborRaftsComponent(this.flow) : super(priority: 70);
  final HarborFlow flow;
  double _clock = 0;
  @override
  void update(double dt) => _clock += dt;

  @override
  void render(Canvas canvas) {
    for (final raft in flow.rafts) {
      final c = _px(raft.center, game.size) +
          Offset(0, math.sin(_clock * 3 + raft.id) * 1.5);
      final body = Rect.fromCenter(center: c, width: 84, height: 35);
      canvas.drawOval(body.inflate(8).shift(const Offset(0, 9)),
          Paint()..color = const Color(0x44000000));
      canvas.drawLine(
          body.centerLeft + const Offset(-14, 0),
          body.centerLeft + const Offset(-26, 0),
          _stroke(const Color(0x66BFF2FA), 2));
      // Bamboo poles lie across the current, tied by two rope bands.
      for (var i = 0; i < 4; i++) {
        final pole = RRect.fromRectAndRadius(
            Rect.fromLTWH(body.left - (i.isEven ? 3 : 0), body.top + i * 8.8,
                body.width + (i.isEven ? 6 : 0), 8.2),
            const Radius.circular(4.1));
        canvas.drawRRect(
            pole,
            Paint()
              ..shader = ui.Gradient.linear(
                  pole.outerRect.topCenter,
                  pole.outerRect.bottomCenter,
                  const [Color(0xFFE6D985), Color(0xFF9FA34C)]));
        canvas.drawLine(
            Offset(pole.left + 5, pole.top + 2.4),
            Offset(pole.right - 5, pole.top + 2.4),
            _stroke(const Color(0x99FFF8C8), 1.2));
        for (var x = pole.left + 15; x < pole.right - 6; x += 17) {
          canvas.drawLine(Offset(x, pole.top + 1), Offset(x, pole.bottom - 1),
              _stroke(const Color(0xFF6E7434), 1.6));
        }
        canvas.drawRRect(pole, _stroke(_ink, 1.3));
      }
      for (final x in [body.left + 17, body.right - 17]) {
        canvas.drawLine(Offset(x, body.top - 2), Offset(x, body.bottom + 2),
            _stroke(const Color(0xFFD7B47A), 3.4));
        for (var y = body.top + 4; y < body.bottom; y += 7) {
          canvas.drawLine(Offset(x - 2, y), Offset(x + 2, y + 3),
              _stroke(const Color(0xFF8A6235), 1));
        }
      }
      final pole = Offset(body.right - 8, body.top + 4);
      canvas.drawLine(pole, pole - const Offset(0, 25), _stroke(_ink, 2.5));
      final flag = Path()
        ..moveTo(pole.dx, pole.dy - 25)
        ..lineTo(pole.dx + 18, pole.dy - 20)
        ..lineTo(pole.dx, pole.dy - 14)
        ..close();
      canvas.drawPath(flag, Paint()..color = CatBreed.of(raft.breed).color);
      canvas.drawPath(flag, _stroke(_ink, 1.5));
      if (raft.anchor > 0) {
        final fish = c + const Offset(-24, 1);
        final fishPaint = Paint()..color = const Color(0xFF8ED7E8);
        canvas.drawOval(
            Rect.fromCenter(center: fish, width: 18, height: 10), fishPaint);
        canvas.drawPath(
            Path()
              ..moveTo(fish.dx - 8, fish.dy)
              ..lineTo(fish.dx - 15, fish.dy - 6)
              ..lineTo(fish.dx - 15, fish.dy + 6)
              ..close(),
            fishPaint);
        canvas.drawArc(
            Rect.fromCircle(center: c, radius: 45),
            -math.pi / 2,
            math.pi * 2 * raft.anchor / 2.5,
            false,
            _stroke(const Color(0xFF8ED7E8), 3));
      }
    }
  }
}

class HarborMoon extends PositionComponent with HasGameReference {
  HarborMoon(this.moon) : super(priority: 84);
  final Moonlight moon;
  @override
  void render(Canvas canvas) => paintMoon(canvas, game.size.toSize(), moon);
}

/// Pivoting wooden sluice. Tap cycles it; a vertical swipe picks a branch.
class HarborGateComponent extends PositionComponent
    with HasGameReference, TapCallbacks, DragCallbacks {
  HarborGateComponent(this.gate, this.flow,
      {required this.onTapGate, required this.onSwipeGate})
      : super(priority: 88);
  final HarborGate gate;
  final HarborFlow flow;
  final void Function(HarborGate) onTapGate;
  final void Function(HarborGate, int) onSwipeGate;
  double _turn = 0, _clock = 0, _dragY = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = Vector2(size.x * .11, size.y * .19);
    position = Vector2(size.x * gate.x - this.size.x / 2,
        size.y * HarborFlow.laneY[gate.lane] - this.size.y / 2);
  }

  @override
  void update(double dt) {
    _clock += dt;
    final target = gate.direction * .55;
    _turn += (target - _turn) * math.min(1, dt * 12);
  }

  @override
  void onTapDown(TapDownEvent event) => onTapGate(gate);

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragY = 0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _dragY += event.localDelta.y;
    if (_dragY.abs() < 18) return;
    onSwipeGate(gate, _dragY < 0 ? -1 : 1);
    _dragY = 0;
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final ready = flow.approaching(gate);
    // Soft whirl of water so the whole pool reads as the touch target.
    canvas.drawOval(
        Rect.fromCenter(center: c, width: size.x * .96, height: size.y * .78),
        Paint()
          ..color = ready ? const Color(0x55FFE08A) : const Color(0x2296DDEB));
    if (ready) {
      final pulse = 1 + math.sin(_clock * 8) * .05;
      canvas.drawOval(
          Rect.fromCenter(
              center: c,
              width: size.x * .98 * pulse,
              height: size.y * .8 * pulse),
          _stroke(const Color(0xCCFFE08A), 2.5));
    }
    // Foam trails the way the water is sent.
    final foam = _stroke(const Color(0xAAE6FBFF), 2);
    final dir = Offset(math.cos(_turn), math.sin(_turn));
    final normal = Offset(-dir.dy, dir.dx);
    for (var i = 0; i < 3; i++) {
      final t = ((_clock * .9 + i / 3) % 1);
      final p = c + dir * (10 + t * size.x * .38) + normal * ((i - 1) * 6);
      canvas.drawLine(p, p + dir * 7, foam);
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_turn);
    final length = size.x * .78;
    final plank = RRect.fromRectAndRadius(
        Rect.fromLTWH(-length * .38, -6, length, 12), const Radius.circular(4));
    canvas.drawRRect(plank.shift(const Offset(0, 4)),
        Paint()..color = const Color(0x55000000));
    canvas.drawRRect(
        plank,
        Paint()
          ..shader = ui.Gradient.linear(const Offset(0, -6), const Offset(0, 6),
              const [Color(0xFFD8A866), Color(0xFF9B6534)]));
    for (var x = -length * .38 + 12; x < length * .62 - 6; x += 12) {
      canvas.drawLine(Offset(x, -4), Offset(x + 4, 4),
          _stroke(const Color(0x667A4A27), 1.1));
    }
    canvas.drawRRect(plank, _stroke(_ink, 2));
    for (final x in [length * .2, length * .5]) {
      canvas.drawCircle(Offset(x, 0), 1.8, Paint()..color = _ink);
    }
    canvas.restore();
    // Post at the hinge, with a rope ring when the column is linked.
    canvas.drawCircle(
        c + const Offset(0, 3), 9, Paint()..color = const Color(0x55000000));
    canvas.drawCircle(c, 9, Paint()..color = _woodDark);
    canvas.drawCircle(c, 9, _stroke(_ink, 2));
    canvas.drawCircle(
        c - const Offset(2, 2), 3, Paint()..color = const Color(0x66FFF0C8));
    if (flow.linked) {
      canvas.drawCircle(c, 12, _stroke(const Color(0xFFD7B47A), 2.5));
    }
  }
}
