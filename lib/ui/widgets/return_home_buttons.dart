import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/cats/cat_breed.dart';

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
        child: const Icon(Icons.home_rounded, size: 28, color: _ink),
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
  });
  final String catType;
  final bool ready;
  final double cooldownLeft, cooldownTotal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final skill = CatBreed.of(catType).homeSkill;
    final (icon, color, label) = (skill.icon, skill.color, skill.label);
    final left = cooldownTotal <= 0
        ? 0.0
        : (cooldownLeft / cooldownTotal).clamp(0.0, 1.0);
    return RoundGameButton(
      tooltip: label,
      size: 76,
      face: ready ? color : const Color(0xFFB9AE9C),
      base: ready
          ? Color.lerp(color, Colors.black, .35)!
          : const Color(0xFF7D7365),
      onPressed: ready ? onPressed : null,
      child: Stack(alignment: Alignment.center, children: [
        if (ready) Icon(icon, size: 38, color: Colors.white),
        if (!ready) ...[
          SizedBox.square(
              dimension: 64,
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
