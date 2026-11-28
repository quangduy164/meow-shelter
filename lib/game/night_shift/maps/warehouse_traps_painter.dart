import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../../text_cache.dart';
import '../static_layer.dart';
import '../../components/fish_item_component.dart';
import '../moonlight.dart';
import '../moonlight_art.dart';
import 'warehouse_traps.dart';

class WarehouseBackground extends PositionComponent {
  WarehouseBackground() : super(priority: -100);
  final _layer = StaticLayer();
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.setFrom(size);
    _layer.clear();
  }

  @override
  void onRemove() {
    _layer.clear();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    _layer.draw(canvas, size.toSize(), (c) => _paint(c, size.toSize()));
  }

  void _paint(Canvas c, Size s) {
    c.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height),
              const [Color(0xFF243C50), Color(0xFF53625C)]));
    for (var x = 0.0; x < s.width; x += 48) {
      c.drawLine(Offset(x, s.height * .20), Offset(x, s.height),
          Paint()..color = const Color(0x225D8F93));
    }
    for (var y = s.height * .20; y < s.height; y += 35) {
      c.drawLine(Offset(0, y), Offset(s.width, y),
          Paint()..color = const Color(0x225D8F93));
    }
    c.drawRect(Rect.fromLTWH(0, s.height * .06, s.width, s.height * .15),
        Paint()..color = const Color(0xFF263A43));
    for (var x = 18.0; x < s.width; x += 85) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, s.height * .09, 66, s.height * .11),
              const Radius.circular(3)),
          Paint()..color = const Color(0xFF7C6E52));
      c.drawRect(Rect.fromLTWH(x + 27, s.height * .09, 10, s.height * .11),
          Paint()..color = const Color(0xFFAF9972));
      c.drawRect(Rect.fromLTWH(x + 8, s.height * .12, 15, 8),
          Paint()..color = const Color(0xFFCCBB8D));
    }
    c.drawRect(Rect.fromLTWH(0, s.height * .20, s.width, 5),
        Paint()..color = const Color(0xFF2B3030));
    for (final x in [s.width * .06, s.width * .94]) {
      c.drawRect(Rect.fromLTWH(x - 4, s.height * .82, 8, s.height * .10),
          Paint()..color = const Color(0xFFB8A267));
    }
  }
}

class WarehouseMoon extends PositionComponent with HasGameReference {
  WarehouseMoon(this.moon) : super(priority: 84);
  final Moonlight moon;
  @override
  void render(Canvas canvas) => paintMoon(canvas, game.size.toSize(), moon);
}

Rect _cageRect(TrapSlot slot, Vector2 field) => Rect.fromLTWH(
    slot.area.left * field.x,
    slot.area.top * field.y,
    slot.area.width * field.x,
    slot.area.height * field.y);

/// Floor, back bars and bait stay behind cats.
class WarehouseCageBack extends PositionComponent with HasGameReference {
  WarehouseCageBack(this.slot, this.traps) : super(priority: 70);
  final TrapSlot slot;
  final WarehouseTraps traps;
  final _shell = StaticLayer();

  @override
  void onRemove() {
    _shell.clear();
    super.onRemove();
  }

  static void _paintShell(Canvas canvas, Rect body) {
    final shell = RRect.fromRectAndRadius(body, const Radius.circular(8));
    canvas.drawRRect(shell.shift(const Offset(0, 5)),
        Paint()..color = const Color(0x55101519));
    canvas.drawRRect(
        shell,
        Paint()
          ..shader = ui.Gradient.linear(body.topCenter, body.bottomCenter,
              const [Color(0xFF1C2B31), Color(0xFF34443F)]));
    final back = Paint()
      ..color = const Color(0x5574918D)
      ..strokeWidth = 1.5;
    for (var y = body.top + 14; y < body.bottom - 18; y += 14) {
      canvas.drawLine(
          Offset(body.left + 7, y), Offset(body.right - 7, y), back);
    }
    final floor = Rect.fromLTWH(body.left + 4, body.bottom - body.height * .22,
        body.width - 8, body.height * .18);
    canvas.drawRRect(RRect.fromRectAndRadius(floor, const Radius.circular(4)),
        Paint()..color = const Color(0xFF8A6A43));
    for (var x = floor.left + 14; x < floor.right; x += 18) {
      canvas.drawLine(Offset(x, floor.top + 2), Offset(x - 5, floor.bottom - 2),
          Paint()..color = const Color(0x665B3F27));
    }
  }

  @override
  void render(Canvas canvas) {
    final body = _cageRect(slot, game.size).deflate(3);
    // Only the cage area is rasterised, with room for the drop shadow.
    canvas
      ..save()
      ..translate(body.left - 4, body.top - 4);
    _shell.draw(canvas, Size(body.width + 8, body.height + 12),
        (c) => _paintShell(c, Rect.fromLTWH(4, 4, body.width, body.height)));
    canvas.restore();
    final floor = Rect.fromLTWH(body.left + 4, body.bottom - body.height * .22,
        body.width - 8, body.height * .18);
    if (!slot.showsFish) return;
    final left = traps.fishLeft(slot);
    final x = slot.opensRight
        ? body.left + body.width * .34
        : body.right - body.width * .34;
    final center = Offset(x, floor.top + 5);
    canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(0, 9), width: 46, height: 10),
        Paint()..color = const Color(0x66392616));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(center.dx - 26, center.dy - 18,
        center.dx - 26 + 52 * left, center.dy + 18));
    canvas.translate(center.dx, center.dy);
    canvas.scale(slot.opensRight ? -.72 : .72, .72);
    drawFish(canvas, Offset.zero);
    canvas.restore();
  }
}

/// Front bars and gate cover cats. The front also receives taps.
class WarehouseDoor extends PositionComponent
    with HasGameReference, TapCallbacks {
  WarehouseDoor(this.slot, this.traps, {required this.onClose, this.canClose})
      : super(priority: 88);
  final TrapSlot slot;
  final WarehouseTraps traps;
  final void Function(TrapSlot) onClose;
  final bool Function(TrapSlot)? canClose;
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final body = _cageRect(slot, size);
    position = Vector2(body.left - 5, body.top - 16);
    this.size = Vector2(body.width + 10, body.height + 50);
  }

  @override
  void onTapDown(TapDownEvent event) => onClose(slot);
  void _label(Canvas c, String text, Offset center, Color color,
      {double font = 10}) {
    final p = TextCache.layout(
        text,
        TextStyle(
            color: color,
            fontFamily: 'Nunito',
            fontSize: font,
            fontWeight: FontWeight.w900),
        maxWidth: size.x - 8);
    p.paint(c, center - Offset(p.width / 2, 0));
  }

  @override
  void render(Canvas canvas) {
    final c = canvas;
    final body = Rect.fromLTWH(8, 19, size.x - 16, size.y - 56);
    final ready = canClose?.call(slot) ?? traps.catchable(slot);
    final closed = slot.phase == TrapPhase.closing;
    final color = ready
        ? const Color(0xFF8FF0A6)
        : closed
            ? const Color(0xFFFFD36E)
            : const Color(0xFFC9AE7C);
    final metal = Paint()
      ..color = const Color(0xFFB9C7C1)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final frame = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = ready ? 4 : 3;
    final entrance = slot.opensRight ? body.right : body.left;
    final innerStart = slot.opensRight ? body.left + 10 : body.left + 24;
    final innerEnd = slot.opensRight ? body.right - 24 : body.right - 10;
    for (var x = innerStart; x <= innerEnd; x += 13) {
      c.drawLine(Offset(x, body.top + 5), Offset(x, body.bottom - 5), metal);
    }
    c.drawLine(body.topLeft, body.topRight, frame);
    c.drawLine(body.bottomLeft, body.bottomRight, frame);
    c.drawLine(Offset(slot.opensRight ? body.left : body.right, body.top),
        Offset(slot.opensRight ? body.left : body.right, body.bottom), frame);
    final close = traps.doorClosed(slot);
    final gateHeight = body.height * (.18 + .82 * close);
    final gateX = slot.opensRight ? entrance - 18 : entrance;
    final gate = Rect.fromLTWH(gateX, body.top, 18, gateHeight);
    c.drawRRect(RRect.fromRectAndRadius(gate, const Radius.circular(3)),
        Paint()..color = const Color(0xDD394B4F));
    for (var x = gate.left + 4; x < gate.right; x += 7) {
      c.drawLine(Offset(x, gate.top + 2), Offset(x, gate.bottom - 2), metal);
    }
    c.drawLine(gate.bottomLeft, gate.bottomRight, frame);
    if (slot.phase == TrapPhase.cooling) {
      c.drawRect(body, Paint()..color = const Color(0x77506468));
      for (var y = body.top + 9; y < body.bottom; y += 14) {
        c.drawLine(Offset(innerStart, y), Offset(innerEnd, y), metal);
      }
    }
    if (ready) {
      c.drawRRect(
          RRect.fromRectAndRadius(body.inflate(5), const Radius.circular(9)),
          Paint()
            ..color = const Color(0x6696E6AC)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
    }
    final name =
        'LỒNG ${slot.cage + 1}${traps.lanes == 2 ? ' · ${slot.lane + 1}' : ''}';
    _label(c, name, Offset(body.center.dx, 1), color, font: 10);
    final button = Rect.fromLTWH(body.left, body.bottom + 8, body.width, 25);
    c.drawRRect(
        RRect.fromRectAndRadius(button, const Radius.circular(7)),
        Paint()
          ..color = ready
              ? const Color(0xFF3C8065)
              : closed
                  ? const Color(0xFF8A6630)
                  : const Color(0xFF354B51));
    final text = ready
        ? 'CHỐT NGAY'
        : switch (slot.phase) {
            TrapPhase.open => slot.baited ? 'CHỜ MÈO' : 'THẢ MỒI',
            TrapPhase.approaching => 'MÈO ĐANG TỚI',
            TrapPhase.peeking => 'MÈO DÒ ĐƯỜNG',
            TrapPhase.entering => 'ĐANG VÀO',
            TrapPhase.inside => 'ĐANG ĂN',
            TrapPhase.closing => 'ĐÃ CHỐT',
            TrapPhase.leaving => 'MÈO ĐANG RA',
            TrapPhase.cooling => 'CHỜ ${slot.cool.ceil()}s',
          };
    _label(c, text, Offset(button.center.dx, button.top + 6),
        const Color(0xFFFFF4DA),
        font: 10);
    if (slot.phase == TrapPhase.inside) {
      c.drawRect(
          Rect.fromLTWH(body.left, body.bottom + 3,
              body.width * (1 - slot.elapsed / slot.hold).clamp(0, 1), 3),
          Paint()..color = color);
    }
  }
}
