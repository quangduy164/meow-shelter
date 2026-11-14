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
  double _cooldown = 0;
  bool has(NightRelic relic) => night.run?.relics.contains(relic) == true;
  double get afterglowSeconds => has(NightRelic.embers) ? 4 : 0;
  void resetNight() => _cooldown = 0;

  bool freezesCat(CatComponent cat) =>
      has(NightRelic.prism) &&
      night.scene
          .overlappingLights(cat.center.toOffset(), night.game.size.toSize());

  void onFirstLight(Offset point, double reach) {
    if (has(NightRelic.bell)) _advanceNearby(point, reach, 'Chuông đèn');
  }

  void onRescue(CatComponent cat) {
    if (has(NightRelic.feastCharm) && night.lightsCat(cat)) {
      _advanceNearby(cat.center.toOffset(), 240, 'Bùa no bụng');
    }
  }

  void update(double dt, {required bool cloudsStarted}) {
    _cooldown = max(0, _cooldown - dt);
    if (has(NightRelic.moonPouch) && cloudsStarted && _cooldown <= 0) {
      for (final type in night.helperCooldown.keys.toList()) {
        night.helperCooldown[type] = max(0, night.helperCooldown[type]! - 3);
      }
      _cooldown = 10;
      night.game.hud.showBanner(['Túi trăng · trợ thủ hồi nhanh 3s'], 1.8);
    }
  }

  void _advanceNearby(Offset point, double reach, String relicName) {
    final cats = night.game.children
        .whereType<CatComponent>()
        .where((cat) =>
            cat.canBless && (cat.center.toOffset() - point).distance <= reach)
        .toList()
      ..sort((a, b) => (a.center.toOffset() - point)
          .distance
          .compareTo((b.center.toOffset() - point).distance));
    if (cats.isEmpty) return;
    cats.first.advanceRescueStep();
    night.game.hud.showBanner(['$relicName · +1 bước ăn/chơi'], 1.5);
  }
}
