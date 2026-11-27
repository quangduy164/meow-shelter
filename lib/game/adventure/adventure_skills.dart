import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../cats/home_attack.dart';
import '../cats/cat_state.dart';
import '../constants.dart';
import 'adventure_obstacle.dart';

part 'adventure_projectiles.dart';
part 'adventure_fire_effects.dart';
part 'adventure_shadow_effects.dart';
part 'adventure_ice_effects.dart';
part 'adventure_earth_effects.dart';
part 'adventure_support_effects.dart';
part 'adventure_aim_indicator.dart';

/// World-side effects of the Adventure secondary skills (see
/// [HomeAttack]). Every effect only knows how to move and how to look; the
/// game decides what it hits. Shapes drawn here use the same numbers the game
/// hits with, so what the player sees is what lands.

final double fireballRange = HomeAttack.fireball.range;
final double fireballRadius = HomeAttack.fireball.radius;
const double fireballSpeed = 520;
const double iceShardSpeed = 660;

final double boltRange = HomeAttack.bolt.range;
final double boltRadius = HomeAttack.bolt.radius;
const double boltDelay = .45;

final double roarRadius = HomeAttack.roar.radius;
const double roarPush = 400;

final double magnetRadius = HomeAttack.magnet.radius;
final double magnetDuration = HomeAttack.magnet.duration;
const double magnetPull = 380;

/// Fire breath and burning zones hurt in pulses this far apart.
const double fireTick = .2;

/// How long the fire bomb flies before it lands.
const double bombFlight = .45;

/// Speed of hazards inside the cat-eye aura.
const double catEyeSlow = .45;

/// Ground ellipses are flattened like the lane (2.5D view).
const double groundSquash = .6;

/// Ground-zone test shared by every flattened area effect.
bool inGroundEllipse(Vector2 p, Vector2 center, double radius,
    {double margin = 14}) {
  final dx = (p.x - center.x) / (radius + margin);
  final dy = (p.y - center.y) / (radius * groundSquash + margin);
  return dx * dx + dy * dy <= 1;
}

Rect groundEllipse(Vector2 center, double radius) => Rect.fromCenter(
    center: Offset(center.x, center.y),
    width: radius * 2,
    height: radius * 2 * groundSquash);

Color _a(Color c, double alpha) =>
    c.withAlpha((255 * alpha.clamp(0.0, 1.0)).round());
