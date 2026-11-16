import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../../components/fish_item_component.dart';
import '../moonlight.dart';
import '../moonlight_art.dart';
import 'warehouse_traps.dart';

class WarehouseBackground extends PositionComponent {
  WarehouseBackground() : super(priority: -100);
  ui.Picture? _picture;
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.setFrom(size);
    _picture?.dispose();
    _picture = null;
  }

  @override
  void onRemove() {
    _picture?.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    if (_picture == null) {
      final rec = ui.PictureRecorder();
      _paint(Canvas(rec), size.toSize());
      _picture = rec.endRecording();
    }
    canvas.drawPicture(_picture!);
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

/// Cage front is above cats. Taps are intercepted here, never used to carry cats.
class WarehouseDoor extends PositionComponent
    with HasGameReference, TapCallbacks {
  WarehouseDoor(this.slot, this.traps, {required this.onClose, this.canClose})
      : super(priority: 12);
  final TrapSlot slot;
  final WarehouseTraps traps;
  final void Function(TrapSlot) onClose;
  final bool Function(TrapSlot)? canClose;
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final field = size;
    position =
        Vector2(slot.area.left * field.x - 5, slot.area.top * field.y - 14);
    this.size = Vector2(
        slot.area.width * field.x + 10, slot.area.height * field.y + 48);
  }

  @override
  void onTapDown(TapDownEvent event) => onClose(slot);
  void _label(Canvas c, String text, Offset center, Color color,
      {double font = 10}) {
    final p = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: color,
                fontFamily: 'Roboto',
                fontSize: font,
                fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: size.x - 8);
    p.paint(c, center - Offset(p.width / 2, 0));
    p.dispose();
  }

  @override
  void render(Canvas canvas) {
    final c = canvas;
    final body = Rect.fromLTWH(5, 14, size.x - 10, size.y - 48);
    final ready = canClose?.call(slot) ?? traps.catchable(slot);
    final color = ready ? const Color(0xFF96E6AC) : const Color(0xFFD1B17C);
    final frame = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    c.drawRRect(
        RRect.fromRectAndRadius(body.inflate(2), const Radius.circular(6)),
        frame);
    // Open entrance at left; back and ceiling remain visibly barred.
    for (var x = body.left + body.width * .35; x < body.right; x += 16) {
      c.drawLine(
          Offset(x, body.top + 4),
          Offset(x, body.bottom - 4),
          Paint()
            ..color = const Color(0x778DA4A3)
            ..strokeWidth = 2);
    }
    c.drawLine(body.topLeft, body.topRight, frame);
    c.drawLine(body.bottomLeft, body.bottomRight, frame);
    if (slot.phase == TrapPhase.cooling) {
      c.drawRect(body, Paint()..color = const Color(0x66506468));
      for (var y = body.top + 8; y < body.bottom; y += 15) {
        c.drawLine(
            Offset(body.left, y),
            Offset(body.right, y),
            Paint()
              ..color = const Color(0xFF91A7A7)
              ..strokeWidth = 2);
      }
    }
    if (slot.baited) {
      c.save();
      c.translate(body.center.dx + 7, body.center.dy);
      c.scale(.6);
      drawFish(c, Offset.zero);
      c.restore();
    }
    if (ready) {
      c.drawRRect(
          RRect.fromRectAndRadius(body.inflate(5), const Radius.circular(8)),
          Paint()
            ..color = const Color(0x5596E6AC)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    final name =
        'LỒNG ${slot.cage + 1}${traps.lanes == 2 ? ' · ${slot.lane + 1}' : ''}';
    _label(c, name, Offset(body.center.dx, 0), color, font: 9);
    final button = Rect.fromLTWH(5, body.bottom + 9, body.width, 25);
    c.drawRRect(
        RRect.fromRectAndRadius(button, const Radius.circular(6)),
        Paint()
          ..color = ready ? const Color(0xFF3C8065) : const Color(0xFF354B51));
    final text = ready
        ? 'CHỐT NGAY'
        : switch (slot.phase) {
            TrapPhase.open => slot.baited ? 'CHỜ MÈO' : 'THẢ MỒI',
            TrapPhase.approaching => 'MÈO ĐANG TỚI',
            TrapPhase.peeking => 'CHỈ THÒ ĐẦU',
            TrapPhase.entering => 'ĐANG VÀO',
            TrapPhase.inside => 'CHỐT NGAY',
            TrapPhase.leaving => 'MÈO ĐANG RA',
            TrapPhase.cooling => 'CHỜ ${slot.cool.ceil()}s',
          };
    _label(c, text, Offset(button.center.dx, button.top + 6),
        const Color(0xFFFFF4DA),
        font: 9);
    if (slot.phase == TrapPhase.inside) {
      c.drawRect(
          Rect.fromLTWH(body.left, body.bottom + 3,
              body.width * (1 - slot.elapsed / slot.hold).clamp(0, 1), 3),
          Paint()..color = color);
    }
  }
}
