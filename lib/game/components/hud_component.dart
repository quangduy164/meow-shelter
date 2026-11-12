import '../../ui/design.dart';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../../levels/level_goal.dart';

enum RoundStatus { playing, won, lost }

const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);
const _wood = Color(0xFFB27A3E);
const _gold = Color(0xFFFFC24D);
const _muted = Color(0xFF8E8270);
const _danger = Color(0xFFC0503A);

/// Compact round HUD: one status pill at the top (time · cats · fish),
/// a small mission card in the top-right corner and short toasts.
class HudComponent extends PositionComponent with HasGameRef<FlameGame> {
  HudComponent() : super(priority: 100);

  int delivered = 0;
  int totalCats = 8;
  int secondsLeft = 90;
  RoundStatus status = RoundStatus.playing;
  bool isTutorial = false;
  bool isInfinite = false;

  /// Fish left on fish-limit levels; null when bait is unlimited.
  int? fishLeft;

  /// Missions of the level and live counters to judge them.
  List<LevelGoal> goals = const [];
  RoundStats Function()? stats;

  List<String> _toast = const [];
  double _toastTime = 0;
  double _clock = 0;

  /// Shows [lines] as a small toast under the status pill.
  void showBanner(List<String> lines, [double seconds = 3]) {
    _toast = lines.take(2).toList();
    _toastTime = seconds;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
    if (_toastTime > 0) _toastTime -= dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (status != RoundStatus.playing || isTutorial) return;
    final pill = _drawStatusPill(canvas);
    _drawToast(canvas, pill.bottom + 6);
    _drawGoals(canvas);
  }

  Rect _drawStatusPill(Canvas canvas) {
    final screen = gameRef.size;
    final lowTime = !isInfinite && secondsLeft <= 10;
    final parts = <(void Function(Canvas, Offset, Color), String, Color)>[
      if (!isInfinite)
        (_clockIcon, '${secondsLeft}s', lowTime ? _danger : _ink),
      (_pawIcon, isInfinite ? '$delivered' : '$delivered/$totalCats', _ink),
      if (fishLeft != null)
        (_fishIcon, '$fishLeft', fishLeft == 0 ? _danger : _ink),
    ];
    final labels = [
      for (final (_, text, color) in parts)
        _text(text, DS.fontBody, color, bold: true)
    ];
    const iconW = 16.0, gap = 4.0, sep = 13.0, padX = 11.0, h = 28.0;
    final width = labels.fold(0.0, (w, l) => w + iconW + gap + l.width) +
        sep * (parts.length - 1) +
        padX * 2;
    final pulse = lowTime ? 1 + math.sin(_clock * 9) * .04 : 1.0;
    final box = Rect.fromCenter(
        center: Offset(screen.x / 2, 12 + h / 2), width: width, height: h);
    canvas.save();
    canvas.translate(box.center.dx, box.center.dy);
    canvas.scale(pulse);
    canvas.translate(-box.center.dx, -box.center.dy);
    final shape = RRect.fromRectAndRadius(box, const Radius.circular(14));
    canvas.drawRRect(shape.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x44402616));
    canvas.drawRRect(shape, Paint()..color = const Color(0xF2FFF4DA));
    canvas.drawRRect(
        shape,
        Paint()
          ..color = lowTime ? _danger : _wood
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    var x = box.left + padX;
    for (var i = 0; i < parts.length; i++) {
      final (icon, _, color) = parts[i];
      icon(canvas, Offset(x + iconW / 2, box.center.dy), color);
      x += iconW + gap;
      labels[i].paint(canvas, Offset(x, box.center.dy - labels[i].height / 2));
      x += labels[i].width;
      if (i < parts.length - 1) {
        canvas.drawLine(
            Offset(x + sep / 2, box.top + 7),
            Offset(x + sep / 2, box.bottom - 7),
            Paint()
              ..color = const Color(0x55B27A3E)
              ..strokeWidth = 1.5);
        x += sep;
      }
    }
    canvas.restore();
    return box;
  }

  void _drawToast(Canvas canvas, double top) {
    if (_toastTime <= 0 || _toast.isEmpty) return;
    final fade = (_toastTime.clamp(0.0, .35) / .35);
    final rise = (1 - fade) * -4;
    final screen = gameRef.size;
    var y = top + rise;
    for (final line in _toast) {
      final label = _text(line, DS.fontCaption, _cream.withOpacity(fade),
          bold: true, maxWidth: screen.x * .5);
      final box = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(screen.x / 2, y + 11),
              width: label.width + 20,
              height: 22),
          const Radius.circular(11));
      canvas.drawRRect(
          box, Paint()..color = Color.fromRGBO(90, 50, 20, .9 * fade));
      label.paint(canvas,
          Offset(screen.x / 2 - label.width / 2, y + 11 - label.height / 2));
      y += 26;
    }
  }

  void _drawGoals(Canvas canvas) {
    final current = stats?.call();
    if (goals.isEmpty || current == null) return;
    final screen = gameRef.size;
    const rowH = 17.0, padX = 8.0, padY = 6.0;
    final rows = [
      for (final goal in goals) (goal, _goalFailed(goal, current)),
    ];
    final labels = [
      for (final (goal, failed) in rows)
        _text(goal.label, DS.fontCaption, failed ? _muted : _ink,
            bold: !failed, strike: failed)
    ];
    final width =
        labels.fold(0.0, (w, l) => math.max(w, l.width)) + padX * 2 + 16;
    final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            screen.x - width - 12, 12, width, rows.length * rowH + padY * 2),
        const Radius.circular(10));
    canvas.drawRRect(box, Paint()..color = const Color(0xD9FFF4DA));
    canvas.drawRRect(
        box,
        Paint()
          ..color = const Color(0x99B27A3E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    for (var i = 0; i < rows.length; i++) {
      final cy = box.top + padY + rowH * i + rowH / 2;
      _star(canvas, Offset(box.left + padX + 6, cy), 6,
          rows[i].$2 ? const Color(0x55704019) : _gold);
      labels[i].paint(
          canvas, Offset(box.left + padX + 16, cy - labels[i].height / 2));
    }
  }

  /// A goal that can no longer be met this round.
  bool _goalFailed(LevelGoal goal, RoundStats s) => switch (goal.kind) {
        GoalKind.timeLeft => secondsLeft < goal.value,
        GoalKind.noStartle => s.startles > 0,
        GoalKind.fishMax => s.fishUsed > goal.value,
        GoalKind.noWrongBed => s.wrongDrops > 0,
      };

  TextPainter _text(String text, double size, Color color,
          {bool bold = false, bool strike = false, double? maxWidth}) =>
      TextPainter(
          text: TextSpan(
              text: text,
              style: TextStyle(
                  color: color,
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                  decoration: strike ? TextDecoration.lineThrough : null,
                  decorationColor: color)),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…')
        ..layout(maxWidth: maxWidth ?? double.infinity);

  static void _clockIcon(Canvas canvas, Offset c, Color color) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, 6.5, stroke);
    canvas.drawLine(c, c + const Offset(0, -4), stroke);
    canvas.drawLine(c, c + const Offset(3, 1.5), stroke);
  }

  static void _pawIcon(Canvas canvas, Offset c, Color color) {
    final paint = Paint()..color = color;
    canvas.drawOval(
        Rect.fromCenter(
            center: c + const Offset(0, 2.5), width: 8, height: 6.5),
        paint);
    for (final (dx, dy) in const [
      (-5.0, -2.0),
      (-2.0, -5.5),
      (2.0, -5.5),
      (5.0, -2.0)
    ]) {
      canvas.drawCircle(c + Offset(dx, dy), 1.8, paint);
    }
  }

  static void _fishIcon(Canvas canvas, Offset c, Color color) {
    final paint = Paint()
      ..color = color == _danger ? _danger : const Color(0xFF3E9FB0);
    canvas.drawOval(
        Rect.fromCenter(center: c + const Offset(1.5, 0), width: 11, height: 7),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(c.dx - 3, c.dy)
          ..lineTo(c.dx - 7.5, c.dy - 4)
          ..lineTo(c.dx - 7.5, c.dy + 4)
          ..close(),
        paint);
    canvas.drawCircle(c + const Offset(4, -.8), 1, Paint()..color = _cream);
  }

  static void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * .45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }
}
