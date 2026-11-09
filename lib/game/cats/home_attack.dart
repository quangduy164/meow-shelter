import 'package:flutter/painting.dart';

import '../skill_glyph.dart';

/// How a skill is aimed while its button is held, and so which range preview
/// the world shows (MOBA style).
enum AimShape {
  /// Skill shot along a lane: [HomeAttack.range] long, 2x[HomeAttack.radius]
  /// wide.
  line,

  /// Cone in front of the cat: [HomeAttack.range] deep, [HomeAttack.radius]
  /// is the half angle in radians.
  cone,

  /// Ground circle of [HomeAttack.radius] placed anywhere within
  /// [HomeAttack.range].
  area,

  /// A wall [HomeAttack.radius] long placed within [HomeAttack.range],
  /// standing across the aim direction.
  wall,

  /// Teleport to a point within [HomeAttack.range].
  blink,

  /// Centered on the cat, [HomeAttack.radius] around it. No aiming.
  self,

  /// Affects everything on screen. No aiming.
  global,
}

/// The three secondary skills each breed carries in Return Home. Pure data:
/// numbers the game, the range preview and the buttons all read, so what the
/// player sees while aiming is exactly what the skill does.
enum HomeAttack {
  // ---- Mèo cam: lửa ----
  fireball(
      'Cầu lửa', SkillGlyph.fireball, Color(0xFFF0663A), 2.5, AimShape.line,
      range: 380, radius: 12),
  flameBreath(
      'Phun lửa', SkillGlyph.flameBreath, Color(0xFFE8452C), 7, AimShape.cone,
      range: 160, radius: .55, duration: 1.1),
  fireBomb('Bom lửa', SkillGlyph.fireBomb, Color(0xFFC2402A), 9, AimShape.area,
      range: 260, radius: 58, duration: 2.5),

  // ---- Mèo đen: bóng tối, thời gian ----
  shadowStep('Dịch chuyển bóng', SkillGlyph.shadowStep, Color(0xFF5B4A9E), 6,
      AimShape.blink,
      range: 210, radius: 22),
  decoy('Phân thân', SkillGlyph.decoy, Color(0xFF7B5FC4), 11, AimShape.area,
      range: 200, radius: 110, duration: 4),
  timeStop('Ngưng thời gian', SkillGlyph.timeStop, Color(0xFF3D6FA8), 20,
      AimShape.global,
      duration: 3),

  // ---- Himalaya: băng ----
  iceShard('Mũi băng', SkillGlyph.iceShard, Color(0xFF3FA6D6), 4, AimShape.line,
      range: 420, radius: 14, duration: 3),
  frostNova('Vùng băng giá', SkillGlyph.frostNova, Color(0xFF5AB8E0), 10,
      AimShape.self,
      radius: 140, duration: 3),
  iceBridge(
      'Cầu băng', SkillGlyph.iceBridge, Color(0xFF2E8FB8), 14, AimShape.line,
      range: 240, radius: 28, duration: 6),

  // ---- Scottish: đỡ đòn ----
  roar('Tiếng gầm', SkillGlyph.roar, Color(0xFFE0A030), 7, AimShape.self,
      radius: 150),
  stoneWall(
      'Tường đá', SkillGlyph.stoneWall, Color(0xFF8A7560), 9, AimShape.wall,
      range: 220, radius: 110, duration: 5),
  reflect('Phản đòn', SkillGlyph.reflect, Color(0xFF4FA89A), 12, AimShape.self,
      radius: 44, duration: 4),

  // ---- Tam thể: hỗ trợ, may mắn ----
  magnet(
      'Móng nam châm', SkillGlyph.magnet, Color(0xFFD9475A), 14, AimShape.self,
      radius: 170, duration: 6),
  catEye('Mắt mèo', SkillGlyph.catEye, Color(0xFFD9A420), 13, AimShape.self,
      radius: 200, duration: 6),
  bolt('Sấm sét', SkillGlyph.bolt, Color(0xFF4F7BD9), 10, AimShape.area,
      range: 300, radius: 62);

  const HomeAttack(
    this.label,
    this.glyph,
    this.color,
    this.cooldown,
    this.shape, {
    this.range = 0,
    this.radius = 0,
    this.duration = 0,
  });

  final String label;
  final SkillGlyph glyph;
  final Color color;
  final double cooldown;
  final AimShape shape;
  final double range;
  final double radius;

  /// How long the effect lasts (buff, burning zone, freeze...), 0 if instant.
  final double duration;

  /// Whether dragging the button steers the skill.
  bool get aimable => shape != AimShape.self && shape != AimShape.global;
}
