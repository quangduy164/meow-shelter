import 'dart:ui';

import 'package:flame/components.dart';

import 'cat_component.dart';

/// A shelter sprite with a smaller doorway hit area used to receive cats.
class ShelterZoneComponent extends SpriteComponent {
  ShelterZoneComponent({
    required super.sprite,
    required super.position,
    required super.size,
    required this.catType,
  }) : super(priority: -10);

  final String catType;

  bool accepts(CatComponent cat) {
    if (cat.catType != catType) return false;
    final catCenter = cat.position + cat.size / 2;
    final bedCenter = position + Vector2(size.x * 0.5, size.y * 0.52);
    final bedSize = Vector2(size.x * 0.62, size.y * 0.28);
    final bed = Rect.fromCenter(
      center: Offset(bedCenter.x, bedCenter.y),
      width: bedSize.x,
      height: bedSize.y,
    );
    return bed.contains(Offset(catCenter.x, catCenter.y));
  }
}
