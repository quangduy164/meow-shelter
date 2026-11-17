import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../game/night_shift/night_run.dart';
import '../../game/night_shift/night_cards.dart';
import '../design.dart';
import 'night_card_icons.dart';
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

  static const _panel = Color(0xFF1E2944);
  static const _panelLight = Color(0xFF2C3A5D);
  static const _muted = Color(0xFFC5D0E8);

  List<String> get _notes => rules
      .skip(1)
      .where((r) => !r.startsWith('Mèo trong vùng sáng'))
      .map((r) => r.split(':').first)
      .take(3)
      .toList();

  @override
  Widget build(BuildContext context) => BlockSemantics(
        child: Stack(fit: StackFit.expand, children: [
          const ModalBarrier(dismissible: false, color: Color(0xC40A1020)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DS.spaceMd),
              child: LayoutBuilder(
                builder: (context, box) => Center(
                  child: SizedBox(
                    width: math.min(700, box.maxWidth),
                    height: math.min(310, box.maxHeight),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_panelLight, _panel],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: DS.gold.withValues(alpha: .55), width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x88000000),
                              blurRadius: 24,
                              offset: Offset(0, 10))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(children: [
                          _header(),
                          const SizedBox(height: DS.spaceMd),
                          Expanded(child: _stepsRow()),
                          const SizedBox(height: DS.spaceMd),
                          _footer(),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _header() => Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: DS.gold.withValues(alpha: .16),
            shape: BoxShape.circle,
            border: Border.all(color: DS.gold.withValues(alpha: .5)),
          ),
          child:
              const Icon(Icons.nights_stay_rounded, color: DS.gold, size: 27),
        ),
        const SizedBox(width: DS.spaceMd),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ĐÊM ${run.night}${run.bossNight ? ' · CÓ TRÙM' : ''}',
                style: const TextStyle(
                    color: DS.gold,
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8)),
            Text('${run.map.title} · ${run.variant.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _muted, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: DS.cream,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0x44000000), offset: Offset(0, 3))
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.pets_rounded, color: DS.success, size: 22),
            const SizedBox(width: 5),
            Text('${run.quota} mèo',
                style: const TextStyle(
                    color: DS.ink, fontSize: 18, fontWeight: FontWeight.w900)),
            Container(
                width: 1.5,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: DS.borderMedium),
            const Icon(Icons.timer_rounded, color: DS.goldEdge, size: 21),
            const SizedBox(width: 4),
            Text('${secondsLeft}s',
                style: const TextStyle(
                    color: DS.ink, fontSize: 18, fontWeight: FontWeight.w900)),
          ]),
        ),
      ]);

  Widget _stepsRow() => Row(children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Icon(Icons.chevron_right_rounded,
                  color: Color(0x99FFC24D), size: 26),
            ),
          Expanded(child: _step(i + 1, _steps[i])),
        ],
      ]);
  List<(NightGuideGlyph, String, String)> get _steps => switch (run.map) {
        NightMap.backyard => [
            (NightGuideGlyph.lantern, 'Bật đèn', 'Chạm đèn để tạo vùng sáng'),
            (NightGuideGlyph.fish, 'Dụ mèo', 'Cho ăn hoặc chơi với mèo'),
            (NightGuideGlyph.carry, 'Bế vào ổ', 'Kéo mèo vào đúng ổ'),
          ],
        NightMap.marketAlley => [
            (NightGuideGlyph.lantern, 'Bật đèn', 'Đèn giúp mèo bình tĩnh'),
            (NightGuideGlyph.quiet, 'Giữ yên', 'Tránh để độ ồn đầy'),
            (NightGuideGlyph.carry, 'Bế vào ổ', 'Kéo mèo vào đúng ổ'),
          ],
        NightMap.rooftops => [
            (NightGuideGlyph.fish, 'Đặt cá', 'Chỉ đặt ở mái giữa'),
            (NightGuideGlyph.bridge, 'Hạ cầu', 'Mở đường cho mèo sang'),
            (NightGuideGlyph.carry, 'Bế vào ổ', 'Kéo mèo vào đúng ổ'),
          ],
        NightMap.warehouse => [
            (NightGuideGlyph.cageBait, 'Thả mồi', 'Kéo cá vào lồng'),
            (NightGuideGlyph.cageWatch, 'Chờ xanh', 'Mèo vào trọn lồng'),
            (NightGuideGlyph.cageLock, 'Chốt lồng', 'Chạm khi lồng xanh'),
          ],
        NightMap.station => [
            (
              NightGuideGlyph.stationSign,
              'Xem biển',
              'Màu biển là toa cho mèo'
            ),
            (NightGuideGlyph.stationMark, 'Ra vạch', 'Chạm mèo rồi chạm vạch'),
            (NightGuideGlyph.stationTrain, 'Lên tàu', 'Tàu dừng là mèo lên'),
          ],
        NightMap.harbor => [
            (NightGuideGlyph.harborGate, 'Bẻ cửa', 'Chạm để đổi hướng nước'),
            (NightGuideGlyph.harborRaft, 'Nhìn màu', 'Cờ bè hợp màu bến'),
            (NightGuideGlyph.harborDock, 'Đúng bến', 'Sai màu thì quay lại'),
          ],
        NightMap.reedGarden => [
            (NightGuideGlyph.reedTracks, 'Theo vết', 'Nhìn vết lau mới nhất'),
            (NightGuideGlyph.reedTap, 'Chạm sau mèo', 'Tiếng động đẩy mèo đi'),
            (NightGuideGlyph.reedExit, 'Về giỏ', 'Mèo tới lối ra là cứu'),
          ],
      };

  static const _stepColors = [
    Color(0xFFFFD36B),
    Color(0xFF8ED7E8),
    Color(0xFF9EE0A8),
  ];

  Widget _step(int number, (NightGuideGlyph, String, String) step) {
    final (icon, title, text) = step;
    final color = _stepColors[number - 1];
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 8, 7, 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 140,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: NightGuideIcon(icon),
                ),
              ),
              Positioned(
                right: -5,
                top: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _panel,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text('$number',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: _muted, fontSize: 14, height: 1.15)),
          ]),
        ),
      ),
    );
  }

  Widget _chip(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: DS.gold.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DS.gold.withValues(alpha: .28)),
        ),
        child: child,
      );

  Widget _footer() => Row(children: [
        Expanded(
          child: Wrap(spacing: 6, runSpacing: 4, children: [
            for (final note in _notes.isEmpty ? const ['Đêm thường'] : _notes)
              _chip(Text(note,
                  style: const TextStyle(
                      color: Color(0xFFFFE6A6),
                      fontSize: 12,
                      fontWeight: FontWeight.w800))),
            for (final relic in run.relics)
              Tooltip(
                message: '${relic.title}: ${relic.details}',
                child: _chip(Row(mainAxisSize: MainAxisSize.min, children: [
                  NightRelicIcon(relic, size: 18),
                  const SizedBox(width: 3),
                  Text(relic.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ])),
              ),
          ]),
        ),
        const SizedBox(width: DS.spaceMd),
        ElevatedButton.icon(
          style: DS.primary.copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(150, 42))),
          onPressed: onClose,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('BẮT ĐẦU'),
        ),
      ]);
}
