import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../components/cat_component.dart';
import 'night_game.dart';
import 'night_relics.dart';

/// All relic triggers and limits live here. None auto-deliver a cat.
class NightRelicEffects {
  NightRelicEffects(this.night);
  final NightGame night;
  double _cooldown = 0, _chainLeft = 0;
  int _chain = 0;
  bool has(NightRelic relic) => night.run?.relics.contains(relic) == true;
  double get afterglowSeconds => night.run?.afterglowSeconds ?? 0;
  void resetNight() {
    _cooldown = _chainLeft = 0;
    _chain = 0;
  }

  bool freezesCat(CatComponent cat) =>
      has(NightRelic.prism) &&
      night.scene
          .overlappingLights(cat.center.toOffset(), night.game.size.toSize());

  void onFirstLight(Offset point, double reach) {
    final run = night.run!;
    if (has(NightRelic.bell)) {
      _advanceNearby(
          point, reach * run.bellReach, 'Chuông đèn', run.bellTargets);
    }
    if (has(NightRelic.moonPouch)) _recharge(run.lightRecharge);
  }

  void onRescue(CatComponent cat) {
    final run = night.run!;
    if (!night.lightsCat(cat)) {
      _chain = 0;
      _chainLeft = 0;
      return;
    }
    if (has(NightRelic.feastCharm)) {
      _chain = _chainLeft > 0 ? _chain + 1 : 1;
      _chainLeft = run.chainWindow;
      _advanceNearby(cat.center.toOffset(), run.chainReach,
          'Liên hoàn x$_chain', run.chainTargets(_chain));
    }
    if (has(NightRelic.prism)) {
      final overlap = night.scene
          .overlappingLights(cat.center.toOffset(), night.game.size.toSize());
      final reward = (overlap ? run.prismReward : 0) +
          (has(NightRelic.feastCharm) && _chain >= 3 ? 2 : 0);
      if (reward > 0) {
        run.earnMoonlight(reward);
        night.game.hud.showBanner(['Lăng kính · +$reward Nguyệt quang'], 1.5);
      }
    }
  }

  void update(double dt, {required bool cloudsStarted}) {
    _cooldown = max(0, _cooldown - dt);
    _chainLeft = max(0, _chainLeft - dt);
    if (has(NightRelic.moonPouch) && cloudsStarted && _cooldown <= 0) {
      _recharge(night.run!.cloudRecharge);
      _cooldown = 10;
    }
  }

  void _recharge(double seconds) {
    for (final type in night.helperCooldown.keys.toList()) {
      night.helperCooldown[type] =
          max(0, night.helperCooldown[type]! - seconds);
    }
    night.game.hud
        .showBanner(['Túi trăng · trợ thủ hồi nhanh ${seconds.round()}s'], 1.5);
  }

  void _advanceNearby(
      Offset point, double reach, String relicName, int targets) {
    final helped = night.scene.helpNear(point, reach, targets);
    if (helped >= 0) {
      if (helped > 0) {
        night.game.hud.showBanner(['$relicName · giúp $helped mèo'], 1.5);
      }
      return;
    }
    final cats = night.game.children
        .whereType<CatComponent>()
        .where((cat) =>
            cat.canBless && (cat.center.toOffset() - point).distance <= reach)
        .toList()
      ..sort((a, b) => (a.center.toOffset() - point)
          .distance
          .compareTo((b.center.toOffset() - point).distance));
    if (cats.isEmpty) return;
    for (final cat in cats.take(targets)) {
      cat.advanceRescueStep();
    }
    night.game.hud.showBanner(
        ['$relicName · ${min(cats.length, targets)} mèo tiến 1 bước'], 1.5);
  }
}
