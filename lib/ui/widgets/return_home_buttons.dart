import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/cats/cat_breed.dart';
import '../../game/skill_glyph.dart';
import 'game_glyphs.dart';
import 'skill_glyphs.dart';

const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);
const _wood = Color(0xFFB27A3E);

/// Round game button with a darker base underneath; sinks when pressed.
class RoundGameButton extends StatefulWidget {
  const RoundGameButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.size = 52,
    this.face = _cream,
    this.base = _wood,
  });
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final double size;
  final Color face, base;

  @override
  State<RoundGameButton> createState() => _RoundGameButtonState();
}

class _RoundGameButtonState extends State<RoundGameButton> {
  static const _depth = 4.0;
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onPressed,
          child: SizedBox(
            width: widget.size,
            height: widget.size + _depth,
            child: Stack(children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: widget.size,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: widget.base,
                        shape: BoxShape.circle,
                        boxShadow: const [
                      BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 5,
                          offset: Offset(0, 3))
                    ])),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                left: 0,
                right: 0,
                top: _down ? _depth : 0,
                height: widget.size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: widget.face,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.base, width: 3)),
                  child: Center(child: widget.child),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class ReturnHomeHomeButton extends StatelessWidget {
  const ReturnHomeHomeButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => RoundGameButton(
        tooltip: 'Về Trang chủ',
        onPressed: onPressed,
        face: const Color(0xFFFFC24D),
        base: const Color(0xFF9A6028),
        child: const GameGlyphView(GameGlyph.home, size: 30),
      );
}

/// Skill button tinted per cat, with a cooldown sweep around the rim.
class ReturnHomeSkillButton extends StatelessWidget {
  const ReturnHomeSkillButton({
    super.key,
    required this.catType,
    required this.ready,
    required this.cooldownLeft,
    required this.cooldownTotal,
    required this.onPressed,
    this.size = 76,
  });
  final String catType;
  final double size;
  final bool ready;
  final double cooldownLeft, cooldownTotal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final skill = CatBreed.of(catType).homeSkill;
    final (glyph, color, label) = (skill.glyph, skill.color, skill.label);
    final left = cooldownTotal <= 0
        ? 0.0
        : (cooldownLeft / cooldownTotal).clamp(0.0, 1.0);
    return RoundGameButton(
      tooltip: label,
      size: size,
      face: ready ? color : const Color(0xFFB9AE9C),
      base: ready
          ? Color.lerp(color, Colors.black, .35)!
          : const Color(0xFF7D7365),
      onPressed: ready ? onPressed : null,
      child: Stack(alignment: Alignment.center, children: [
        if (ready) SkillGlyphView(glyph, size: size * .6),
        if (!ready) ...[
          SizedBox.square(
              dimension: size - 12,
              child: CustomPaint(painter: _CooldownPainter(left, color))),
          Text('${cooldownLeft.ceil()}',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: _ink, blurRadius: 3)])),
        ],
      ]),
    );
  }
}

class _CooldownPainter extends CustomPainter {
  const _CooldownPainter(this.left, this.color);
  final double left;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        rect, 0, math.pi * 2, false, stroke..color = const Color(0x55FFFFFF));
    // The filled part grows as the cooldown runs out.
    canvas.drawArc(rect, -math.pi / 2, (1 - left) * math.pi * 2, false,
        stroke..color = color);
  }

  @override
  bool shouldRepaint(covariant _CooldownPainter old) =>
      left != old.left || color != old.color;
}

/// Skill button in the style of mobile MOBAs:
/// - tap: casts at once with auto-aim, no preview;
/// - press and hold, or start dragging: the skill's range shows in the world
///   ([onAim]); dragging steers it, releasing casts;
/// - release over [cancelKey] (the X shown while aiming): cancels.
///
/// The drag is measured from where the finger went down, not from the button
/// center, so an off-center press never jumps the aim.
class ReturnHomeAimButton extends StatefulWidget {
  const ReturnHomeAimButton({
    super.key,
    required this.label,
    required this.glyph,
    required this.color,
    required this.cooldownLeft,
    required this.cooldownTotal,
    required this.onAim,
    required this.onCast,
    required this.onCancel,
    this.size = 62,
    this.aimable = true,
    this.activeLeft = 0,
    this.cancelKey,
    this.onCancelHover,
  });
  final String label;
  final SkillGlyph glyph;
  final Color color;
  final double cooldownLeft, cooldownTotal;

  /// Stick: direction of the drag, length 0..1 of the full range. Zero means
  /// "not steered yet" (auto-aim).
  final ValueChanged<Offset> onAim;
  final ValueChanged<Offset?> onCast;
  final VoidCallback onCancel;
  final double size;

  /// False for self-cast skills: holding shows the area, dragging does not
  /// steer (but can still reach the cancel button).
  final bool aimable;

  /// Seconds left on an active effect; shown as a bright halo while > 0.
  final double activeLeft;

  final GlobalKey? cancelKey;
  final ValueChanged<bool>? onCancelHover;

  @override
  State<ReturnHomeAimButton> createState() => _ReturnHomeAimButtonState();
}

class _ReturnHomeAimButtonState extends State<ReturnHomeAimButton> {
  /// Holding this long without moving opens the range preview.
  static const _holdDelay = Duration(milliseconds: 170);

  /// Finger travel (px) that still counts as a tap / as "not steered".
  static const double _slop = 9;

  /// Finger travel (px) for a full-range aim. Short on purpose: a small thumb
  /// flick covers the whole range.
  static const double _reach = 80;

  int? _pointer;
  Offset _origin = Offset.zero;
  Offset _stick = Offset.zero;
  bool _aiming = false;
  bool _overCancel = false;
  Timer? _hold;

  bool get _ready => widget.cooldownLeft <= 0;

  /// Drag vector -> stick. Inside the slop it stays zero (auto-aim); past it
  /// the length grows linearly to 1 at [_reach].
  Offset _toStick(Offset drag) {
    final length = drag.distance;
    if (length < _slop) return Offset.zero;
    final t = ((length - _slop) / (_reach - _slop)).clamp(.02, 1.0);
    return drag / length * t;
  }

  bool _hitsCancel(Offset global) {
    final box = widget.cancelKey?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.inflate(16).contains(global);
  }

  void _setCancel(bool v) {
    if (_overCancel == v) return;
    _overCancel = v;
    widget.onCancelHover?.call(v);
  }

  void _beginAim() {
    if (_pointer == null || _aiming || !mounted) return;
    setState(() => _aiming = true);
    widget.onAim(_stick);
  }

  void _down(PointerDownEvent e) {
    if (!_ready || _pointer != null) return;
    _pointer = e.pointer;
    _origin = e.localPosition;
    _stick = Offset.zero;
    _aiming = false;
    _hold?.cancel();
    _hold = Timer(_holdDelay, _beginAim);
    setState(() {});
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final drag = e.localPosition - _origin;
    if (widget.aimable) _stick = _toStick(drag);
    if (!_aiming) {
      if (drag.distance < _slop) return;
      _hold?.cancel();
      _beginAim();
      return;
    }
    _setCancel(_hitsCancel(e.position));
    if (!widget.aimable) return;
    setState(() {});
    widget.onAim(_stick);
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    final aimed = _aiming;
    final cancel = _overCancel;
    final stick = _stick;
    _reset();
    if (cancel) {
      widget.onCancel();
    } else {
      // A tap casts with auto-aim; a released drag casts where it points.
      widget.onCast(
          aimed && widget.aimable && stick != Offset.zero ? stick : null);
    }
  }

  void _reset() {
    _hold?.cancel();
    _hold = null;
    _setCancel(false);
    setState(() {
      _pointer = null;
      _aiming = false;
      _stick = Offset.zero;
    });
  }

  @override
  void didUpdateWidget(covariant ReturnHomeAimButton old) {
    super.didUpdateWidget(old);
    // The skill changed under a held finger: drop the aim.
    if (old.glyph != widget.glyph && _pointer != null) {
      final wasAiming = _aiming;
      _reset();
      if (wasAiming) widget.onCancel();
    }
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ready;
    final left = widget.cooldownTotal <= 0
        ? 0.0
        : (widget.cooldownLeft / widget.cooldownTotal).clamp(0.0, 1.0);
    final color = widget.color;
    final held = _pointer != null;
    final ringReach = widget.size * .8;
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: (e) {
          if (e.pointer != _pointer) return;
          final wasAiming = _aiming;
          _reset();
          if (wasAiming) widget.onCancel();
        },
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            // Drawn outside the button bounds while aiming: the drag ring.
            foregroundPainter: _aiming && widget.aimable
                ? _AimRingPainter(_stick, ringReach, color)
                : null,
            child: AnimatedScale(
              scale: held ? .92 : 1,
              duration: const Duration(milliseconds: 80),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ready ? color : const Color(0xFFB9AE9C),
                  border: Border.all(
                      color: ready
                          ? Color.lerp(color, Colors.black, .35)!
                          : const Color(0xFF7D7365),
                      width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 5,
                        offset: Offset(0, 3))
                  ],
                ),
                child: Stack(alignment: Alignment.center, children: [
                  if (widget.activeLeft > 0)
                    SizedBox.square(
                        dimension: widget.size + 10,
                        child: const DecoratedBox(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                              BoxShadow(
                                  color: Color(0xAAFFF4A0),
                                  blurRadius: 10,
                                  spreadRadius: 2)
                            ]))),
                  if (ready)
                    SkillGlyphView(widget.glyph, size: widget.size * .66),
                  if (!ready) ...[
                    Opacity(
                        opacity: .35,
                        child: SkillGlyphView(widget.glyph,
                            size: widget.size * .66)),
                    SizedBox.square(
                        dimension: widget.size - 10,
                        child: CustomPaint(
                            painter: _CooldownPainter(left, color))),
                    Text('${widget.cooldownLeft.ceil()}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [Shadow(color: _ink, blurRadius: 3)])),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The X that appears while a skill is held; drag onto it to cancel.
class ReturnHomeCancelButton extends StatelessWidget {
  const ReturnHomeCancelButton({super.key, required this.hot});
  final bool hot;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: hot ? 60 : 48,
        height: hot ? 60 : 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hot ? const Color(0xCCE0483F) : const Color(0x88203040),
          border: Border.all(
              color: hot ? Colors.white : const Color(0xCCDDEEFF), width: 3),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
      );
}

class _AimRingPainter extends CustomPainter {
  const _AimRingPainter(this.stick, this.reach, this.color);
  final Offset stick;
  final double reach;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, reach, Paint()..color = const Color(0x33FFFFFF));
    canvas.drawCircle(
        c,
        reach,
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final knob = c + stick * reach;
    canvas.drawCircle(knob, size.width * .3, Paint()..color = color);
    canvas.drawCircle(
        knob,
        size.width * .3,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _AimRingPainter old) =>
      stick != old.stick || color != old.color;
}
