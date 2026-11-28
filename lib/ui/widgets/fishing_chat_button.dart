import 'dart:async';
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import '../../online/fishing_chat.dart';
import '../../online/fishing_sticker.dart';
import '../design.dart';
import 'round_button.dart';
import 'fishing_sticker_art.dart';

/// Tap opens chat; dragging immediately selects a sticker without a hold delay.
class FishingChatButton extends StatefulWidget {
  const FishingChatButton(
      {super.key,
      required this.chat,
      required this.onPressed,
      required this.name,
      required this.cat,
      required this.partner});
  final FishingChat chat;
  final VoidCallback onPressed;
  final String Function() name;
  final String cat;
  final String? Function() partner;
  @override
  State<FishingChatButton> createState() => _FishingChatButtonState();
}

class _FishingChatButtonState extends State<FishingChatButton>
    with WidgetsBindingObserver {
  OverlayEntry? _menu;
  Offset _center = Offset.zero, _origin = Offset.zero;
  int? _selected;
  String? _partner;
  bool _moved = false;
  static const _size = 284.0, _inner = 60.0, _outer = 111.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.chat.addListener(_chatChanged);
  }

  void _chatChanged() {
    if (widget.chat.uid == null || !widget.chat.ready) _close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _close();
  }

  @override
  void didUpdateWidget(covariant FishingChatButton old) {
    super.didUpdateWidget(old);
    if (old.chat != widget.chat) {
      old.chat.removeListener(_chatChanged);
      widget.chat.addListener(_chatChanged);
      _close();
    }
    if (old.cat != widget.cat) _close();
  }

  @override
  void dispose() {
    _close();
    widget.chat.removeListener(_chatChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _close() {
    _menu?.remove();
    _menu?.dispose();
    _menu = null;
    _selected = null;
    _partner = null;
    _moved = false;
  }

  Offset _point(int index) {
    final outer = index >= FishingSticker.emoteCount;
    final i = outer ? index - FishingSticker.emoteCount : index;
    final count =
        outer ? FishingSticker.interactions.length : FishingSticker.emoteCount;
    final angle = -math.pi / 2 + 2 * math.pi * i / count;
    return Offset(math.cos(angle), math.sin(angle)) * (outer ? _outer : _inner);
  }

  void _open(Offset globalPosition) {
    _close();
    final box = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final screen = box.size;
    _origin = box.globalToLocal(globalPosition);
    final pad = MediaQuery.paddingOf(context);
    double fit(double value, double low, double high) =>
        high < low ? (low + high) / 2 : value.clamp(low, high);
    _center = Offset(
        fit(_origin.dx - 90, pad.left + _size / 2 + 8,
            screen.width - pad.right - _size / 2 - 8),
        fit(_origin.dy, pad.top + _size / 2 + 8,
            screen.height - pad.bottom - _size / 2 - 8));
    _partner = widget.partner();
    _menu = OverlayEntry(
        builder: (context) => Positioned(
            left: _center.dx - _size / 2,
            top: _center.dy - _size / 2,
            width: _size,
            height: _size,
            child: IgnorePointer(
                child: Material(
                    type: MaterialType.transparency, child: _wheel()))));
    Overlay.of(context).insert(_menu!);
  }

  void _move(Offset globalPosition) {
    if (_menu == null) return;
    final box = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final pointer = box.globalToLocal(globalPosition);
    _moved = _moved || (pointer - _origin).distance > 8;
    int? selected;
    var distance = 27.0;
    if (_moved) {
      for (var i = 0;
          i < FishingSticker.emoteCount + FishingSticker.interactions.length;
          i++) {
        final d = (pointer - _center - _point(i)).distance;
        if (d < distance &&
            (i < FishingSticker.emoteCount || _partner != null)) {
          selected = i;
          distance = d;
        }
      }
    }
    if (selected != _selected) {
      _selected = selected;
      _menu?.markNeedsBuild();
    }
  }

  Future<void> _release() async {
    final selected = _selected, partner = _partner;
    _close();
    if (selected == null) return;
    final token = selected < FishingSticker.emoteCount
        ? FishingSticker.emote(widget.cat, selected)
        : partner == null
            ? null
            : FishingSticker.interact(
                selected - FishingSticker.emoteCount, widget.cat, partner);
    if (token == null) return;
    final ok = await widget.chat.send(token, name: widget.name());
    if (!ok && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(widget.chat.error ?? 'Chat chưa sẵn sàng.'),
          duration: const Duration(seconds: 2)));
    }
  }

  Widget _wheel() {
    final labels =
        FishingSticker.emotes[widget.cat] ?? FishingSticker.emotes['orange']!;
    final title = _selected == null
        ? 'Kéo để chọn'
        : _selected! < FishingSticker.emoteCount
            ? labels[_selected!]
            : FishingSticker
                .interactions[_selected! - FishingSticker.emoteCount];
    return Stack(key: const ValueKey('chat-emote-wheel'), children: [
      for (final radius in [_outer, _inner])
        Positioned(
            left: _size / 2 - radius - 22,
            top: _size / 2 - radius - 22,
            width: (radius + 22) * 2,
            height: (radius + 22) * 2,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x80172E3B),
                    border: Border.all(color: const Color(0x5578CED8))))),
      Center(
          child: SizedBox(
              width: 70,
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black, blurRadius: 3)])))),
      for (var i = 0;
          i < FishingSticker.emoteCount + FishingSticker.interactions.length;
          i++)
        Positioned(
            key: ValueKey('chat-wheel-item:$i'),
            left: _size / 2 + _point(i).dx - 22,
            top: _size / 2 + _point(i).dy - 22,
            width: 44,
            height: 44,
            child: Opacity(
                opacity:
                    i < FishingSticker.emoteCount || _partner != null ? 1 : .3,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selected == i
                            ? const Color(0xFF78CED8)
                            : const Color(0xCC243F4B),
                        border: Border.all(
                            color: _selected == i
                                ? const Color(0xFFFFDE85)
                                : const Color(0x5578CED8),
                            width: 2)),
                    child: Center(
                        child: i < FishingSticker.emoteCount
                            ? FishingStickerArt(
                                FishingSticker.emoteSheet(widget.cat),
                                i,
                                FishingSticker.emoteCount,
                                size: 38)
                            : FishingInteractionArt(
                                index: i - FishingSticker.emoteCount,
                                left: FishingSticker.interactSheet(widget.cat),
                                right: FishingSticker.interactSheet(widget.cat),
                                size: 20))))),
    ]);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTap: widget.onPressed,
      onPanStart: (details) => _open(details.globalPosition),
      onPanUpdate: (details) => _move(details.globalPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _close,
      child: IgnorePointer(
          child: AnimatedBuilder(
              animation: widget.chat,
              builder: (context, _) =>
                  Stack(clipBehavior: Clip.none, children: [
                    FlatRoundButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        tooltipTriggerMode: TooltipTriggerMode.manual,
                        tooltip: 'Trò chuyện trong phòng',
                        onPressed: widget.onPressed),
                    if (widget.chat.unread > 0)
                      Positioned(
                          right: -3,
                          top: -3,
                          child: IgnorePointer(
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: DS.goldEdge,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text('${widget.chat.unread}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800))))),
                  ]))));
}
