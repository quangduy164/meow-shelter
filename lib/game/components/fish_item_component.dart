import 'package:flutter/painting.dart';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

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
      this.remaining})
      : super(size: Vector2(64, 48), priority: 90);

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
    position.setValues((size.x - this.size.x) / 2, size.y - this.size.y - 8);
  }

  @override
  void render(Canvas canvas) {
    if (!visible()) return;
    final frame = RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5, 1.5, size.x - 3, size.y - 3),
        const Radius.circular(14));
    canvas.drawRRect(frame.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x55402616));
    canvas.drawRRect(
        frame,
        Paint()
          ..color =
              enabled() ? const Color(0xFFFCCB59) : const Color(0xFFB4A58C));
    canvas.drawRRect(
        frame.deflate(4),
        Paint()
          ..color = const Color(0x66FFF0CA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.drawRRect(
        frame,
        Paint()
          ..color = const Color(0xFF774016)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // Fish artwork spans -24..15 horizontally, including its tail.
    final count = remaining?.call();
    canvas.save();
    canvas.translate(count == null ? size.x / 2 : size.x * .4, size.y / 2);
    canvas.scale(0.75);
    drawFish(canvas, const Offset(4.5, 0));
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
      final center = Offset(size.x - 12, 12);
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
    if (preview != null) drawFish(canvas, Offset(preview.x, preview.y));
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
