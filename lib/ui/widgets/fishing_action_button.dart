import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fishing_tool_art.dart';

export 'fishing_tool_art.dart' show FishingTool;

class FishingActionButton extends StatefulWidget {
  const FishingActionButton(
      {super.key,
      required this.tool,
      required this.tooltip,
      this.onPressed,
      this.onHoldChanged,
      this.active = false,
      this.alert = false,
      this.busy = false,
      this.primary = false,
      this.rotation = 0});
  final FishingTool tool;
  final String tooltip;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onHoldChanged;
  final bool active, alert, busy, primary;
  final double rotation;

  @override
  State<FishingActionButton> createState() => _FishingActionButtonState();
}

class _FishingActionButtonState extends State<FishingActionButton> {
  int? _heldPointer;
  bool _pressed = false;

  void _activate() {
    if (widget.onHoldChanged != null) {
      widget.onHoldChanged!(!widget.active);
    } else {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null || widget.onHoldChanged != null;
    final size = widget.primary ? 80.0 : 50.0;
    final artSize = widget.primary ? 44.0 : 50.0;
    final pressed = _pressed || widget.active;
    return Tooltip(
      message: widget.tooltip,
      // Holding the reel must not trigger a long-press tooltip or enter a tap arena.
      triggerMode: widget.onHoldChanged == null
          ? TooltipTriggerMode.longPress
          : TooltipTriggerMode.manual,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.tooltip,
        onTap: enabled ? _activate : null,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor:
              enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              _activate();
              return null;
            })
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (!enabled || _heldPointer != null) return;
              _heldPointer = event.pointer;
              setState(() => _pressed = true);
              widget.onHoldChanged?.call(true);
            },
            onPointerUp: (event) => _release(event.pointer),
            onPointerCancel: (event) => _release(event.pointer),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: enabled && widget.onHoldChanged == null
                  ? widget.onPressed
                  : null,
              child: SizedBox.square(
                  dimension: size,
                  child: Stack(alignment: Alignment.center, children: [
                    if (widget.primary)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 58,
                        height: 58,
                        transform:
                            Matrix4.translationValues(0, pressed ? 3 : 0, 0),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF365D56),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF29463F),
                                offset: Offset(0, pressed ? 1 : 5)),
                            BoxShadow(
                                color: const Color(0x44302E23),
                                offset: const Offset(0, 7),
                                blurRadius: pressed ? 3 : 9),
                          ],
                        ),
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                          color: !enabled && !widget.busy
                              ? const Color(0xFFC9CDBD)
                              : widget.alert
                                  ? const Color(0xFFFFBD8A)
                                  : pressed
                                      ? const Color(0xFFB9E2CC)
                                      : const Color(0xFFFFE8B5),
                          border: Border.all(
                              color: const Color(0xFFFFF8DE), width: 2),
                          borderRadius: BorderRadius.circular(5),
                        )),
                      ),
                    SizedBox.square(
                        dimension: artSize,
                        child: AnimatedScale(
                            scale: pressed ? .94 : 1,
                            duration: const Duration(milliseconds: 100),
                            child: Opacity(
                                opacity: enabled || widget.busy ? 1 : .45,
                                child: CustomPaint(
                                    painter: FishingToolArt(
                                        tool: widget.tool,
                                        rotation: widget.rotation,
                                        active: widget.active,
                                        alert: widget.alert))))),
                    if (widget.busy)
                      const Positioned(
                          right: 10,
                          bottom: 8,
                          child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF365F56)))),
                  ])),
            ),
          ),
        ),
      ),
    );
  }

  void _release(int pointer) {
    if (_heldPointer != pointer) return;
    _heldPointer = null;
    setState(() => _pressed = false);
    widget.onHoldChanged?.call(false);
  }
}
