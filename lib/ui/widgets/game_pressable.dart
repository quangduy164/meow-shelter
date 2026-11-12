import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../design.dart';

/// Shared raised control. InkWell supplies keyboard, focus and tap semantics;
/// gesture-specific controls (aiming and holding a reel) keep their own input.
class GamePressable extends StatefulWidget {
  const GamePressable({
    super.key,
    this.width,
    required this.height,
    required this.color,
    required this.shade,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.circle = false,
    this.gradient = true,
    this.radius = DS.radiusCard,
    this.depth = DS.featureDepth,
  });

  final double? width;
  final double height, radius, depth;
  final Color color, shade;
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final bool circle, gradient;

  @override
  State<GamePressable> createState() => _GamePressableState();
}

class _GamePressableState extends State<GamePressable> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  void didUpdateWidget(covariant GamePressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) _down = false;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = enabled ? widget.color : DS.mutedFill;
    final edge = enabled ? widget.shade : DS.mutedBorder;
    final shape = widget.circle ? BoxShape.circle : BoxShape.rectangle;
    final radius = widget.circle ? null : BorderRadius.circular(widget.radius);
    final border = widget.circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: radius!);
    final control = Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        width: widget.width,
        height: widget.height + widget.depth,
        child: Stack(children: [
          Positioned.fill(
            top: widget.depth,
            child: DecoratedBox(
                decoration: BoxDecoration(
              color: edge,
              shape: shape,
              borderRadius: radius,
              boxShadow: DS.controlShadow,
            )),
          ),
          AnimatedPositioned(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : DS.pressDuration,
            left: 0,
            right: 0,
            top: _down && enabled ? widget.depth : 0,
            height: widget.height,
            child: Material(
              type: MaterialType.transparency,
              shape: border,
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  color: widget.gradient ? null : face,
                  gradient: widget.gradient
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color.lerp(face, Colors.white, .18)!, face],
                        )
                      : null,
                  shape: shape,
                  borderRadius: radius,
                  border: Border.all(color: edge, width: DS.borderRaised),
                ),
                child: InkWell(
                  customBorder: border,
                  onTapDown: enabled ? (_) => _setDown(true) : null,
                  onTapUp: enabled ? (_) => _setDown(false) : null,
                  onTapCancel: () => _setDown(false),
                  onTap: enabled
                      ? () {
                          GameAudio.instance.play(GameSound.click);
                          widget.onPressed!();
                        }
                      : null,
                  focusColor: DS.gold.withOpacity(.3),
                  hoverColor: DS.cream.withOpacity(.12),
                  child: IconTheme.merge(
                    data: IconThemeData(color: enabled ? DS.ink : DS.mutedText),
                    child: DefaultTextStyle.merge(
                      style: DS.buttonText
                          .copyWith(color: enabled ? DS.ink : DS.mutedText),
                      child: Center(child: widget.child),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
    return widget.tooltip == null
        ? control
        : Tooltip(message: widget.tooltip!, child: control);
  }
}

class RoundGameButton extends StatelessWidget {
  const RoundGameButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.size = DS.touchTarget,
    this.face = DS.cream,
    this.base = DS.wood,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final double size;
  final Color face, base;

  @override
  Widget build(BuildContext context) => GamePressable(
        width: size,
        height: size,
        color: face,
        shade: base,
        onPressed: onPressed,
        tooltip: tooltip,
        circle: true,
        gradient: false,
        depth: DS.buttonDepth,
        child: child,
      );
}
