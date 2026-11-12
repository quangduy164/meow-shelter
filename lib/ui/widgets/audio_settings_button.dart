import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../design.dart';

class AudioSettingsButton extends StatelessWidget {
  const AudioSettingsButton({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Cài đặt',
        child: SizedBox.square(
          dimension: 48,
          child: IconButton(
            tooltip: 'Cài đặt',
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: DS.cream.withOpacity(.92),
                shape: BoxShape.circle,
                border: Border.all(color: DS.wood, width: 1.5),
              ),
              child:
                  const Icon(Icons.settings_rounded, size: 19, color: DS.ink),
            ),
            padding: EdgeInsets.zero,
            onPressed: () {
              GameAudio.instance.play(GameSound.click);
              showDialog<void>(
                context: context,
                barrierColor: DS.scrim,
                builder: (_) => const _AudioSettingsDialog(),
              );
            },
          ),
        ),
      );
}

class _AudioSettingsDialog extends StatelessWidget {
  const _AudioSettingsDialog();

  @override
  Widget build(BuildContext context) {
    final audio = GameAudio.instance;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: DS.cream,
      shape: DS.dialogShape,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              audio.musicVolume,
              audio.effectsVolume,
              audio.musicEnabled,
              audio.vibrationEnabled,
            ]),
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: DS.gold,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.settings_rounded,
                        color: DS.ink, size: 23),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('CÀI ĐẶT',
                        style: TextStyle(
                            color: DS.ink,
                            fontSize: DS.fontTitle,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .6)),
                  ),
                  IconButton(
                    tooltip: 'Đóng cài đặt',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: DS.ink),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 168,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _panel(Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _volumeControl(
                                context,
                                'Nhạc nền',
                                Icons.music_note_rounded,
                                audio.musicVolume.value,
                                audio.setMusicVolume,
                              ),
                              const SizedBox(height: 8),
                              _volumeControl(
                                context,
                                'Hiệu ứng',
                                Icons.volume_up_rounded,
                                audio.effectsVolume.value,
                                audio.setEffectsVolume,
                                onChangeEnd: (_) => audio.play(GameSound.click),
                              ),
                            ],
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _panel(Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _toggle(
                                'Phát nhạc',
                                Icons.music_note_rounded,
                                audio.musicEnabled.value,
                                audio.setMusicEnabled,
                              ),
                              const Divider(
                                  height: 16, color: Color(0x33B27A3E)),
                              _toggle(
                                'Rung',
                                Icons.vibration_rounded,
                                audio.vibrationEnabled.value,
                                audio.setVibrationEnabled,
                              ),
                            ],
                          )),
                        ),
                      ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x55B27A3E)),
        ),
        child: child,
      );

  Widget _toggle(String label, IconData icon, bool value,
          ValueChanged<bool> onChanged) =>
      Row(children: [
        Icon(icon, size: 18, color: value ? DS.goldEdge : DS.mutedText),
        const SizedBox(width: 6),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: DS.ink,
                    fontSize: DS.fontBody,
                    fontWeight: FontWeight.w800))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: DS.goldEdge,
          activeTrackColor: DS.gold,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]);

  Widget _volumeControl(BuildContext context, String title, IconData icon,
          double value, ValueChanged<double> onChanged,
          {ValueChanged<double>? onChangeEnd}) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Icon(icon, size: 19, color: DS.goldEdge),
          const SizedBox(width: 6),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: DS.ink,
                      fontSize: DS.fontBody,
                      fontWeight: FontWeight.w800))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: DS.cream, borderRadius: BorderRadius.circular(7)),
            child: Text('${(value * 100).round()}%',
                style: const TextStyle(
                    color: DS.goldEdge,
                    fontSize: DS.fontCaption,
                    fontWeight: FontWeight.w900)),
          ),
        ]),
        SizedBox(
          height: 38,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              divisions: 20,
              label: '${(value * 100).round()}%',
              semanticFormatterCallback: (v) =>
                  '$title ${(v * 100).round()} phần trăm',
              activeColor: DS.goldEdge,
              inactiveColor: DS.mutedFill,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ),
      ]);
}
