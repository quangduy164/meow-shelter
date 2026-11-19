import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../game/night_shift/night_run.dart';
import '../../game/night_shift/night_cards.dart';
import '../../game/night_shift/night_relics.dart';
import '../design.dart';
import 'night_card_icons.dart';
import 'night_relic_icon.dart';

/// The same briefing is opened before a night and by the information button.
/// Every map fills one layout: mission + conditions, three steps, relic slots.
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

  static const _paper = Color(0xFFFFF4DA);
  static const _card = Color(0xFFFFFBF0);
  static const _line = Color(0xFFE1CFAD);
  static const _green = Color(0xFF3C8065);

  List<String> get _notes => rules
      .skip(1)
      .where((r) => !r.startsWith('Mèo trong vùng sáng'))
      .map((r) => r.split(':').first)
      .take(4)
      .toList();

  @override
  Widget build(BuildContext context) => BlockSemantics(
        child: Stack(fit: StackFit.expand, children: [
          const ModalBarrier(dismissible: false, color: Color(0xB3201208)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DS.spaceMd),
              child: LayoutBuilder(
                builder: (context, box) => Center(
                  child: SizedBox(
                    width: math.min(700, box.maxWidth),
                    height: math.min(330, box.maxHeight),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DS.wood, width: 3),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 20,
                              offset: Offset(0, 8))
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        _header(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 4, child: _missionColumn()),
                                const SizedBox(width: 10),
                                Expanded(flex: 6, child: _stepsColumn()),
                              ],
                            ),
                          ),
                        ),
                        _footer(),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [Color(0xFF8A5A2E), Color(0xFFB27A3E)]),
        ),
        child: Row(children: [
          const Icon(Icons.nights_stay_rounded, color: DS.gold, size: 24),
          const SizedBox(width: 8),
          Text('ĐÊM ${run.night}',
              style: const TextStyle(
                  color: DS.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${run.map.title} · ${run.variant.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _paper, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          if (run.bossNight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFE85D6F),
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('CÓ TRÙM',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
            ),
        ]),
      );

  Widget _label(String text, IconData icon) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: DS.goldEdge, size: 15),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: DS.goldEdge,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8)),
      ]);

  Widget _missionColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('NHIỆM VỤ', Icons.flag_rounded),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFDF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB8D0AA), width: 1.5),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Cứu ${run.quota} mèo',
                    style: const TextStyle(
                        color: _green,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.timer_rounded,
                        color: DS.goldEdge, size: 16),
                    const SizedBox(width: 3),
                    Text('trong ${secondsLeft}s',
                        style: const TextStyle(
                            color: DS.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ])),
              const SizedBox(height: 3),
              Text(run.map.mission,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DS.ink,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 6),
          _label('ĐIỀU KIỆN', Icons.auto_awesome_rounded),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(spacing: 5, runSpacing: 5, children: [
                for (final note
                    in _notes.isEmpty ? const ['Đêm thường'] : _notes)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E1B8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _line),
                    ),
                    child: Text(note,
                        style: const TextStyle(
                            color: DS.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
              ]),
            ),
          ),
        ],
      );

  Widget _stepsColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('CÁCH CHƠI', Icons.touch_app_rounded),
          const SizedBox(height: 4),
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 5),
            Expanded(child: _step(i + 1, _steps[i])),
          ],
        ],
      );
  List<(NightGuideGlyph, String, String)> get _steps => switch (run.map) {
        NightMap.backyard => [
            (NightGuideGlyph.lantern, 'Bật đèn', 'Chạm đèn để tạo vùng sáng'),
            (NightGuideGlyph.fish, 'Dụ mèo', 'Cho ăn hoặc chơi với mèo'),
            (NightGuideGlyph.carry, 'Bế vào ổ', 'Kéo mèo vào đúng ổ'),
          ],
        NightMap.marketAlley => [
            (
              NightGuideGlyph.marketSignal,
              'Ra hiệu xe',
              'Chạm biển báo khi xe sắp qua'
            ),
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
        NightMap.clawMachine => [
            (NightGuideGlyph.clawAim, 'Ngắm', 'Giữ nút ◀ ▶ để dời càng'),
            (
              NightGuideGlyph.clawDrop,
              'Thả càng',
              'Hạ giữa người mèo thì chắc'
            ),
            (NightGuideGlyph.clawChute, 'Về miệng', 'Mèo rơi vào miệng là cứu'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line, width: 1.5),
      ),
      child: Row(children: [
        Text('$number',
            style: const TextStyle(
                color: DS.goldEdge, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                  color: _stepColors[number - 1], shape: BoxShape.circle),
              padding: const EdgeInsets.all(3),
              child: NightGuideIcon(icon),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: DS.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  Text(text,
                      style: const TextStyle(
                          color: DS.soft,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
          ),
        ),
      ]),
    );
  }

  /// Three slots, the same number the shop allows; empty ones stay dashed.
  Widget _relicSlot(NightRelic? relic) {
    final box = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: relic == null ? const Color(0xFFF1E4C8) : _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: relic == null ? _line : DS.wood,
            width: relic == null ? 1.5 : 2),
      ),
      padding: const EdgeInsets.all(3),
      child: relic == null
          ? const Icon(Icons.add_rounded, color: _line, size: 20)
          : NightRelicIcon(relic, size: 34),
    );
    if (relic == null) return box;
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message: '${relic.title}: ${relic.effectOn(run.map)}',
      child: box,
    );
  }

  Widget _footer() {
    final slots = [
      for (var i = 0; i < run.relicSlots; i++)
        i < run.relics.length ? run.relics[i] : null
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF5E8D0),
        border: Border(top: BorderSide(color: _line, width: 1.5)),
      ),
      child: Row(children: [
        _label('CỔ VẬT', Icons.diamond_rounded),
        const SizedBox(width: 8),
        for (final relic in slots) ...[
          _relicSlot(relic),
          const SizedBox(width: 6),
        ],
        const SizedBox(width: 4),
        Expanded(
          child: Text(
              run.relics.isEmpty
                  ? 'Mua ở tiệm sau đêm chẵn'
                  : 'Chạm ô để xem tác dụng ở map này',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: DS.soft, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: DS.primary.copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(140, 42))),
          onPressed: onClose,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('BẮT ĐẦU'),
        ),
      ]),
    );
  }
}
