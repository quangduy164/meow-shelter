import 'dart:math';
import '../../audio/game_audio.dart';
import '../../camp/camp_state.dart';
import '../components/cat_component.dart';
import '../components/hud_component.dart';
import 'night_game.dart';
import 'night_run.dart';
import 'night_helpers.dart';
import '../cats/cat_assist.dart';

class NightHelperEffects {
  NightHelperEffects(this.night);
  final NightGame night;
  final assist = CatAssist();
  final cooldowns = <String, double>{};
  final _effects = <String, double>{};
  bool get acceptsAnyBed => _effects.containsKey('calico');

  void reset() {
    assist.reset();
    _effects.clear();
    cooldowns
      ..clear()
      ..addAll({for (final type in night.helpers) type: 0});
  }

  void beginNight() {
    _effects.clear();
    _syncAssist();
  }

  /// Full recharge time of a helper's skill.
  double cooldownTotal(String type) => NightHelperSkill.of[type]!
      .cooldownFor(scale: night.run?.cooldownScale ?? 1);

  /// Seconds left on a running helper effect (0 when off).
  double effectLeft(String type) => _effects[type] ?? 0;

  /// Fires a helper's skill if it is ready.
  void use(String type) {
    final skill = NightHelperSkill.of[type];
    if (night.run == null ||
        night.game.paused ||
        night.phase != NightPhase.playing ||
        skill == null ||
        night.game.hud.status != RoundStatus.playing ||
        night.game.overlays.isActive('nightCards') ||
        (cooldowns[type] ?? 1) > 0) {
      return;
    }
    cooldowns[type] = cooldownTotal(type);
    GameAudio.instance.playRescue(GameSound.homeSupport, important: true);
    night.game.hud.showBanner([
      CampState.instance.nameOf(type),
      NightHelperSkill.effectOn(type, night.run!.map)
    ], 2.5);
    if (skill.duration > 0) {
      _effects[type] = skill.duration;
      _syncAssist();
      return;
    }
    // Himalaya: maps without carrying use their own boost.
    if (night.scene.helperBoost(2) >= 0) return;
    // Otherwise two hungry cats are full at once.
    final cats = night.game.children
        .whereType<CatComponent>()
        .where((cat) => cat.canBless)
        .toList()
      ..shuffle(night.random);
    for (final cat in cats.take(2)) {
      cat.bless();
    }
  }

  void _syncAssist() {
    assist
      ..pace = _effects.containsKey('scottish') ? .5 : 1
      ..lure = night.run?.lure ?? 1
      ..calm = _effects.containsKey('black') || night.scene.peaceful
      ..frozen = _effects.containsKey('orange');
    night.game.hud.anyBed = _effects.containsKey('calico');
  }

  void update(double dt) {
    _syncAssist();
    for (final type in cooldowns.keys.toList()) {
      cooldowns[type] = max(0, cooldowns[type]! - dt);
    }
    for (final type in _effects.keys.toList()) {
      final left = _effects[type]! - dt;
      if (left > 0) {
        _effects[type] = left;
      } else {
        _effects.remove(type);
        _syncAssist();
      }
    }
  }
}
