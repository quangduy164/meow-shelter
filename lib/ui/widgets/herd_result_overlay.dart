import 'package:flutter/material.dart';

import '../../game/cat_herd/herd_round.dart';
import '../design.dart';
import 'game_glyphs.dart';
import 'round_button.dart';
import 'game_surfaces.dart';

/// Results use the actual round counters; this mode has no coin/star rewards.
class HerdResultOverlay extends StatelessWidget {
  const HerdResultOverlay({
    super.key,
    required this.round,
    required this.onReplay,
    required this.onMap,
    required this.onHome,
  });

  final HerdRound round;
  final VoidCallback onReplay, onMap, onHome;

  @override
  Widget build(BuildContext context) {
    final won = round.won;
    final tutorialDone = round.isTutorial && won;
    final complete = round.delivered >= round.catCount;
    final color = won ? DS.success : DS.danger;
    final seconds = round.time.floor();
    final time = '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
    final title = tutorialDone
        ? 'TẬP CHƠI HOÀN TẤT!'
        : won
            ? (complete ? 'CẢ ĐÀN VỀ NHÀ!' : 'ĐÃ VỀ NHÀ AN TOÀN!')
            : 'THỬ LẠI NÀO!';
    final subtitle = tutorialDone
        ? 'Bạn đã sẵn sàng dẫn đàn khám phá các vùng đất.'
        : won
            ? 'Bạn đã đưa ${round.delivered} người bạn về nhà.'
            : 'Mèo mệt rồi. Cùng thử một hành trình mới nhé!';
    final hint = tutorialDone
        ? 'Ở bản đồ chính, đón ít nhất ${HerdRound.requiredCats} mèo để mở nhà.'
        : !won
            ? 'Đón ít nhất ${round.minimumToHome} mèo, tránh nguy hiểm rồi về nhà.'
            : complete
                ? 'Không bỏ lại bạn nào — cả đàn đã về an toàn!'
                : 'Lượt sau, thử đón đủ ${round.catCount} mèo để tăng điểm nhé!';

    return BlockSemantics(
      child: Material(
        color: DS.scrim,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(DS.spaceLg),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  width: DS.resultWidth,
                  padding: const EdgeInsets.all(DS.spaceLg),
                  decoration: DS.card.copyWith(color: DS.cream),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Icon(Icons.place_rounded,
                          color: round.map.color, size: 17),
                      const SizedBox(width: DS.spaceXs),
                      Expanded(
                        child: Text(round.map.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: DS.soft,
                                fontSize: DS.fontCaption,
                                fontWeight: FontWeight.w800)),
                      ),
                      GameBadge(won ? 'HOÀN THÀNH' : 'CHƯA HOÀN THÀNH',
                          color: color),
                    ]),
                    const SizedBox(height: DS.spaceSm),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: DS.spaceSm),
                      child: Column(children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(title,
                              textAlign: TextAlign.center,
                              style: DS.title.copyWith(color: color)),
                        ),
                        const SizedBox(height: DS.spaceXs),
                        Text(subtitle,
                            textAlign: TextAlign.center,
                            style: DS.bodyText.copyWith(color: DS.soft)),
                      ]),
                    ),
                    const SizedBox(height: DS.spaceMd),
                    Row(children: [
                      Expanded(
                          child: _stat(Icons.pets_rounded, 'Đã về nhà',
                              '${round.delivered}/${round.catCount}', color)),
                      const SizedBox(width: DS.spaceSm),
                      Expanded(
                          child: _stat(Icons.emoji_events_rounded, 'Điểm số',
                              '${round.score}', DS.goldEdge)),
                      const SizedBox(width: DS.spaceSm),
                      Expanded(
                          child: _stat(Icons.timer_outlined, 'Thời gian', time,
                              DS.soft)),
                    ]),
                    const SizedBox(height: DS.spaceSm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: DS.spaceSm, vertical: DS.spaceSm),
                      decoration: BoxDecoration(
                        color: color.withOpacity(.08),
                        borderRadius: BorderRadius.circular(DS.radiusMd),
                      ),
                      child: Row(children: [
                        Icon(
                            won
                                ? Icons.check_circle_outline_rounded
                                : Icons.lightbulb_outline_rounded,
                            color: color,
                            size: 18),
                        const SizedBox(width: DS.spaceSm),
                        Expanded(
                            child: Text(hint,
                                style: DS.captionText
                                    .copyWith(color: color, height: 1.3))),
                      ]),
                    ),
                    const SizedBox(height: DS.spaceMd),
                    SizedBox(
                      height: 42,
                      child: Row(children: [
                        RoundButton(
                            glyph: GameGlyph.home,
                            tooltip: 'Trang chủ',
                            size: 38,
                            onPressed: onHome),
                        const SizedBox(width: DS.spaceSm),
                        if (!tutorialDone) ...[
                          OutlinedButton.icon(
                            onPressed: onMap,
                            style: DS.outlined,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Bản đồ'),
                          ),
                          const SizedBox(width: DS.spaceSm),
                        ],
                        Expanded(
                          child: SizedBox.expand(
                            child: ElevatedButton.icon(
                              onPressed: tutorialDone ? onMap : onReplay,
                              style: DS.primary,
                              icon: Icon(
                                  tutorialDone
                                      ? Icons.explore_rounded
                                      : Icons.replay_rounded,
                                  size: 20),
                              label: Text(
                                  tutorialDone ? 'CHỌN BẢN ĐỒ' : 'CHƠI LẠI'),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) =>
      GameStat(
          icon: Icon(icon, color: color, size: DS.iconMd),
          label: label,
          value: value);
}
