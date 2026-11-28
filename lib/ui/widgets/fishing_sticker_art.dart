import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../online/fishing_sticker.dart';

/// One cell of a horizontal sticker sheet (square cells).
class FishingStickerArt extends StatelessWidget {
  const FishingStickerArt(this.asset, this.index, this.count,
      {super.key, this.size = 56, this.flip = false});
  final String asset;
  final int index, count;
  final double size;
  final bool flip;
  @override
  Widget build(BuildContext context) {
    Widget art = SizedBox.square(
        dimension: size,
        child: ClipRect(
            child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: size * count,
                maxWidth: size * count,
                minHeight: size,
                maxHeight: size,
                child: Transform.translate(
                    offset: Offset(-index * size, 0),
                    child: Image.asset(asset,
                        width: size * count,
                        height: size,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium)))));
    if (flip) art = Transform.flip(flipX: true, child: art);
    return art;
  }
}

/// Two cats meeting: [left] faces right, [right] is mirrored to face left.
/// With [animate] the halves slide in, bump together, keep a small
/// per-interaction motion and fade out before the bubble expires.
class FishingInteractionArt extends StatefulWidget {
  const FishingInteractionArt(
      {super.key,
      required this.index,
      required this.left,
      required this.right,
      this.size = 64,
      this.animate = false});
  final int index;
  final String left, right;
  final double size;
  final bool animate;
  @override
  State<FishingInteractionArt> createState() => _FishingInteractionArtState();
}

class _FishingInteractionArtState extends State<FishingInteractionArt>
    with SingleTickerProviderStateMixin {
  static const _life = 6.0;
  late final AnimationController _clock = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 6000));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _clock.forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Widget _half(String asset, bool flip) =>
      FishingStickerArt(asset, widget.index, FishingSticker.interactions.length,
          size: widget.size, flip: flip);

  @override
  Widget build(BuildContext context) {
    final size = widget.size, overlap = size * .07;
    if (!widget.animate) {
      return SizedBox(
          width: size * 2,
          height: size,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: overlap, top: 0, child: _half(widget.left, false)),
            Positioned(
                left: size - overlap, top: 0, child: _half(widget.right, true)),
          ]));
    }
    return AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          final t = _clock.value * _life;
          // Slide in from both sides with a little overshoot.
          final enter = Curves.easeOutBack.transform((t / .45).clamp(0, 1));
          final gap = (1 - enter) * size * .55;
          // Bump on contact: a quick squash and pop.
          final hit = ((t - .4) / .3).clamp(0.0, 1.0);
          final bump = math.sin(hit * math.pi) * .1;
          final idle = math.max(0.0, t - .7);
          var dy = 0.0, lean = 0.0, scale = 1.0;
          switch (widget.index) {
            case 0: // High five: hop up together.
              dy = -math.sin(hit * math.pi) * size * .12 -
                  (math.sin(idle * 4).abs() * size * .025);
            case 1: // Hug: squeeze closer and sway.
              lean = math.sin(idle * 3) * size * .03 + size * .02;
            case 3: // Cheek rub: rub up and down against each other.
              dy = math.sin(idle * 11) * size * .035;
            case 4: // Lean to sleep: slow breathing.
              scale = 1 + math.sin(idle * 2.4) * .025;
            default: // Share a fish: gentle bob.
              dy = math.sin(idle * 3.2) * size * .03;
          }
          final fade =
              (1 - (t - 5.4) / .6).clamp(0.0, 1.0) * (t / .2).clamp(0.0, 1.0);
          Widget place(String asset, bool right) {
            final side = right ? 1.0 : -1.0;
            // The cheek rub moves the halves in opposite directions.
            final y = widget.index == 3 && right ? -dy : dy;
            return Positioned(
                left: (right ? size - overlap : overlap) + side * (gap - lean),
                top: y,
                child: Transform.scale(
                    scale: (1 + bump) * scale,
                    alignment: Alignment.bottomCenter,
                    child: _half(asset, right)));
          }

          return Opacity(
              opacity: fade,
              child: SizedBox(
                  width: size * 2,
                  height: size,
                  child: Stack(clipBehavior: Clip.none, children: [
                    place(widget.left, false),
                    place(widget.right, true),
                  ])));
        });
  }
}
