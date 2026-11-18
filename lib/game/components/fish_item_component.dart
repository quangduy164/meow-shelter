import 'package:flutter/painting.dart';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../cats/dish.dart';

void drawFish(Canvas canvas, Offset center) {
  final body = Paint()..color = const Color(0xFF53C9EF);
  canvas.drawOval(Rect.fromCenter(center: center, width: 30, height: 17), body);
  canvas.drawPath(
      Path()
        ..moveTo(center.dx - 12, center.dy)
        ..lineTo(center.dx - 24, center.dy - 11)
        ..lineTo(center.dx - 24, center.dy + 11)
        ..close(),
      body);
  canvas.drawCircle(center + const Offset(8, -2), 2,
      Paint()..color = const Color(0xFF173D51));
}

class FishItemComponent extends PositionComponent with DragCallbacks {
  FishItemComponent(
      {required this.enabled,
      required this.visible,
      required this.placeFish,
      this.remaining,
      this.dish = Dish.fish,
      this.slot = 0,
      this.slots = 1})
      : super(size: Vector2.all(54), priority: 90);

  /// What this slot hands out; the kitchen tray shows three slots in a row.
  final Dish dish;
  final int slot, slots;

  final bool Function() enabled;
  final bool Function() visible;
  final void Function(Vector2) placeFish;

  /// Null means unlimited bait; otherwise shown directly on the drag source.
  final int? Function()? remaining;
  Vector2? _preview;
  TextPainter? _countLabel;
  int? _lastCount;

  @override
  void onRemove() {
    _countLabel?.dispose();
    _countLabel = null;
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    const gap = 8.0;
    final row = slots * this.size.x + (slots - 1) * gap;
    position.setValues((size.x - row) / 2 + slot * (this.size.x + gap),
        size.y - this.size.y - 10);
  }

  @override
  void render(Canvas canvas) {
    if (!visible()) return;
    final on = enabled();
    // Square 3D tile: dark base, glossy face, cream plate holding the bait.
    final face = RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5, 1.5, size.x - 3, size.y - 6),
        const Radius.circular(13));
    const ink = Color(0xFF774016);
    canvas.drawRRect(face.shift(const Offset(0, 5)),
        Paint()..color = const Color(0x44402616));
    canvas.drawRRect(
        face.shift(const Offset(0, 3.5)),
        Paint()
          ..color = on ? const Color(0xFFC98A2E) : const Color(0xFF8E826F));
    canvas.drawRRect(
        face,
        Paint()
          ..shader = ui.Gradient.linear(
              face.outerRect.topCenter,
              face.outerRect.bottomCenter,
              on
                  ? const [Color(0xFFFFDE85), Color(0xFFF7B940)]
                  : const [Color(0xFFD2C6B0), Color(0xFFB4A58C)]));
    final plate = RRect.fromRectAndRadius(
        face.outerRect.deflate(7), const Radius.circular(9));
    canvas.drawRRect(
        plate,
        Paint()
          ..color = on ? const Color(0xFFFFF4DA) : const Color(0xFFE8E0D0));
    canvas.drawRRect(
        plate,
        Paint()
          ..color = const Color(0x55B27A3E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawLine(
        Offset(face.left + 9, face.top + 3.5),
        Offset(face.right - 16, face.top + 3.5),
        Paint()
          ..color = const Color(0x99FFFFFF)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(face.left, face.top, face.right, face.bottom + 3.5),
            const Radius.circular(13)),
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    // Fish artwork spans -24..15 horizontally, including its tail.
    final count = remaining?.call();
    canvas.save();
    canvas.translate(plate.center.dx, plate.center.dy);
    canvas.scale(dish == Dish.fish ? .7 : .66);
    drawDish(
        canvas, dish == Dish.fish ? const Offset(4.5, 0) : Offset.zero, dish);
    canvas.restore();
    if (count != null) {
      if (_lastCount != count || _countLabel == null) {
        _countLabel?.dispose();
        _lastCount = count;
        _countLabel = TextPainter(
          text: TextSpan(
              text: '$count',
              style: const TextStyle(
                  color: Color(0xFFFFFAEE),
                  fontSize: 11,
                  fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        )..layout();
      }
      // Count badge pinned on the top-right corner.
      final center = Offset(size.x - 4, 3);
      canvas.drawCircle(
          center,
          10.5,
          Paint()
            ..color =
                count == 0 ? const Color(0xFFC0503A) : const Color(0xFF31586C));
      canvas.drawCircle(
          center,
          10.5,
          Paint()
            ..color = const Color(0xFFFFEFCA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      final label = _countLabel!;
      label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
    }
    final preview = _preview;
    if (preview != null) drawDish(canvas, Offset(preview.x, preview.y), dish);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (enabled()) _preview = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _preview?.add(event.canvasDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final preview = _preview;
    _preview = null;
    if (preview != null &&
        enabled() &&
        !Rect.fromLTWH(0, 0, size.x, size.y)
            .contains(Offset(preview.x, preview.y))) {
      placeFish(position + preview);
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    _preview = null;
    super.onDragCancel(event);
  }
}
