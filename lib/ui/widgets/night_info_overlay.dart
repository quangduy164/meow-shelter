import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../game/night_shift/night_run.dart';
import '../../game/night_shift/night_cards.dart';
import '../design.dart';
import 'night_relic_icon.dart';

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
                            padding: const EdgeInsets.all(DS.spaceSm),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: 700,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 5, child: _objective()),
                                    const SizedBox(width: DS.spaceMd),
                                    Expanded(flex: 6, child: _howToPlay()),
                                  ],
                                ),
                              ),
                            ),
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
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_night, Color(0xFF445582)]),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: DS.gold.withValues(alpha: .15), shape: BoxShape.circle),
            child:
                const Icon(Icons.nights_stay_rounded, color: DS.gold, size: 26),
          ),
          const SizedBox(width: DS.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ĐÊM ${run.night}${run.bossNight ? ' · ĐÊM TRÙM' : ''}',
                    style: const TextStyle(
                        color: DS.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
                Text(run.map.title,
                    style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
        ]),
      );

  Widget _objective() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('NHIỆM VỤ ĐÊM NÀY', Icons.flag_rounded),
          const SizedBox(height: DS.spaceSm),
          Container(
            padding: const EdgeInsets.all(DS.spaceMd),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFDF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC1D4B4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cứu ${run.quota} mèo trước bình minh',
                    style: const TextStyle(
                        color: Color(0xFF365C3E),
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: DS.spaceSm),
                Wrap(
                  spacing: DS.spaceMd,
                  runSpacing: DS.spaceXs,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.pets_rounded,
                          color: DS.success, size: 20),
                      const SizedBox(width: DS.spaceXs),
                      Text('${run.rescuedTonight}/${run.quota} mèo',
                          style: DS.bodyText
                              .copyWith(fontWeight: FontWeight.w900)),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.timer_outlined,
                          color: DS.goldEdge, size: 20),
                      const SizedBox(width: DS.spaceXs),
                      Text('${secondsLeft}s còn lại',
                          style: DS.bodyText
                              .copyWith(fontWeight: FontWeight.w900)),
                    ]),
                  ],
                ),
                const SizedBox(height: DS.spaceSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: run.rescuedTonight / run.quota,
                    minHeight: 8,
                    color: DS.success,
                    backgroundColor: const Color(0xFFC5D5BC),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DS.spaceSm),
          _label('ĐIỀU KIỆN ĐÊM NAY', Icons.auto_awesome_rounded),
          const SizedBox(height: DS.spaceXs),
          // The first entry names the map; its rules are explained on the right.
          if (rules.length <= 1) _condition('Không có điều kiện đặc biệt'),
          for (final rule in rules
              .skip(1)
              .where((r) => !r.startsWith('Mèo trong vùng sáng')))
            _condition(rule),
          if (run.relics.isNotEmpty) ...[
            const SizedBox(height: DS.spaceSm),
            Wrap(spacing: 8, children: [
              for (final relic in run.relics)
                Tooltip(
                  message: '${relic.title}: ${relic.details}',
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    NightRelicIcon(relic, size: 24),
                    const SizedBox(width: 3),
                    Text(relic.title, style: DS.captionText),
                  ]),
                ),
            ]),
          ],
        ],
      );

  Widget _condition(String text) => Padding(
        padding: const EdgeInsets.only(top: DS.spaceXs),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.circle, size: 7, color: DS.goldEdge),
          ),
          const SizedBox(width: DS.spaceSm),
          Expanded(child: Text(text, style: DS.bodyText)),
        ]),
      );

  Widget _howToPlay() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('CÁCH CHƠI', Icons.touch_app_rounded),
          const SizedBox(height: DS.spaceSm),
          _step(
              Icons.pets_rounded,
              const Color(0xFFEBDCCD),
              'Dụ mèo → bế vào ổ',
              'Cho ăn hoặc chơi đến khi sẵn sàng. Bế được ở mọi nơi.'),
          _step(
              run.map == NightMap.rooftops
                  ? Icons.horizontal_rule_rounded
                  : Icons.lightbulb_rounded,
              const Color(0xFFFFE7AC),
              switch (run.map) {
                NightMap.marketAlley => 'Bật đèn đường',
                NightMap.rooftops => 'Hạ cầu ván',
                NightMap.backyard => 'Chạm để thắp đèn',
              },
              run.map == NightMap.rooftops
                  ? 'Ván mở ${lanternBurn.round()}s. Hết giờ thì cần chờ kéo lại.'
                  : 'Sáng ${lanternBurn.round()}s · nguội 5s. Vùng vàng giúp mèo ngoan và chờ bế lâu hơn.'),
          _step(
              Icons.nights_stay_rounded,
              const Color(0xFFDCE9FF),
              switch (run.map) {
                NightMap.marketAlley => 'Giữ hẻm yên tĩnh',
                NightMap.rooftops => 'Nối các mái nhà',
                NightMap.backyard => 'Vùng sáng giúp mèo ngoan',
              },
              switch (run.map) {
                NightMap.marketAlley =>
                  'Xe và lỗi gây ồn. Sau xe: mèo ngoan, ồn giảm nhanh. Thả cá chưa ai nhận sát đường để xe chở sang điểm dừng.',
                NightMap.rooftops =>
                  'Chỉ thả cá ở vùng đánh dấu trên mái giữa. Mở cầu phía có mèo để chúng sang ăn; cá chờ khi cầu đóng.',
                NightMap.backyard =>
                  'Không giở chiêu mới; thanh chờ/bế chậm một nửa. Mây che trăng thì vệt sáng tắt.',
              }),
        ],
      );

  Widget _label(String title, IconData icon) => Row(children: [
        Icon(icon, color: DS.goldEdge, size: 17),
        const SizedBox(width: DS.spaceXs),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: DS.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6)),
        ),
      ]);

  Widget _step(IconData icon, Color color, String title, String text) =>
      Padding(
        padding: const EdgeInsets.only(bottom: DS.spaceSm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _night, size: 21),
          ),
          const SizedBox(width: DS.spaceSm),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: DS.bodyText.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(text, style: DS.captionText.copyWith(height: 1.35)),
            ]),
          ),
        ]),
      );

  Widget _footer() => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        decoration: const BoxDecoration(
          color: Color(0xFFF5E8D0),
          border: Border(top: BorderSide(color: Color(0xFFE1CFAD))),
        ),
        child: Align(
          alignment: Alignment.center,
          child: ElevatedButton.icon(
            style: DS.primary,
            onPressed: onClose,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('TIẾP TỤC'),
          ),
        ),
      );
}
