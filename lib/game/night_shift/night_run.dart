import 'dart:math';
import 'night_cards.dart';
import 'night_relics.dart';
import 'night_variants.dart';

enum NightPhase { setup, briefing, playing, cards, shop, ended }

/// Progress of one night-shift run: the current night, its quota and every
/// bonus from the cards picked so far.
class NightRun {
  NightRun(this.helpers);

  /// Camp cats brought along (one or two breed ids).
  final List<String> helpers;
  final cards = <NightCard>[];
  int night = 1;
  NightVariant variant = NightVariant.yardNormal;
  NightArrival arrival = NightArrival.steady;
  int rescuedTonight = 0, spawnedTonight = 0;
  int totalRescued = 0, coins = 0;
  int silver = 0, lastSilverReward = 0, earnedMoonlight = 0;
  final relics = <NightRelic>[];

  /// Relic bag size; a 4th slot can be bought once in the shop.
  int relicSlots = 3;
  static const maxRelicSlots = 4, slotPrice = 80;

  /// Relic levels 1..3 (owned relics only) and what was paid for each.
  final relicLevels = <NightRelic, int>{};
  final _relicPaid = <NightRelic, int>{};

  /// Shop rerolls this visit; each one costs 5 more.
  int rerolls = 0;
  int get rerollPrice => 5 + 5 * rerolls;

  /// Separate run currency; never credited to the camp wallet.
  void rewardSilver({required int secondsLeft, required bool clean}) {
    final speedBonus = (4 * secondsLeft / seconds).floor().clamp(0, 4);
    lastSilverReward =
        ((12 + min(night * 2, 20) + speedBonus + (clean ? 3 : 0)) *
                (1 + moonlightBonus))
            .round();
    earnMoonlight(lastSilverReward);
  }

  void earnMoonlight(int amount) {
    assert(amount >= 0);
    silver += amount;
    earnedMoonlight += amount;
  }

  int relicLevel(NightRelic relic) =>
      relics.contains(relic) ? relicLevels[relic] ?? 1 : 0;
  int _up(NightRelic relic) => max(0, relicLevel(relic) - 1);

  /// Next level's price, or null at max level / not owned.
  int? upgradePrice(NightRelic relic) => switch (relicLevel(relic)) {
        1 => relic.price,
        2 => (relic.price * 1.5).round(),
        _ => null,
      };
  int sellPrice(NightRelic relic) => (_relicPaid[relic] ?? relic.price) ~/ 2;

  double get afterglowSeconds => relics.contains(NightRelic.embers)
      ? 4 +
          2.0 * _up(NightRelic.embers) +
          2.0 *
              (count(NightCard.longWick) +
                  count(NightCard.backupPower) +
                  count(NightCard.sturdyPlanks) +
                  count(NightCard.deepBait) +
                  count(NightCard.dewTracks) +
                  count(NightCard.slowCurrent) +
                  count(NightCard.longStop))
      : 0;
  int get bellTargets => min(
      3 + _up(NightRelic.bell),
      1 +
          _up(NightRelic.bell) +
          count(NightCard.extraLantern) +
          count(NightCard.widePlanks) +
          count(NightCard.reedBell) +
          count(NightCard.porter));
  double get bellReach =>
      1 +
      .2 * _up(NightRelic.bell) +
      .25 * count(NightCard.brightLantern) +
      (has(NightCard.railLights) ? .5 : 0);
  double get lightRecharge =>
      2 +
      _up(NightRelic.moonPouch) +
      (has(NightCard.fullMoon) ? 2 : 0) +
      count(NightCard.eagerHelpers).toDouble();
  double get cloudRecharge =>
      3 + _up(NightRelic.moonPouch) + count(NightCard.eagerHelpers).toDouble();
  double get chainWindow =>
      8 + 2.0 * (count(NightCard.warmHug) + _up(NightRelic.feastCharm));
  double get chainReach => 240 * (1 + .35 * count(NightCard.scentedFish));
  int chainTargets(int chain) =>
      chain < 2 ? 1 : 2 + (chain >= 3 && has(NightCard.patience) ? 1 : 0);
  int get prismReward =>
      3 +
      _up(NightRelic.prism) +
      (has(NightCard.fullMoon) ? 2 : 0) +
      count(NightCard.hotCoins);

  List<NightRelic> relicOffer(Random random) =>
      // Owned relics come back on the counter until they reach tier 3.
      (NightRelic.values.where((r) => relicLevel(r) < 3).toList()
            ..shuffle(random))
          .take(3)
          .toList();

  /// Counter price: new relics cost their base price, owned ones the next tier.
  int shopPrice(NightRelic relic) => upgradePrice(relic) ?? relic.price;

  /// Buys a new relic, or a second/third copy that raises its tier.
  bool buyRelic(NightRelic relic) {
    if (relics.contains(relic)) return upgradeRelic(relic);
    if (relics.length >= relicSlots ||
        relics.contains(relic) ||
        silver < relic.price) {
      return false;
    }
    silver -= relic.price;
    relics.add(relic);
    relicLevels[relic] = 1;
    _relicPaid[relic] = relic.price;
    return true;
  }

  bool sellRelic(NightRelic relic) {
    if (!relics.contains(relic)) return false;
    silver += sellPrice(relic);
    relics.remove(relic);
    relicLevels.remove(relic);
    _relicPaid.remove(relic);
    return true;
  }

  bool upgradeRelic(NightRelic relic) {
    final price = upgradePrice(relic);
    if (price == null || silver < price) return false;
    silver -= price;
    relicLevels[relic] = relicLevel(relic) + 1;
    _relicPaid[relic] = (_relicPaid[relic] ?? relic.price) + price;
    return true;
  }

  bool buySlot() {
    if (relicSlots >= maxRelicSlots || silver < slotPrice) return false;
    silver -= slotPrice;
    relicSlots++;
    return true;
  }

  int count(NightCard card) => cards.where((c) => c == card).length;
  bool has(NightCard card) => cards.contains(card);

  // Card bonuses.
  double get speed =>
      pow(.88, count(NightCard.lazyLunch)) *
      pow(1.15, count(NightCard.hotCoins)).toDouble();
  double get grip => 1 + .35 * count(NightCard.warmHug);
  double get ready => 1 + .35 * count(NightCard.patience);
  double get lure => 1 + .35 * count(NightCard.scentedFish);
  double get bedScale => 1 + .25 * count(NightCard.wideBeds);
  int get extraFish => 4 * count(NightCard.fishBasket);
  double get cooldownScale =>
      pow(.75, count(NightCard.eagerHelpers)).toDouble();
  // Map-specific contracts pay only on the map where their drawback applies.
  double get moonlightBonus =>
      .4 * count(NightCard.hotCoins) +
      .25 *
          (count(NightCard.crowd) +
              count(NightCard.hiddenFish) +
              switch (map) {
                NightMap.backyard =>
                  count(NightCard.nightWind) + count(NightCard.fewerLanterns),
                NightMap.marketAlley => count(NightCard.busyMarket),
                NightMap.rooftops => count(NightCard.stormyRoof),
                NightMap.warehouse ||
                NightMap.reedGarden ||
                NightMap.harbor ||
                NightMap.station ||
                NightMap.clawMachine =>
                  0,
              });

  // The night itself.
  int get quota => min(3 + night, 12);

  /// Cats on the field at once.
  int get fieldSize =>
      min(min(2 + night ~/ 2, 5) + count(NightCard.crowd), quota);
  int get seconds {
    final base = (22 + quota * 8) + 10 * count(NightCard.longNight);
    // Khế ước trăng's speed cost only bites where cats roam; elsewhere the
    // night is shorter instead.
    if (NightCard.carryMaps.contains(map)) return base;
    return (base * pow(.9, count(NightCard.hotCoins))).round();
  }

  /// Rotate rescue maps each night.
  // Test order: put the newest maps first.
  static const mapOrder = [
    NightMap.clawMachine,
    NightMap.station,
    NightMap.harbor,
    NightMap.warehouse,
    NightMap.reedGarden,
    NightMap.backyard,
    NightMap.marketAlley,
    NightMap.rooftops,
  ];
  NightMap mapFor(int night) => mapOrder[(night - 1) % mapOrder.length];
  NightMap get map => mapFor(night);

  double get lightTimeScale => map == NightMap.backyard
      ? .5 / (1 + .5 * count(NightCard.restingLight))
      : .5;
  int get baitPortions =>
      map == NightMap.rooftops && has(NightCard.sharedFish) ? 2 : 1;

  // Backyard bonuses.
  int get lanterns =>
      3 + count(NightCard.extraLantern) - count(NightCard.fewerLanterns);
  double get lanternBurn =>
      10 *
      (1 + .5 * count(NightCard.longWick)) /
      (has(NightCard.nightWind) ? 2 : 1);
  double get lanternLight => 1 + .25 * count(NightCard.brightLantern);

  /// Every fifth night ends with a boss cat.
  bool get bossNight => night % 5 == 0;

  /// Three cards for the night ahead on [next]: one general upgrade, one
  /// card for that map and one deal, filled from the others when a group
  /// has run out.
  List<NightCard> offer(Random random, NightMap next) {
    final open = NightCard.values
        .where((c) => count(c) < c.limit && c.availableOn(next))
        .toList()
      ..shuffle(random);
    final general = open.where((c) => !c.isDeal && c.map == null).toList();
    final mapCards = open.where((c) => !c.isDeal && c.map != null).toList();
    final deals = open.where((c) => c.isDeal).toList();
    final picks = <NightCard>[
      ...general.take(1),
      ...mapCards.take(1),
      ...deals.take(1),
    ];
    for (final card in [...general, ...mapCards, ...deals]) {
      if (picks.length >= 3) break;
      if (!picks.contains(card)) picks.add(card);
    }
    return picks;
  }
}
