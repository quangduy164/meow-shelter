import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameSound { click, meow, splash, bite, pickup, win, lose }

/// One music player and one effect player shared by all screens.
class GameAudio with WidgetsBindingObserver {
  GameAudio._();
  static final instance = GameAudio._();

  final musicVolume = ValueNotifier(1.0);
  final effectsVolume = ValueNotifier(1.0);
  final musicEnabled = ValueNotifier(true);
  final vibrationEnabled = ValueNotifier(true);
  SharedPreferences? _preferences;
  AudioPlayer? _music, _effect;
  bool _foreground = true, _musicLoaded = false, _homeActive = false;
  Future<void> _pending = Future.value();

  void initialize(SharedPreferences preferences) {
    _preferences = preferences;
    final previousVolume = (preferences.getDouble('audio_volume') ??
            (preferences.getBool('audio_enabled') == false ? 0.0 : 1.0))
        .clamp(0.0, 1.0);
    musicVolume.value =
        (preferences.getDouble('audio_music_volume') ?? previousVolume)
            .clamp(0.0, 1.0);
    effectsVolume.value =
        (preferences.getDouble('audio_effects_volume') ?? previousVolume)
            .clamp(0.0, 1.0);
    musicEnabled.value = preferences.getBool('audio_music_enabled') ?? true;
    vibrationEnabled.value = preferences.getBool('vibration_enabled') ?? true;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _enqueue(_sync);
  }

  Future<void> setMusicVolume(double value) {
    if (!value.isFinite) return Future.value();
    musicVolume.value = value.clamp(0.0, 1.0);
    return _saveAndSync();
  }

  void setHomeActive(bool value) {
    _homeActive = value;
    unawaited(_enqueue(_sync));
  }

  Future<void> setEffectsVolume(double value) {
    if (!value.isFinite) return Future.value();
    effectsVolume.value = value.clamp(0.0, 1.0);
    return _saveAndSync();
  }

  Future<void> setMusicEnabled(bool value) {
    musicEnabled.value = value;
    return _saveAndSync();
  }

  Future<void> setVibrationEnabled(bool value) {
    vibrationEnabled.value = value;
    return _saveAndSync();
  }

  Future<void> _saveAndSync() {
    return _enqueue(() async {
      await _preferences?.setDouble('audio_music_volume', musicVolume.value);
      await _preferences?.setDouble(
          'audio_effects_volume', effectsVolume.value);
      await _preferences?.setBool('audio_music_enabled', musicEnabled.value);
      await _preferences?.setBool('vibration_enabled', vibrationEnabled.value);
      await _sync();
    });
  }

  // Serialize playback and mute commands so a slow load cannot undo mute.
  Future<void> _enqueue(Future<void> Function() action) {
    _pending = _pending.then((_) => action()).catchError((Object error) {
      debugPrint('Audio unavailable: $error');
    });
    return _pending;
  }

  Future<void> _sync() async {
    if (!_foreground) {
      await _music?.pause();
      await _effect?.stop();
      return;
    }
    if (effectsVolume.value == 0) {
      await _effect?.stop();
    } else {
      await _effect?.setVolume(.4 * effectsVolume.value);
    }
    if (!_homeActive || !musicEnabled.value || musicVolume.value == 0) {
      await _music?.pause();
      return;
    }
    final music = _music ??= AudioPlayer()..audioCache = FlameAudio.audioCache;
    if (!_musicLoaded) {
      await music.setReleaseMode(ReleaseMode.loop);
      await music.play(AssetSource('background.wav'),
          volume: .12 * musicVolume.value);
      _musicLoaded = true;
    } else {
      await music.setVolume(.12 * musicVolume.value);
      if (music.state != PlayerState.playing) await music.resume();
    }
  }

  void play(GameSound sound) {
    if (_preferences == null || effectsVolume.value == 0 || !_foreground) {
      return;
    }
    final requested = DateTime.now();
    unawaited(_enqueue(() async {
      if (effectsVolume.value == 0 ||
          !_foreground ||
          DateTime.now().difference(requested).inMilliseconds > 300) return;
      final effect =
          _effect ??= AudioPlayer()..audioCache = FlameAudio.audioCache;
      await effect.stop();
      await effect.play(
        AssetSource('${sound.name}.wav'),
        volume: .4 * effectsVolume.value,
        // Effects must not take audio focus away from the background music.
        ctx: const AudioContext(
          android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
          iOS: AudioContextIOS(options: [
            AVAudioSessionOptions.mixWithOthers,
          ]),
        ),
      );
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    unawaited(_enqueue(_sync));
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _foreground = false;
    await _pending;
    await _music?.dispose();
    await _effect?.dispose();
    _music = _effect = null;
    _musicLoaded = false;
    _preferences = null;
  }
}
