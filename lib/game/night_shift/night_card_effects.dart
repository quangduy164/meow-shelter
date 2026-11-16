import 'dart:math';
import '../components/cat_component.dart';
import 'night_game.dart';
import 'night_cards.dart';

/// Common-card triggers are independent of map and relic triggers.
class NightCardEffects {
  NightCardEffects(this.night);
  final NightGame night;
  double _rhythmLeft = 0;
  int _earned = 0;
  void resetNight() {
    _rhythmLeft = 0;
    _earned = 0;
  }

  void update(double dt) => _rhythmLeft = max(0, _rhythmLeft - dt);
  void onRescue(CatComponent cat) {
    final run = night.run!;
    final recharge = 2 * run.count(NightCard.relayRescue);
    if (recharge > 0) {
      for (final type in night.helperCooldown.keys.toList()) {
        night.helperCooldown[type] =
            max(0, night.helperCooldown[type]! - recharge);
      }
    }
    final rank = run.count(NightCard.rescueRhythm);
    if (rank > 0) {
      final reward = _rhythmLeft > 0 ? min(rank, 6 - _earned) : 0;
      if (reward > 0) {
        run.earnMoonlight(reward);
        _earned += reward;
        night.game.hud
            .showBanner(['Cứu đúng nhịp · +$reward Nguyệt quang'], 1.5);
      }
      _rhythmLeft = run.chainWindow;
    }
  }

  void onFed(CatComponent fed) {
    final run = night.run!;
    final seconds = 2 * run.count(NightCard.nurturingMeal);
    if (seconds <= 0) return;
    final reach = 220 * (1 + .35 * run.count(NightCard.scentedFish));
    for (final cat in night.game.children.whereType<CatComponent>()) {
      if (cat == fed ||
          cat.isCarried ||
          cat.isDelivered ||
          !cat.catchWindow.canCatch ||
          (cat.center - fed.center).length > reach) {
        continue;
      }
      cat.catchWindow.ready = min(
          cat.catchWindow.ready + seconds, cat.catchWindow.readySeconds * 3);
    }
  }
}
