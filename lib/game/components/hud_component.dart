import '../../ui/design.dart';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../../levels/level_goal.dart';
import '../silver_token_art.dart';
import '../text_cache.dart';

enum RoundStatus { playing, won, lost }

const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);
const _wood = Color(0xFFB27A3E);
const _gold = Color(0xFFFFC24D);
const _muted = Color(0xFF8E8270);
const _danger = Color(0xFFC0503A);

/// Compact round HUD: one status pill at the top (time · cats · fish),
/// a small mission card in the top-right corner and short toasts.
class HudComponent extends PositionComponent with HasGameReference<FlameGame> {
  HudComponent() : super(priority: 100);

  int delivered = 0;
  int totalCats = 8;
  int secondsLeft = 90;
  RoundStatus status = RoundStatus.playing;
  bool isTutorial = false;
  bool isInfinite = false;

  /// Night-shift night number (0 outside the night shift) and cats rescued
  /// tonight out of [totalCats].
  int night = 0;
  int tonight = 0;
  String arrivalHint = '';
  int silver = 0;

  /// Maps with extra HUD reserve space above transient notifications.
  double notificationTop = 46;

  /// Calico helper running: every bed takes any cat, so beds glow.
  bool anyBed = false;

  /// Tonight's boss flag, full rules (opened with the information button) and short
  /// tags (shown as chips on the small mission card).
  bool bossNight = false;
  List<String> nightNotes = const [];
  List<String> nightTags = const [];

  int _shownTonight = 0;
  double _pop = 0;

  /// Resets progress feedback for the new night.
  void startNight() {
    _shownTonight = 0;
    _pop = 0;
  }

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
    if (_pop > 0) _pop -= dt;
    if (tonight != _shownTonight) {
      _shownTonight = tonight;
      _pop = .35;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (status != RoundStatus.playing || isTutorial) return;
    if (anyBed) _drawBedGlow(canvas);
    final pill = _drawStatusPill(canvas);
    _drawToast(canvas, math.max(pill.bottom + 6, notificationTop));
    _drawGoals(canvas);
    if (night > 0) {
      _drawNightCard(canvas);
    }
  }

  Rect _drawStatusPill(Canvas canvas) {
    final screen = game.size;
    final timed = !isInfinite || night > 0;
    final lowTime = timed && secondsLeft <= 10;
    final parts = <(void Function(Canvas, Offset, Color), String, Color)>[
      if (timed) (_clockIcon, '${secondsLeft}s', lowTime ? _danger : _ink),
      if (night > 0) (_silverIcon, '$silver', _ink),
      if (night == 0)
        (_pawIcon, isInfinite ? '$delivered' : '$delivered/$totalCats', _ink),
      if (fishLeft != null && night == 0)
        (_fishIcon, '$fishLeft', fishLeft == 0 ? _danger : _ink),
    ];
    final labels = [
      for (final (_, text, color) in parts)
        _text(text, DS.fontBody, color, bold: true)
    ];
    const iconW = 16.0, gap = 4.0, sep = 13.0, padX = 11.0, h = 28.0;
    // Measure with the same font so 10 → 9 seconds stays stable on all devices.
    final clockTemplate = _text('000s', DS.fontBody, _ink, bold: true);
    final numberTemplate = _text('0000', DS.fontBody, _ink, bold: true);
    final clockWidth = math.max(34.0, clockTemplate.width);
    final numberWidth = math.max(38.0, numberTemplate.width);
    final widths = [
      for (var i = 0; i < labels.length; i++)
        math.max(labels[i].width, timed && i == 0 ? clockWidth : numberWidth),
    ];
    final width = widths.fold(0.0, (w, value) => w + iconW + gap + value) +
        sep * (parts.length - 1) +
        padX * 2;
    final box = Rect.fromCenter(
        center: Offset(screen.x / 2, 12 + h / 2), width: width, height: h);
    canvas.save();
    final shape = RRect.fromRectAndRadius(box, const Radius.circular(14));
    canvas.drawRRect(shape.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x44402616));
    canvas.drawRRect(shape, Paint()..color = const Color(0xF2FFF4DA));
    if (lowTime && parts.isNotEmpty) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(box.left + 4, box.top + 4,
                  padX - 4 + iconW + gap + widths.first + sep / 2, h - 8),
              const Radius.circular(9)),
          Paint()..color = const Color(0x22C0503A));
    }
    canvas.drawRRect(
        shape,
        Paint()
          ..color = _wood
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    var x = box.left + padX;
    for (var i = 0; i < parts.length; i++) {
      final (icon, _, color) = parts[i];
      icon(canvas, Offset(x + iconW / 2, box.center.dy), color);
      x += iconW + gap;
      labels[i].paint(
          canvas,
          Offset(x + (widths[i] - labels[i].width) / 2,
              box.center.dy - labels[i].height / 2));
      x += widths[i];
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

  /// Night-shift mission card, top right and compact: night number and
  /// count on one line, a segmented progress bar, and tiny twist chips.
  /// The full rules are available through the information button.
  void _drawNightCard(Canvas canvas) {
    final screen = game.size;
    const width = 132.0, pad = 7.0, barH = 7.0;
    const inner = width - pad * 2;
    final head = _text('ĐÊM $night', DS.fontBody, _ink, bold: true);
    final count = _text('$tonight/$totalCats', DS.fontBody,
        tonight >= totalCats ? DS.success : _ink,
        bold: true);
    final tags = [
      for (final tag in nightTags) _text(tag, DS.fontMicro, _cream, bold: true)
    ];
    const tagH = 13.0;
    final headH = math.max(head.height, count.height);
    final height = pad +
        headH +
        4 +
        barH +
        (arrivalHint.isEmpty ? 0 : 15) +
        (tags.isEmpty ? 0 : 5 + tagH) +
        pad;
    final box = Rect.fromLTWH(screen.x - width - 10, 10, width, height);
    final shape = RRect.fromRectAndRadius(box, const Radius.circular(10));
    canvas.drawRRect(shape.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x44402616));
    canvas.drawRRect(shape, Paint()..color = const Color(0xE6FFF4DA));
    canvas.drawRRect(
        shape,
        Paint()
          ..color = bossNight ? const Color(0xFFE85D6F) : _wood
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    var y = box.top + pad;
    _moonIcon(canvas, Offset(box.left + pad + 6, y + headH / 2), _ink);
    head.paint(
        canvas, Offset(box.left + pad + 15, y + (headH - head.height) / 2));
    final scale = 1 + math.max(0.0, _pop) / .35 * .3;
    canvas.save();
    canvas.translate(box.right - pad - count.width / 2, y + headH / 2);
    canvas.scale(scale);
    count.paint(canvas, Offset(-count.width / 2, -count.height / 2));
    canvas.restore();
    y += headH + 4;
    // One slot per cat tonight; the newest flashes.
    final gap = totalCats > 8 ? 1.5 : 2.5;
    final seg = (inner - gap * (totalCats - 1)) / math.max(1, totalCats);
    for (var i = 0; i < totalCats; i++) {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(box.left + pad + i * (seg + gap), y, seg, barH),
          const Radius.circular(3));
      final done = i < tonight;
      canvas.drawRRect(
          r,
          Paint()
            ..color = done ? const Color(0xFF6DBE63) : const Color(0x2E704019));
      if (done && i == tonight - 1 && _pop > 0) {
        canvas.drawRRect(
            r.inflate(_pop * 5),
            Paint()
              ..color =
                  const Color(0xFF6DBE63).withValues(alpha: _pop / .35 * .5));
      }
    }
    y += barH;
    if (arrivalHint.isNotEmpty) {
      final hint = _text(arrivalHint, DS.fontMicro, _ink);
      hint.paint(canvas, Offset(box.left + pad, y + 3));
      y += 15;
    }
    if (tags.isEmpty) return;
    y += 5;
    var x = box.left + pad;
    for (var i = 0; i < tags.length; i++) {
      final tag = tags[i];
      final w = tag.width + 8;
      if (x + w > box.right - pad) break;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, w, tagH), const Radius.circular(6.5)),
          Paint()
            ..color = nightTags[i] == 'Có trùm'
                ? const Color(0xFFE85D6F)
                : const Color(0xFF6B5A8E));
      tag.paint(canvas, Offset(x + 4, y + (tagH - tag.height) / 2));
      x += w + 3;
    }
  }

  /// Gold frame pulsing round the field while any bed takes any cat.
  void _drawBedGlow(Canvas canvas) {
    final screen = game.size;
    final alpha = .35 + math.sin(_clock * 6) * .15;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, screen.x, screen.y).deflate(3),
        Paint()
          ..color = _gold.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
  }

  void _drawToast(Canvas canvas, double top) {
    if (_toastTime <= 0 || _toast.isEmpty) return;
    final fade = (_toastTime.clamp(0.0, .35) / .35);
    final rise = (1 - fade) * -4;
    final screen = game.size;
    var y = top + rise;
    for (final line in _toast) {
      final label = _text(line, DS.fontCaption, _cream.withValues(alpha: fade),
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
    final screen = game.size;
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
        GoalKind.rightDish => s.wrongDishes > 0,
        GoalKind.quiet => s.retreats > 0,
        GoalKind.noDistract => s.distractions > 0,
        GoalKind.onBeat => s.offBeats > 0,
      };

  TextPainter _text(String text, double size, Color color,
          {bool bold = false,
          bool strike = false,
          double? maxWidth,
          int maxLines = 1}) =>
      TextCache.layout(
          text,
          TextStyle(
              color: color,
              fontSize: size,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              decoration: strike ? TextDecoration.lineThrough : null,
              decorationColor: color),
          maxWidth: maxWidth ?? double.infinity,
          maxLines: maxLines);

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

  static void _silverIcon(Canvas canvas, Offset c, Color color) =>
      paintSilverToken(
          canvas, Rect.fromCenter(center: c, width: 20, height: 20));

  static void _moonIcon(Canvas canvas, Offset c, Color color) {
    final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: 6.5)),
        Path()
          ..addOval(Rect.fromCircle(
              center: c + const Offset(3.5, -2.5), radius: 5.5)));
    canvas.drawPath(moon, Paint()..color = const Color(0xFFE0A93A));
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
