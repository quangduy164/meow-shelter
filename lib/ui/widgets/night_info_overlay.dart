import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../game/night_shift/night_run.dart';
import '../../game/night_shift/night_cards.dart';
import '../design.dart';

/// The same briefing is opened before a night and by the information button.
/// Nothing closes it automatically; the game remains paused until dismissed.
class NightInfoOverlay extends StatelessWidget {
  const NightInfoOverlay({
    super.key,
    required this.run,
    required this.secondsLeft,
    required this.rules,
    required this.lanternBurn,
    required this.onClose,
  });

  final NightRun run;
  final int secondsLeft;
  final List<String> rules;
  final double lanternBurn;
  final VoidCallback onClose;

  static const _night = Color(0xFF253052);
  static const _muted = Color(0xFFBFCDE8);

  @override
  Widget build(BuildContext context) => BlockSemantics(
        child: Stack(fit: StackFit.expand, children: [
          const ModalBarrier(dismissible: false, color: Color(0xBC10182D)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DS.spaceMd),
              child: LayoutBuilder(builder: (context, box) {
                return Center(
                  child: SizedBox(
                    width: math.min(720, box.maxWidth),
                    height: math.min(330, box.maxHeight),
                    child: Material(
                      color: DS.cream,
                      elevation: 12,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        _header(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                DS.spaceMd, DS.spaceSm, DS.spaceMd, 0),
                            child: _body(),
                          ),
                        ),
                        _footer(),
                      ]),
                    ),
                  ),
                );
              }),
            ),
          ),
        ]),
      );

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_night, Color(0xFF445582)]),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: DS.gold.withValues(alpha: .15), shape: BoxShape.circle),
            child:
                const Icon(Icons.nights_stay_rounded, color: DS.gold, size: 22),
          ),
          const SizedBox(width: DS.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ĐÊM ${run.night}${run.bossNight ? ' · ĐÊM TRÙM' : ''}',
                    style: const TextStyle(
                        color: DS.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
                Text('${run.map.title} · ${run.variant.title}',
                    style: const TextStyle(color: _muted, fontSize: 14)),
              ],
            ),
          ),
        ]),
      );

  Widget _body() {
    final notes = rules
        .skip(1)
        .where((r) => !r.startsWith('Mèo trong vùng sáng'))
        .map((r) => r.split(':').first)
        .take(3)
        .toList();
    return Column(children: [
      Row(children: [
        const Icon(Icons.flag_rounded, color: DS.goldEdge, size: 24),
        const SizedBox(width: DS.spaceXs),
        Text('Cứu ${run.quota} mèo · ${secondsLeft}s',
            style: const TextStyle(
                color: Color(0xFF365C3E),
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(width: DS.spaceMd),
        Expanded(
          child: Text(notes.isEmpty ? 'Đêm thường' : notes.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DS.bodyText
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ]),
      const SizedBox(height: DS.spaceSm),
      Expanded(
        child: Row(children: [
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0) const SizedBox(width: DS.spaceSm),
            Expanded(child: _step(i + 1, _steps[i])),
          ],
        ]),
      ),
    ]);
  }

  List<(IconData, String, String)> get _steps => switch (run.map) {
        NightMap.backyard => [
            (Icons.lightbulb_rounded, 'Bật đèn', 'Chạm đèn để tạo vùng sáng'),
            (Icons.set_meal_rounded, 'Dụ mèo', 'Cho ăn hoặc chơi với mèo'),
            (Icons.pets_rounded, 'Bế vào ổ', 'Kéo mèo vào đúng ổ'),
          ],
        NightMap.marketAlley => [
            (Icons.lightbulb_rounded, 'Bật đèn', 'Đèn giúp mèo bình tĩnh'),
            (Icons.volume_down_rounded, 'Giữ yên', 'Tránh để độ ồn đầy'),
            (Icons.pets_rounded, 'Bế vào ổ', 'Kéo mèo vào đúng ổ'),
          ],
        NightMap.rooftops => [
            (Icons.set_meal_rounded, 'Đặt cá', 'Chỉ đặt ở mái giữa'),
            (Icons.horizontal_rule_rounded, 'Hạ cầu', 'Mở đường cho mèo sang'),
            (Icons.pets_rounded, 'Bế vào ổ', 'Kéo mèo vào đúng ổ'),
          ],
        NightMap.warehouse => [
            (Icons.set_meal_rounded, 'Thả mồi', 'Kéo cá vào lồng'),
            (Icons.visibility_rounded, 'Chờ xanh', 'Mèo vào trọn lồng'),
            (Icons.lock_rounded, 'Chốt lồng', 'Chạm khi lồng xanh'),
          ],
        NightMap.reedGarden => [
            (Icons.grass_rounded, 'Theo vết', 'Nhìn vết lau mới nhất'),
            (Icons.touch_app_rounded, 'Chạm bụi', 'Đúng bụi thì mèo lộ ra'),
            (Icons.pets_rounded, 'Bế vào ổ', 'Kéo mèo vào đúng ổ'),
          ],
      };

  Widget _step(int number, (IconData, String, String) step) {
    final (icon, title, text) = step;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceSm, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1CFAD)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$number',
              style: const TextStyle(
                  color: DS.goldEdge,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: DS.spaceXs),
          Icon(icon, color: _night, size: 25),
        ]),
        const SizedBox(height: 2),
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DS.bodyText
                .copyWith(fontSize: 19, fontWeight: FontWeight.w900)),
        Text(text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DS.bodyText.copyWith(fontSize: 14, height: 1.15)),
      ]),
    );
  }

  Widget _footer() => Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 7),
        decoration: const BoxDecoration(
          color: Color(0xFFF5E8D0),
          border: Border(top: BorderSide(color: Color(0xFFE1CFAD))),
        ),
        child: Align(
          alignment: Alignment.center,
          child: ElevatedButton.icon(
            style: DS.primary.copyWith(
                minimumSize: const WidgetStatePropertyAll(Size(150, 40))),
            onPressed: onClose,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('TIẾP TỤC'),
          ),
        ),
      );
}
