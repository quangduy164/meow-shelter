import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../design.dart';
import 'game_surfaces.dart';

class AudioSettingsButton extends StatelessWidget {
  const AudioSettingsButton({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: DS.touchTarget,
        child: IconButton(
          tooltip: 'Cài đặt',
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DS.cream.withOpacity(.92),
              shape: BoxShape.circle,
              border: Border.all(color: DS.wood, width: DS.borderSubtle),
            ),
            child: const Icon(Icons.settings_rounded,
                size: DS.iconMd, color: DS.ink),
          ),
          padding: EdgeInsets.zero,
          onPressed: () {
            GameAudio.instance.play(GameSound.click);
            showGameDialog<void>(
              context: context,
              builder: (_) => const _AudioSettingsDialog(),
            );
          },
        ),
      );
}

class _AudioSettingsDialog extends StatelessWidget {
  const _AudioSettingsDialog();

  @override
  Widget build(BuildContext context) {
    final audio = GameAudio.instance;
    return GameDialog(
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
            GameDialogHeader(
              title: 'CÀI ĐẶT',
              icon: Icons.settings_rounded,
              closeTooltip: 'Đóng cài đặt',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: DS.spaceMd),
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
                          const SizedBox(height: DS.spaceSm),
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
                    const SizedBox(width: DS.spaceMd),
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
                          const Divider(height: DS.spaceLg),
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
            const SizedBox(height: DS.spaceSm),
            const SelectableText(
              'Nhạc: Purr Box — Purrple Cat · CC BY 4.0\n'
              'https://purrplecat.itch.io/cat-nap\n'
              'https://creativecommons.org/licenses/by/4.0/',
              textAlign: TextAlign.center,
              style: TextStyle(color: DS.soft, fontSize: DS.fontCaption),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(Widget child) => GamePanel(
      inset: true,
      padding: const EdgeInsets.symmetric(
          horizontal: DS.spaceMd, vertical: DS.spaceSm),
      child: child);

  Widget _toggle(String label, IconData icon, bool value,
          ValueChanged<bool> onChanged) =>
      Row(children: [
        Icon(icon, size: 18, color: value ? DS.goldEdge : DS.mutedText),
        const SizedBox(width: DS.spaceXs),
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
          const SizedBox(width: DS.spaceXs),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: DS.ink,
                      fontSize: DS.fontBody,
                      fontWeight: FontWeight.w800))),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DS.spaceXs, vertical: DS.space2),
            decoration: BoxDecoration(
                color: DS.cream,
                borderRadius: BorderRadius.circular(DS.radiusSm)),
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
