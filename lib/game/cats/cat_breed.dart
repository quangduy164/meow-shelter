import 'package:flutter/material.dart';

import '../skill_glyph.dart';
import 'cat_catch_rule.dart';
import 'home_attack.dart';

/// The Return Home skill of a breed: how it looks on the skill button and how
/// long it takes to recharge. The effect itself lives in `ReturnHomeCat`.
class CatHomeSkill {
  const CatHomeSkill(this.label, this.glyph, this.color, this.cooldown);
  final String label;
  final SkillGlyph glyph;
  final Color color;
  final double cooldown;
}

/// Everything the game knows about one cat breed, in one place.
///
/// To add a breed: add an entry here, add its sprite sheets under
/// `assets/images/Cat/<Folder>/`, then handle its id in the per-breed
/// behaviour (catch rule in `cat_catch_behaviour.dart`, skill effect in
/// `ReturnHomeCat.activateSkill`).
class CatBreed {
  const CatBreed({
    required this.id,
    required this.name,
    required this.color,
    required this.bedAsset,
    required this.catchRule,
    required this.homeSkill,
    required this.attacks,
  });

  /// Stable id used in saves, levels and asset file names.
  final String id;

  /// Display name, e.g. "Mèo cam".
  final String name;

  /// Accent colour for buttons and fallbacks.
  final Color color;
  final String bedAsset;
  final CatCatchRule catchRule;
  final CatHomeSkill homeSkill;

  /// The three secondary Return Home skills, in button order around the main
  /// one (left, diagonal, top).
  final List<HomeAttack> attacks;

  /// Folder under assets/images/Cat, e.g. "Orange".
  String get folder => id[0].toUpperCase() + id.substring(1);
  String sheet(String action) => 'Cat/$folder/cat-$id-$action.png';
  String get upperName => name.toUpperCase();

  static const orange = CatBreed(
    id: 'orange',
    name: 'Mèo cam',
    color: Color(0xFFF4A34E),
    bedAsset: 'Bed/bed-orange.png',
    catchRule: CatCatchRule('Ham ăn',
        'Cho ăn 1 con cá. Ăn xong mèo ngủ khò rất lâu, cứ thong thả bế vào ổ.'),
    homeSkill:
        CatHomeSkill('Chạy nhanh', SkillGlyph.sprint, Color(0xFFF08A3A), 5),
    attacks: [HomeAttack.fireball, HomeAttack.flameBreath, HomeAttack.fireBomb],
  );
  static const black = CatBreed(
    id: 'black',
    name: 'Mèo đen',
    color: Color(0xFF536066),
    bedAsset: 'Bed/bed-scottish.png',
    catchRule: CatCatchRule(
        'Cô độc', 'Chỉ ăn cá ở chỗ vắng: quanh con cá không được có mèo khác.'),
    homeSkill:
        CatHomeSkill('Biến mất', SkillGlyph.vanish, Color(0xFF6D5BA8), 4),
    attacks: [HomeAttack.shadowStep, HomeAttack.decoy, HomeAttack.timeStop],
  );
  static const himalaya = CatBreed(
    id: 'himalaya',
    name: 'Himalaya',
    color: Color(0xFFDCC7A7),
    bedAsset: 'Bed/bed-himalaya.png',
    catchRule: CatCatchRule(
        'Nhút nhát', 'Đặt cá cách xa mèo. Đặt sát quá mèo giật mình bỏ chạy.'),
    homeSkill: CatHomeSkill('Lăn né', SkillGlyph.roll, Color(0xFF3E9FB0), 6),
    attacks: [HomeAttack.iceShard, HomeAttack.frostNova, HomeAttack.iceBridge],
  );
  static const scottish = CatBreed(
    id: 'scottish',
    name: 'Scottish',
    color: Color(0xFFB77E64),
    bedAsset: 'Bed/bed-scottish.png',
    catchRule:
        CatCatchRule('Kén ăn', 'Phải ăn đủ 2 con cá thì mèo mới chịu cho bế.'),
    homeSkill: CatHomeSkill('Lá chắn', SkillGlyph.shield, Color(0xFF6B9E4E), 8),
    attacks: [HomeAttack.roar, HomeAttack.stoneWall, HomeAttack.reflect],
  );
  static const calico = CatBreed(
    id: 'calico',
    name: 'Tam thể',
    color: Color(0xFFE8A86B),
    bedAsset: 'Bed/bed-calico.png',
    catchRule: CatCatchRule('Ham chơi',
        'Không thèm cá! Chạm vào mèo 3 lần liền để chơi cùng, mèo mệt là bế được.'),
    homeSkill: CatHomeSkill('Hồi máu', SkillGlyph.heal, Color(0xFFD9657B), 12),
    attacks: [HomeAttack.magnet, HomeAttack.catEye, HomeAttack.bolt],
  );

  ({
    String name,
    String hint,
    String effect,
    List<({HomeAttack attack, String instruction})> steps
  }) get homeCombo => switch (id) {
        'black' => (
            name: 'Ảnh nổ',
            hint: 'Đặt phân thân rồi dịch chuyển vào vùng phân thân',
            steps: [
              (
                attack: HomeAttack.decoy,
                instruction: 'Đặt phân thân gần mục tiêu muốn gây nổ.'
              ),
              (
                attack: HomeAttack.shadowStep,
                instruction:
                    'Dịch chuyển bóng vào vùng quanh phân thân để kích nổ ngay.'
              ),
            ],
            effect:
                'Khi mèo đáp xuống trong vùng phân thân, phân thân nổ ngay. Sát thương lên rồng tăng từ 4 lên 6.'
          ),
        'himalaya' => (
            name: 'Phá băng',
            hint: 'Đóng băng mục tiêu rồi bắn Mũi băng',
            steps: [
              (
                attack: HomeAttack.frostNova,
                instruction:
                    'Đến gần mục tiêu rồi dùng Vùng băng giá để đóng băng.'
              ),
              (
                attack: HomeAttack.iceShard,
                instruction: 'Bắn Mũi băng trúng mục tiêu trước khi băng tan.'
              ),
            ],
            effect:
                'Phá vỡ chướng ngại đã đóng băng. Với rồng, phá băng gây 3 sát thương thay vì 1 và kết thúc đóng băng.'
          ),
        'scottish' => (
            name: 'Gầm phản chấn',
            hint: 'Bật Phản đòn rồi Gầm đẩy đá vào địch',
            steps: [
              (
                attack: HomeAttack.reflect,
                instruction: 'Bật Phản đòn khi có đá ở gần.'
              ),
              (
                attack: HomeAttack.roar,
                instruction:
                    'Đứng phía sau đá, dùng Tiếng gầm đẩy đá về phía địch.'
              ),
            ],
            effect:
                'Đá được đẩy có thể phá chướng ngại và gây 4 sát thương lên rồng trong 2,5 giây. Đá này không làm mèo mất máu.'
          ),
        'calico' => (
            name: 'Sét tinh anh',
            hint: 'Bật Mắt mèo rồi Sét trúng địch ở gần',
            steps: [
              (
                attack: HomeAttack.catEye,
                instruction: 'Bật Mắt mèo và giữ mục tiêu trong vùng quanh mèo.'
              ),
              (
                attack: HomeAttack.bolt,
                instruction:
                    'Thả Sấm sét trúng mục tiêu khi Mắt mèo còn hiệu lực.'
              ),
            ],
            effect:
                'Sét trúng mục tiêu trong vùng Mắt mèo giảm 2 giây hồi chiêu. Sát thương lên rồng tăng từ 4 lên 6.'
          ),
        _ => (
            name: 'Bùng cháy',
            hint: 'Bom rơi rồi bắn Cầu lửa vào vùng cháy',
            steps: [
              (
                attack: HomeAttack.fireBomb,
                instruction:
                    'Thả Bom lửa vào mục tiêu, chờ bom nổ tạo vùng cháy.'
              ),
              (
                attack: HomeAttack.fireball,
                instruction: 'Bắn Cầu lửa vào vùng cháy khi vùng này vẫn còn.'
              ),
            ],
            effect:
                'Bom nổ thêm một lần, gây 6 sát thương lên rồng. Mỗi bom chỉ kích hoạt combo một lần.'
          ),
      };

  static const all = [orange, black, himalaya, scottish, calico];

  static CatBreed of(String id) =>
      all.firstWhere((b) => b.id == id, orElse: () => orange);
}
