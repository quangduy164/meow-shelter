import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameSound {
  click,
  fishingCast,
  fishingBite,
  fishingHook,
  fishingTension,
  fishingCatch,
  fishingSnap,
  fishingEscape,
  baitDrop,
  catEat,
  catFed,
  catReady,
  catGrab,
  catRescue,
  catWrong,
  catStartle,
  rescueNotice,
  rescueMilestone,
  rescueWin,
  rescueLose,
  homeHit,
  homeSplash,
  homeFish,
  homeHeal,
  homeFire,
  homeIce,
  homeShadow,
  homeShield,
  homeSupport,
  homeImpact,
  homeCheckpoint,
  homeRespawn,
  homeWin,
  bossRoar,
  bossWarning,
  bossPhase,
  bossWin,
  herdJoin,
  herdBounce,
  herdVendor,
  herdStorm,
  herdTired,
  herdIceBreak,
  herdWin,
  herdLose,
  campPet,
  campLift,
  campDrop,
  campPlace,
  campBond,
  campBuy,
  campWelcome,
}

// Fishing WAVs: edited CC0 recordings from BigSoundBank, IDs 1529, 1531,
// 0183, 1435 and 0554 (https://bigsoundbank.com/).
// Rescue cats/food: BigSoundBank CC0 IDs 0494, 0436, 1472, 0407.
// Rescue UI: Kenney Interface Sounds (CC0), drop_002, maximize_001,
// error_003, question_001, confirmation_002/004, back_002.
// https://opengameart.org/content/interface-sounds
// Return Home: edited BigSoundBank CC0 1340 (fire), 2205 (ice), 0486 (growl),
// plus the above water/cat recordings and Kenney Interface Sounds (CC0):
// drop_004, pluck_001, scroll_003, glass_002, minimize_002, question_002,
// bong_001 and confirmation_001/002/003/004.
// Herd: BigSoundBank CC0 1473 (meow), 0584 (ball), 1075 (hush), 0908 (wind),
// mixed with the above CC0 cat, ice, water and Kenney cues.
// Camp: BigSoundBank CC0 0981 (purr), above 0494/1473 (meows), and Kenney
// Interface Sounds CC0 drop_001/003, pluck_002, confirmation_001/003.

/// One music player and one effect player shared by all screens.
class GameAudio with WidgetsBindingObserver {
  GameAudio._();
  static final instance = GameAudio._();

  final musicVolume = ValueNotifier(1.0);
  final effectsVolume = ValueNotifier(1.0);
  final musicEnabled = ValueNotifier(true);
  final vibrationEnabled = ValueNotifier(true);
  SharedPreferences? _preferences;
  AudioPlayer? _music, _effect, _reel;
  bool _reeling = false;
  bool _foreground = true, _musicLoaded = false, _homeActive = false;
  Future<void> _pending = Future.value();
  final _rescueClock = Stopwatch()..start();
  int _nextRescueSound = 0;
  final _lastRescueSounds = <GameSound, int>{};
  final _lastGameplaySounds = <GameSound, int>{};
  int _gameplaySoundUntil = 0, _gameplaySoundPriority = 0;

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
    await _syncReel();
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
      await music.play(AssetSource('background.mp3'),
          volume: .12 * musicVolume.value);
      _musicLoaded = true;
    } else {
      await music.setVolume(.12 * musicVolume.value);
      if (music.state != PlayerState.playing) await music.resume();
    }
  }

  void setFishingReeling(bool value) {
    if (_reeling == value) return;
    _reeling = value;
    unawaited(_enqueue(_syncReel));
  }

  Future<void> _syncReel() async {
    if (!_reeling ||
        !_foreground ||
        effectsVolume.value == 0 ||
        _preferences == null) {
      await _reel?.stop();
      return;
    }
    final reel = _reel ??= AudioPlayer()..audioCache = FlameAudio.audioCache;
    await reel.setVolume(.22 * effectsVolume.value);
    if (reel.state == PlayerState.playing) return;
    await reel.setReleaseMode(ReleaseMode.loop);
    await reel.play(
      AssetSource('fishingReel.wav'),
      volume: .22 * effectsVolume.value,
      ctx: const AudioContext(
        android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
        iOS: AudioContextIOS(options: [AVAudioSessionOptions.mixWithOthers]),
      ),
    );
  }

  void playRescue(GameSound sound, {bool important = false}) {
    if (_preferences == null || effectsVolume.value == 0 || !_foreground) {
      return;
    }
    final now = _rescueClock.elapsedMilliseconds;
    final previous = _lastRescueSounds[sound];
    if (previous != null && now - previous < 400) return;
    if (!important && now < _nextRescueSound) return;
    _lastRescueSounds[sound] = now;
    // Reserve a quiet gap so crowds cannot cut off a warning or result.
    _nextRescueSound = now + (important ? 700 : 280);
    play(sound);
  }

  void playGameplay(GameSound sound, {int priority = 0}) {
    if (_preferences == null || effectsVolume.value == 0 || !_foreground) {
      return;
    }
    final now = _rescueClock.elapsedMilliseconds;
    final previous = _lastGameplaySounds[sound];
    if (previous != null && now - previous < 350) return;
    if (now < _gameplaySoundUntil && priority <= _gameplaySoundPriority) return;
    _lastGameplaySounds[sound] = now;
    _gameplaySoundPriority = priority;
    // Hits and pickups cannot interrupt a warning, damage cue or result.
    _gameplaySoundUntil = now +
        (priority >= 2
            ? 650
            : priority == 1
                ? 300
                : 160);
    play(sound);
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
      if (sound == GameSound.click &&
          _rescueClock.elapsedMilliseconds < _gameplaySoundUntil) {
        return;
      }
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
    _reeling = false;
    await _pending;
    await _music?.dispose();
    await _effect?.dispose();
    await _reel?.dispose();
    _reel = null;
    _music = _effect = null;
    _musicLoaded = false;
    _preferences = null;
  }
}
