import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../../game/cats/cat_breed.dart';
import '../../game/constants.dart';
import '../../game/skill_glyph.dart';
import '../design.dart';
import 'cat_sprite.dart';
import 'game_glyphs.dart';
import 'round_button.dart';
import 'skill_glyphs.dart';

/// Previewing a breed never starts the game; only the main action commits it.
class ReturnHomeCatPicker extends StatefulWidget {
  const ReturnHomeCatPicker({
    super.key,
    required this.onStart,
    required this.onHome,
    required this.onHelp,
    this.initialCat = 'orange',
  });

  final Future<void> Function(String) onStart;
  final VoidCallback onHome;
  final ValueChanged<String> onHelp;
  final String initialCat;

  @override
  State<ReturnHomeCatPicker> createState() => _ReturnHomeCatPickerState();
}

class _ReturnHomeCatPickerState extends State<ReturnHomeCatPicker>
    with SingleTickerProviderStateMixin {
  late CatBreed _selected;
  late final AnimationController _idle;
  bool _starting = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _selected = CatBreed.of(widget.initialCat);
    _idle = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: (framesIdle * animationStepTime * 1000).round()));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _loadFailed = false;
    });
    GameAudio.instance.play(GameSound.click);
    try {
      await widget.onStart(_selected.id);
    } catch (error) {
      debugPrint('Could not start Return Home: $error');
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xF0243E3A),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740, maxHeight: 320),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(children: [
                    RoundButton(
                      glyph: GameGlyph.home,
                      onPressed: _starting ? null : widget.onHome,
                      size: 40,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('CHỌN MÈO',
                          style: TextStyle(
                              color: DS.cream,
                              fontSize: DS.fontTitle,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(builder: (context, box) {
                      final rosterWidth =
                          (box.maxWidth * .22).clamp(136.0, 148.0);
                      return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: rosterWidth,
                              child: Column(children: [
                                for (var i = 0;
                                    i < CatBreed.all.length;
                                    i++) ...[
                                  if (i > 0) const SizedBox(height: 6),
                                  Expanded(child: _breedCard(CatBreed.all[i])),
                                ],
                              ]),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: _details()),
                          ]);
                    }),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );

  Widget _breedCard(CatBreed breed) {
    final selected = _selected.id == breed.id;
    return Semantics(
      selected: selected,
      button: true,
      label: breed.name,
      child: Material(
        color: selected ? DS.cream : const Color(0xFF36554C),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _starting
              ? null
              : () {
                  GameAudio.instance.play(GameSound.click);
                  setState(() {
                    _selected = breed;
                    _loadFailed = false;
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? DS.gold : const Color(0x447CA68D),
                    width: selected ? 2 : 1)),
            child: Row(children: [
              CatFace(breed.id,
                  size: 30,
                  background: selected
                      ? const Color(0xFFFFDFA6)
                      : breed.color.withOpacity(.25)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(breed.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: selected ? DS.ink : DS.cream,
                        fontSize: DS.fontButton,
                        fontWeight: FontWeight.w900)),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: DS.goldEdge, size: 14),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _details() {
    final breed = _selected;
    final color = breed.homeSkill.color;
    final (role, hint) = switch (breed.id) {
      'black' => ('BÓNG TỐI', 'Dịch chuyển linh hoạt, đánh lạc hướng đối thủ.'),
      'himalaya' => ('BĂNG GIÁ', 'Đóng băng vật cản, mở lối qua suối.'),
      'scottish' => ('PHÒNG THỦ', 'Đỡ đòn, đẩy lùi và phản công.'),
      'calico' => ('HỖ TRỢ', 'Hồi phục, hút vật phẩm và gọi sấm sét.'),
      _ => ('HỎA LỰC', 'Bứt tốc và dùng lửa phá chướng ngại.'),
    };
    final skills = [
      (
        label: breed.homeSkill.label,
        glyph: breed.homeSkill.glyph,
        color: color,
        cooldown: breed.homeSkill.cooldown
      ),
      for (final attack in breed.attacks)
        (
          label: attack.label,
          glyph: attack.glyph,
          color: attack.color,
          cooldown: attack.cooldown
        ),
    ];
    return DecoratedBox(
      decoration: DS.card.copyWith(color: DS.cream),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 64,
            child: Row(children: [
              Container(
                width: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withOpacity(.1), color.withOpacity(.3)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                    bottom: 7,
                    left: 18,
                    right: 18,
                    child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                            color: color.withOpacity(.22),
                            borderRadius: BorderRadius.circular(20))),
                  ),
                  Positioned(
                    bottom: -8,
                    left: -8,
                    child: AnimatedBuilder(
                      animation: _idle,
                      builder: (_, __) => CatSprite(
                          type: breed.id,
                          size: 92,
                          frames: framesIdle,
                          frame: (_idle.value * framesIdle)
                              .floor()
                              .clamp(0, framesIdle - 1)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(breed.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: DS.ink,
                          fontSize: DS.fontHeading,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(role,
                      style: TextStyle(
                          color: color,
                          fontSize: DS.fontMicro,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  const SizedBox(height: 3),
                  Text(hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: DS.soft,
                          fontSize: DS.fontCaption,
                          height: 1.2)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 6),
          Text(_loadFailed ? 'Không tải được mèo. Hãy thử lại.' : 'BỘ KỸ NĂNG',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: _loadFailed ? const Color(0xFFB0503A) : DS.label,
                  fontSize: DS.fontMicro,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8)),
          const SizedBox(height: 6),
          Expanded(
              child: Column(children: [
            for (var row = 0; row < 2; row++) ...[
              if (row > 0) const SizedBox(height: 6),
              Expanded(
                  child: Row(children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: 6),
                  Expanded(
                      child: _skillCard(
                    skills[row * 2 + col].label,
                    skills[row * 2 + col].glyph,
                    skills[row * 2 + col].color,
                    skills[row * 2 + col].cooldown,
                    main: row == 0 && col == 0,
                  )),
                ],
              ])),
            ],
          ])),
          const SizedBox(height: 6),
          SizedBox(
              height: 40,
              child: Row(children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: DS.ink,
                      side: const BorderSide(color: DS.wood),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10)),
                  onPressed: _starting ? null : () => widget.onHelp(breed.id),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Combo',
                      style: TextStyle(
                          fontSize: DS.fontButton,
                          fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                const SizedBox(width: 8),
                SizedBox(
                    width: 156,
                    child: SizedBox.expand(
                        child: ElevatedButton.icon(
                      style: DS.primary,
                      onPressed: _starting ? null : _start,
                      icon: _starting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: DS.ink))
                          : const Icon(Icons.play_arrow_rounded, size: 23),
                      label: Text(_starting ? 'ĐANG TẢI' : 'BẮT ĐẦU',
                          style: const TextStyle(
                              color: DS.ink,
                              fontFamily: 'Roboto',
                              fontSize: DS.fontButton,
                              fontWeight: FontWeight.w900)),
                    ))),
              ])),
        ]),
      ),
    );
  }

  Widget _skillCard(
          String label, SkillGlyph glyph, Color color, double cooldown,
          {required bool main}) =>
      Tooltip(
        message:
            '$label · Hồi chiêu ${cooldown.toString().replaceAll('.0', '')} giây',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: main ? const Color(0xFFFFE9B9) : const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: main ? DS.gold : const Color(0x44B27A3E)),
          ),
          child: Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(9)),
              child: Center(child: SkillGlyphView(glyph, size: 21)),
            ),
            const SizedBox(width: 6),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: DS.ink,
                        fontSize: DS.fontCaption,
                        height: 1.15,
                        fontWeight: FontWeight.w800)),
                Text(
                    '${main ? 'Chiêu chính · ' : ''}${cooldown.toString().replaceAll('.0', '')}s',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: DS.soft, fontSize: DS.fontMicro, height: 1.15)),
              ],
            )),
          ]),
        ),
      );
}
