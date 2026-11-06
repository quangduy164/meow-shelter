import 'package:flutter/material.dart';

import '../../game/cats/cat_breed.dart';

/// One frame of a cat sprite sheet. Sheets are [frames] square cells laid out
/// side by side; this crops out cell [frame]. Use it everywhere a cat is drawn
/// with Flutter widgets so cropping never drifts between screens.
class CatSprite extends StatelessWidget {
  const CatSprite({
    super.key,
    required this.type,
    this.action = 'idle',
    this.frames = 6,
    this.frame = 0,
    this.flip = false,
    this.size = 80,
  });

  final String type;

  /// Sheet name, e.g. "idle", "walk", "drop-success".
  final String action;
  final int frames;
  final int frame;
  final bool flip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final breed = CatBreed.of(type);
    return Transform.flip(
      flipX: flip,
      child: SizedBox.square(
        dimension: size,
        child: ClipRect(
          child: OverflowBox(
            maxWidth: size * frames,
            maxHeight: size,
            alignment:
                Alignment(frames <= 1 ? -1 : -1 + 2 * frame / (frames - 1), 0),
            child: Image.asset('assets/images/${breed.sheet(action)}',
                width: size * frames,
                height: size,
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => SizedBox.square(
                    dimension: size,
                    child: CircleAvatar(backgroundColor: breed.color))),
          ),
        ),
      ),
    );
  }
}

/// A breed's first idle frame in a round badge (chooser buttons, chapters).
class CatFace extends StatelessWidget {
  const CatFace(this.type,
      {super.key, this.size = 46, this.border, this.background});
  final String type;
  final double size;
  final Color? border;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border:
                border == null ? null : Border.all(color: border!, width: 2)),
        child: ClipOval(child: CatSprite(type: type, size: size)),
      );
}
