import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../fishing/fishing_quests.dart';
import '../../fishing/fishing_river.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import 'fishing_fish_art.dart';
import '../design.dart';
import 'game_surfaces.dart';
import 'fishing_dialog_kit.dart';

/// Flat, compact quest shortcut aligned with the Home button.
class FishingQuestChip extends StatelessWidget {
  const FishingQuestChip({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quests = FishingQuests.instance;
    return ListenableBuilder(
        listenable: quests,
        builder: (context, _) {
          final q = quests.current;
          final text = q?.title ?? 'Đền Hang biển đã thức tỉnh';
          final progress = q == null ? null : '${quests.progress}/${q.goal}';
          return Tooltip(
              message:
                  'Nhiệm vụ: $text${progress == null ? "" : " · $progress"}',
              child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onTap,
                      child: SizedBox(
                          width: 230,
                          height: 44,
                          child: Center(
                              child: Container(
                                  height: 32,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                      color: DS.cream.withValues(alpha: .92),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(children: [
                                    Icon(
                                        q == null
                                            ? Icons.emoji_events_rounded
                                            : Icons.assignment_rounded,
                                        size: 17,
                                        color: DS.goldEdge),
                                    const SizedBox(width: 6),
                                    Expanded(
                                        child: Text(text,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: DS.ink,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700))),
                                    if (progress != null) ...[
                                      const SizedBox(width: 6),
                                      Text(progress,
                                          style: const TextStyle(
                                              color: DS.goldEdge,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800)),
                                    ],
                                    const Icon(Icons.chevron_right_rounded,
                                        size: 16, color: DS.goldEdge),
                                  ])))))));
        });
  }
}

/// Journey view of the steps: a trail of stepping stones ending at the
/// shrine, and a detail card for the selected stone (current by default).
class FishingQuestDialog extends StatefulWidget {
  const FishingQuestDialog({super.key});
  @override
  State<FishingQuestDialog> createState() => _FishingQuestDialogState();
}

enum _Stone { done, now, locked }

const _gold = Color(0xFFE2A93B),
    _brown = Color(0xFF8A5A33),
    _green = Color(0xFF4F9A6E),
    _stoneGrey = Color(0xFFD9D0C1);

extension on FishingQuest {
  String get short => switch (this) {
        FishingQuest.villageFish => 'Cá Làng',
        FishingQuest.sell => 'Chợ nổi',
        FishingQuest.bambooRare => 'Cá hiếm',
        FishingQuest.activeWater => 'Nước động',
        FishingQuest.nessie => 'Nessie',
        FishingQuest.findShrine => 'Tìm đền',
        FishingQuest.exploreWorld => 'Khám phá',
        FishingQuest.moonfish => 'Nguyệt quang',
        FishingQuest.seaDragon => 'Rồng biển',
        FishingQuest.shrine => 'Hiến tế',
      };

  String get place => switch (this) {
        FishingQuest.villageFish => 'Làng',
        FishingQuest.sell => 'Cửa biển',
        FishingQuest.bambooRare || FishingQuest.nessie => 'Sông tre',
        FishingQuest.activeWater => 'Mọi vùng nước',
        FishingQuest.findShrine => 'Vịnh đá → Hang biển',
        FishingQuest.exploreWorld => 'Tất cả 7 vùng',
        FishingQuest.moonfish => 'Hang biển · ban đêm',
        FishingQuest.seaDragon => 'Biển rộng',
        FishingQuest.shrine => 'Đền Hang biển',
      };

  FishSpecies? get fish => switch (this) {
        FishingQuest.villageFish => FishSpecies.perch,
        FishingQuest.bambooRare => FishSpecies.koi,
        FishingQuest.nessie => FishSpecies.catMew,
        FishingQuest.moonfish => FishSpecies.moonfish,
        FishingQuest.seaDragon => FishSpecies.seaDragon,
        _ => null,
      };

  IconData get icon => switch (this) {
        FishingQuest.sell => Icons.storefront_rounded,
        FishingQuest.activeWater => Icons.bubble_chart_rounded,
        FishingQuest.findShrine ||
        FishingQuest.exploreWorld =>
          Icons.explore_rounded,
        _ => Icons.account_balance_rounded,
      };
}

class _FishingQuestDialogState extends State<FishingQuestDialog> {
  FishingQuests get _quests => FishingQuests.instance;
  late int _selected = math.min(_quests.index, FishingQuest.values.length - 1);

  _Stone _state(FishingQuest q) => _quests.isCompleted(q)
      ? _Stone.done
      : q == _quests.current
          ? _Stone.now
          : _Stone.locked;

  @override
  Widget build(BuildContext context) {
    final done = _quests.completedCount;
    return GameDialog(
        maxWidth: 640,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          FishingDialogHeader(
              icon: Icons.map_rounded,
              title: 'Hành trình câu cá',
              subtitle: 'Thắp sáng đền trong Hang biển',
              trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFE7A8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _gold, width: 1.5)),
                  child: Text('$done/${FishingQuest.values.length}',
                      style: const TextStyle(
                          color: DS.ink, fontWeight: FontWeight.w900))),
              onClose: () => Navigator.pop(context)),
          const SizedBox(height: 6),
          _trail(),
          const SizedBox(height: 10),
          _detail(FishingQuest.values[_selected]),
        ])));
  }

  /// Quest stones on a gently waving path; the last one is the shrine.
  Widget _trail() => LayoutBuilder(builder: (context, box) {
        final n = FishingQuest.values.length;
        const h = 96.0, r = 22.0;
        final w = box.maxWidth;
        Offset at(int i) => Offset(r + 4 + i * (w - 2 * r - 8) / (n - 1),
            40 + math.sin(i * 1.15) * 10);
        return SizedBox(
            height: h,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                  child: CustomPaint(
                      painter: _TrailPainter([
                for (var i = 0; i < n; i++) at(i)
              ], {
                for (final q in FishingQuest.values)
                  if (_quests.isCompleted(q)) q.index
              }))),
              for (final q in FishingQuest.values)
                Positioned(
                    left: at(q.index).dx - 36,
                    top: at(q.index).dy - r,
                    width: 72,
                    child: _stone(q, r)),
            ]));
      });

  Widget _stone(FishingQuest q, double r) {
    final state = _state(q);
    final selected = q.index == _selected;
    final size = r * 2 + (state == _Stone.now ? 6 : 0);
    final fish = q.fish;
    // The goal stays visible from the start so players know where it ends.
    final goal = q == FishingQuest.shrine;
    final Widget face = state == _Stone.locked && goal
        ? const Icon(Icons.account_balance_rounded,
            color: Color(0xFF9C8A6A), size: 22)
        : state == _Stone.locked
            ? const Icon(Icons.lock_rounded, color: Color(0xFFA89D8B), size: 18)
            : fish != null
                ? Padding(
                    padding: const EdgeInsets.all(5),
                    child: CustomPaint(
                        size: Size.infinite, painter: FishingFishArt(fish)))
                : Icon(q.icon,
                    color: state == _Stone.done ? _green : _brown, size: 22);
    return GestureDetector(
        onTap: () => setState(() => _selected = q.index),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              height: r * 2 + 6,
              child: Center(
                  child: Stack(clipBehavior: Clip.none, children: [
                Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: switch (state) {
                          _Stone.done => const Color(0xFFE3F2E1),
                          _Stone.now => const Color(0xFFFFF0C7),
                          _Stone.locked => _stoneGrey,
                        },
                        border: Border.all(
                            color: selected
                                ? DS.ink
                                : switch (state) {
                                    _Stone.done => _green,
                                    _Stone.now => _gold,
                                    _Stone.locked => const Color(0xFFBFB4A2),
                                  },
                            width: selected || state == _Stone.now ? 3 : 2),
                        boxShadow: state == _Stone.now
                            ? const [
                                BoxShadow(
                                    color: Color(0x88FFD36B), blurRadius: 12)
                              ]
                            : null),
                    child: ClipOval(child: face)),
                if (state == _Stone.done)
                  const Positioned(
                      right: -3,
                      bottom: -3,
                      child: Icon(Icons.check_circle_rounded,
                          color: _green, size: 16)),
              ]))),
          const SizedBox(height: 2),
          Text(state == _Stone.locked && !goal ? '?' : q.short,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:
                      state == _Stone.locked ? const Color(0xFFA89D8B) : DS.ink,
                  fontSize: 10.5,
                  fontWeight:
                      state == _Stone.now ? FontWeight.w900 : FontWeight.w700)),
        ]));
  }

  Widget _detail(FishingQuest q) {
    final state = _state(q);
    if (state == _Stone.locked) {
      return _card(
          const Color(0xFFEFE8DC),
          const Color(0xFFD3C8B6),
          Row(children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFA89D8B), size: 30),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    'Chặng ${q.index + 1} còn bí mật. '
                    'Hoàn thành chặng trước để mở.',
                    style: const TextStyle(
                        color: _brown, fontWeight: FontWeight.w700))),
          ]));
    }
    final progress = state == _Stone.done ? q.goal : _quests.progress;
    final fish = q.fish;
    return _card(
        state == _Stone.done
            ? const Color(0xFFEAF5E7)
            : const Color(0xFFFFF6DC),
        state == _Stone.done ? _green : _gold,
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 76,
              height: 60,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(6),
              child: q == FishingQuest.shrine
                  ? Row(children: [
                      for (final f in FishSpecies.legendary)
                        Expanded(
                            child: CustomPaint(
                                size: Size.infinite,
                                painter: FishingFishArt(f,
                                    locked: !FishCollection.instance
                                        .hasShrineOffering(f)))),
                    ])
                  : fish != null
                      ? CustomPaint(
                          size: Size.infinite, painter: FishingFishArt(fish))
                      : Icon(q.icon, color: _brown, size: 36)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text('CHẶNG ${q.index + 1}',
                      style: TextStyle(
                          color: state == _Stone.done ? _green : _brown,
                          fontSize: 11,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  if (state == _Stone.done)
                    const Text('ĐÃ XONG',
                        style: TextStyle(
                            color: _green,
                            fontSize: 11,
                            fontWeight: FontWeight.w900)),
                ]),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                      child: Text(
                          q.goal > 1
                              ? '${q.title} · $progress/${q.goal}'
                              : q.title,
                          style: const TextStyle(
                              color: DS.ink,
                              fontSize: DS.fontButton,
                              fontWeight: FontWeight.w900))),
                  const SizedBox(width: 8),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (q.coins > 0)
                      _reward(Icons.monetization_on_rounded,
                          const Color(0xFFE2A93B), '+${q.coins} xu',
                          claimed: state == _Stone.done),
                    if (q.bait > 0)
                      _reward(Icons.phishing_rounded, const Color(0xFFB0662F),
                          '+${q.bait} mồi huyền thoại',
                          claimed: state == _Stone.done),
                  ]),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.place_rounded, size: 14, color: _brown),
                  const SizedBox(width: 3),
                  Text(q.place,
                      style: const TextStyle(
                          color: _brown,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 4),
                Text(q.hint,
                    style: const TextStyle(color: DS.ink, fontSize: 12.5)),
                if (q == FishingQuest.exploreWorld) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    for (final region in FishingQuests.explorationOrder)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                            _quests.hasVisited(region)
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 14,
                            color:
                                _quests.hasVisited(region) ? _green : _brown),
                        const SizedBox(width: 3),
                        Text(region.label,
                            style:
                                const TextStyle(color: DS.ink, fontSize: 11)),
                      ]),
                  ]),
                ],
              ])),
        ]));
  }

  Widget _card(Color fill, Color edge, Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: edge, width: 2)),
      child: child);

  Widget _reward(IconData icon, Color color, String text,
          {required bool claimed}) =>
      Container(
          padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: .6))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(claimed ? Icons.check_rounded : icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(claimed ? 'Đã nhận $text' : text,
                style: const TextStyle(
                    color: DS.ink, fontSize: 12, fontWeight: FontWeight.w800)),
          ]));
}

/// Dashed path between the stones: solid green over the finished part.
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points, this.done);
  final List<Offset> points;
  final Set<int> done;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      if (done.contains(i) && done.contains(i + 1)) {
        canvas.drawLine(a, b, paint..color = const Color(0xFF8CC79E));
        continue;
      }
      final d = b - a;
      final steps = (d.distance / 9).floor();
      paint.color = const Color(0xFFD3C8B6);
      for (var k = 0; k < steps; k += 2) {
        canvas.drawLine(a + d * (k / steps), a + d * ((k + 1) / steps), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.done.length != done.length ||
      !old.done.containsAll(done) ||
      old.points.length != points.length ||
      old.points.first != points.first ||
      old.points.last != points.last;
}

/// Banner shown for a moment when a step is finished.
class FishingQuestToast extends StatelessWidget {
  const FishingQuestToast({super.key, required this.quest});
  final FishingQuest quest;

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xF2FFF4DA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DS.goldEdge, width: 2)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_rounded,
                  color: DS.success, size: 20),
              const SizedBox(width: 6),
              Text(quest.title,
                  style: const TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: DS.fontButton)),
            ]),
            Text('Nhận ${quest.reward}',
                style: const TextStyle(
                    color: Color(0xFFB27A3E), fontWeight: FontWeight.w800)),
          ])));
}

/// Arrow at the screen edge pointing to the quest target while it is off
/// screen and the boat is far from it.
class FishingQuestArrowPainter extends CustomPainter {
  FishingQuestArrowPainter(this.round, Listenable frames, {this.hidden = false})
      : super(repaint: frames);
  final FishingRiverRound round;
  final bool hidden;
  static final _fill = Paint()..color = const Color(0xFFFFD36B);
  static final _edge = Paint()
    ..color = const Color(0xFF6E4429)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeJoin = StrokeJoin.round;
  static final _arrow = Path()
    ..moveTo(16, 0)
    ..lineTo(-10, -12)
    ..lineTo(-5, 0)
    ..lineTo(-10, 12)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final target = FishingQuests.instance.navigationTarget;
    if (hidden || target == null) return;
    if ((round.cameraFocus - target).distance < 600) return;
    final p = round.toScreen(target);
    final area = (Offset.zero & size).deflate(70);
    if (area.contains(p)) return;
    final centre = size.center(Offset.zero);
    final d = p - centre;
    // Pin to the deflated screen rectangle along the direction.
    final scale = math.min((area.width / 2) / math.max(d.dx.abs(), .001),
        (area.height / 2) / math.max(d.dy.abs(), .001));
    final at = centre + d * math.min(scale, 1);
    final bob = math.sin(round.clock * 5) * 4;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(d.direction);
    canvas.translate(bob, 0);
    canvas.drawPath(_arrow, _fill);
    canvas.drawPath(_arrow, _edge);
    canvas.restore();
  }

  @override
  bool shouldRepaint(FishingQuestArrowPainter old) =>
      old.round != round || old.hidden != hidden;
}
