import 'package:material_ui/material_ui.dart';

import '../../camp/camp_resident.dart' show campSleepFrames;
import '../../game/cat_herd/herd_map.dart';
import '../design.dart';
import 'cat_sprite.dart';

/// First visit to a map with special cats: who they are and how to handle them.
class HerdTraitIntro extends StatelessWidget {
  const HerdTraitIntro({super.key, required this.map, required this.onStart});
  final HerdMap map;
  final VoidCallback onStart;

  static const _station = [
    (
      'train',
      '',
      'Đi nhờ tàu',
      'Tàu dừng mở cửa 4 giây. Đi xuyên qua toa sang sân bên kia, hoặc ở lại toa để sang ga Đông.'
    ),
    (
      'shy',
      'black',
      'Bé Nhát Gan',
      'Nghe còi tàu là chạy trốn dưới ghế. Đứng cạnh một lúc để dỗ bé ra.'
    ),
  ];

  static const _farm = [
    (
      'plate',
      '',
      'Bàn đạp giữ cổng',
      'Bé đầu tiên bước lên bàn đạp sẽ ngồi giữ cổng chuồng. Ra rồi nhớ quay lại đón bé.'
    ),
    (
      'chubby',
      'orange',
      'Bé Mập có ích!',
      'Bàn đạp nặng ở chuồng gà chỉ Bé Mập đè xuống nổi.'
    ),
    (
      'sulky',
      'calico',
      'Bé Hay Dỗi',
      'Bị bỏ lại là giận, quay lưng bỏ đi. Đuổi theo đứng cạnh để dỗ. Bé không chịu giữ cổng.'
    ),
    (
      'goose',
      '',
      'Đàn ngỗng',
      'Đi tuần ngoài đồng. Đụng phải là cả đàn chạy tán loạn.'
    ),
  ];

  static const _cats = [
    (
      'chubby',
      'orange',
      'Bé Mập',
      'Đi chậm, kéo cả đàn chậm theo. Không chui lọt cửa mèo nhỏ.'
    ),
    (
      'sleepy',
      'scottish',
      'Bé Ngủ Say',
      'Đứng cạnh một lúc để gọi dậy, hoặc chờ đồng hồ cúc cu reo.'
    ),
    (
      'curious',
      'calico',
      'Bé Tò Mò',
      'Thấy cuộn len, đĩa cá hay bướm là bỏ đàn chạy đi chơi.'
    ),
    (
      'golden',
      'himalaya',
      'Bé Vàng',
      'Hiếm có! Đưa bé về nhà được thêm 30 điểm.'
    ),
  ];

  @override
  Widget build(BuildContext context) => BlockSemantics(
        child: Material(
          color: DS.scrim,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(DS.spaceMd),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: 520,
                    padding: const EdgeInsets.all(DS.spaceMd),
                    decoration: DS.card.copyWith(color: DS.cream),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          switch (map.kind) {
                            HerdMapKind.station => 'CHÀO MỪNG ĐẾN NHÀ GA',
                            HerdMapKind.farm => 'CHÀO MỪNG ĐẾN NÔNG TRẠI',
                            _ => 'GẶP CÁC BÉ CÓ TÍNH CÁCH',
                          },
                          style: const TextStyle(
                              color: DS.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5)),
                      const SizedBox(height: DS.spaceXs),
                      Text(
                          switch (map.kind) {
                            HerdMapKind.station =>
                              'Lên tàu thiếu bé nào là bé đó bị bỏ lại sân ga!',
                            HerdMapKind.farm =>
                              'Mèo trong chuồng chỉ ra được khi có bé giữ cổng mở.',
                            _ =>
                              'Nhà bà ngoại có vài bé hơi "khó chiều". Nhìn dấu trên đầu để nhận ra nhé!',
                          },
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: DS.soft,
                              fontSize: DS.fontBody,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: DS.spaceSm),
                      for (var row = 0; row < _entries.length ~/ 2; row++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: DS.spaceSm),
                          child: Row(children: [
                            for (var i = row * 2; i < row * 2 + 2; i++) ...[
                              if (i.isOdd) const SizedBox(width: DS.spaceSm),
                              Expanded(child: _entry(_entries[i])),
                            ],
                          ]),
                        ),
                      SizedBox(
                        width: 220,
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: onStart,
                          style: DS.primary,
                          icon: const Icon(Icons.pets_rounded, size: 20),
                          label: Text(switch (map.kind) {
                            HerdMapKind.station => 'VÀO GA',
                            HerdMapKind.farm => 'VÀO TRẠI',
                            _ => 'VÀO NHÀ',
                          }),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  List<(String, String, String, String)> get _entries => switch (map.kind) {
        HerdMapKind.station => _station,
        HerdMapKind.farm => _farm,
        _ => _cats,
      };

  static const _icons = {
    'train': Icons.train_rounded,
    'plate': Icons.radio_button_checked_rounded,
    'goose': Icons.flutter_dash_rounded,
  };

  Widget _entry((String, String, String, String) cat) {
    final (trait, type, name, text) = cat;
    final mark = switch (trait) {
      'chubby' when map.kind == HerdMapKind.farm => (
          'NẶNG',
          const Color(0xFF6E9873)
        ),
      'chubby' => ('KẸT!', const Color(0xFFE0533E)),
      'sleepy' => ('Zz', const Color(0xFF5A6EA8)),
      'curious' => ('?', const Color(0xFF5B8FCF)),
      'shy' => ('!?', const Color(0xFF8E5BC9)),
      'train' => ('', const Color(0xFFE76F51)),
      'plate' => ('', const Color(0xFF6E9873)),
      'goose' => ('', const Color(0xFFE0A21B)),
      'sulky' => ('Hứ!', const Color(0xFFB8463E)),
      _ => ('', const Color(0xFFE0A21B)),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(DS.spaceXs),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(DS.radiusMd),
          border: Border.all(color: mark.$2.withValues(alpha: .5), width: 1.5)),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          if (_icons[trait] case final icon?)
            SizedBox.square(
                dimension: 56, child: Icon(icon, color: mark.$2, size: 44))
          else
            Transform.scale(
              scale: trait == 'chubby' ? 1.2 : 1,
              child: CatSprite(
                  type: type,
                  frame: trait == 'sleepy' ? campSleepFrames[type] ?? 0 : 0,
                  size: 56),
            ),
          if (_icons.containsKey(trait))
            const SizedBox.shrink()
          else if (trait == 'golden')
            const Positioned(
                left: 0,
                right: 0,
                top: -6,
                child: Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFFFC23D), size: 20))
          else
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: mark.$2, width: 1.5)),
                child: Text(mark.$1,
                    style: TextStyle(
                        color: mark.$2,
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
              ),
            ),
        ]),
        const SizedBox(width: DS.spaceSm),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    style: TextStyle(
                        color: mark.$2,
                        fontSize: 13,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(text,
                    maxLines: 4,
                    style: const TextStyle(
                        color: DS.ink,
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w600)),
              ]),
        ),
      ]),
    );
  }
}
