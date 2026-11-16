import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../../audio/game_audio.dart';
import '../../camp/camp_state.dart';
import '../../levels/level_config.dart';
import '../meow_shelter_game.dart';
import '../components/cat_component.dart';
import '../components/hud_component.dart';
import '../cats/cat_catch_rule.dart';
import 'night_scene.dart';
import 'night_run.dart';
import 'night_cards.dart';
import 'night_relics.dart';
import '../cats/cat_assist.dart';
import 'night_relic_effects.dart';
import 'night_card_effects.dart';
import 'night_helper_effects.dart';

/// Owns the night-shift rules; MeowShelterGame only hosts shared cats/fields.
class NightGame {
  NightGame(this.game) : random = game.random;
  final MeowShelterGame game;
  final Random random;
  List<String> helpers = const ['orange'];
  NightRun? run;
  NightPhase phase = NightPhase.setup;
  late final helperEffects = NightHelperEffects(this);
  CatAssist get assist => helperEffects.assist;
  Map<String, double> get helperCooldown => helperEffects.cooldowns;
  NightScene? _scene;
  NightScene get scene => _scene!;
  double get lanternBurn => scene.lanternBurn;
  bool _thickClouds = false, _bedTwist = false;
  List<NightCard> cardOffer = const [];
  List<NightRelic> shopOffer = const [];
  int _nightStartles = 0, _nightWrongDrops = 0;
  double _secondAccumulator = 0;
  late final relicEffects = NightRelicEffects(this);
  late final cardEffects = NightCardEffects(this);
  bool newRecord = false;
  int get nightSecondsLeft => game.hud.secondsLeft;
  List<String> get nightRules => List.unmodifiable(game.hud.nightNotes);
  bool get acceptsAnyBed => helperEffects.acceptsAnyBed;
  bool blocks(Rect bounds) => scene.blocks(bounds);
  bool allowsBait(Vector2 point) =>
      scene.allowsBait(point.toOffset(), game.size.toSize());
  Vector2? lureWaypoint(CatComponent cat, Vector2 target) {
    final point = scene.lureWaypoint(
        cat.position.toOffset() & cat.size.toSize(),
        target.toOffset(),
        game.size.toSize());
    return point == null ? null : Vector2(point.dx, point.dy);
  }

  Vector2? spawnPosition(Vector2 catSize) {
    final point =
        scene.spawnPosition(game.size.toSize(), catSize.toSize(), random);
    return point == null ? null : Vector2(point.dx, point.dy);
  }

  void onMistake() {
    if (phase == NightPhase.playing) scene.onMistake();
  }

  bool lightsCat(CatComponent cat) =>
      scene.isLit(cat.center.toOffset(), game.size.toSize());
  bool freezesCat(CatComponent cat) => relicEffects.freezesCat(cat);

  void reset() {
    // Queued scene components are absent from game.children while paused.
    _scene?.remove();
    for (final name in [
      'nightInfo',
      'nightCards',
      'nightShop',
      'nightSkills'
    ]) {
      game.overlays.remove(name);
    }
    run = NightRun(helpers);
    phase = NightPhase.setup;
    helperEffects.reset();
    _scene = createNightScene(run!.map, game,
        onFirstLight: relicEffects.onFirstLight);
    _recentTypes.clear();
    cardOffer = const [];
    shopOffer = const [];
    newRecord = false;
    _secondAccumulator = 0;
  }

  void mountScene() => scene.mount();

  void recordResult() {
    final run = this.run!;
    phase = NightPhase.ended;
    newRecord =
        CampState.instance.recordNightShift(run.night, run.totalRescued);
  }

  void onDelivered(CatComponent cat) {
    if (phase != NightPhase.playing) return;
    final run = this.run!;
    run.rescuedTonight += 1;
    run.totalRescued += 1;
    game.hud.tonight = run.rescuedTonight;
    relicEffects.onRescue(cat);
    cardEffects.onRescue(cat);
    scene.onRescue();
    run.coins += 5; // Camp rescue pays this small, fixed side reward.
    run.earnMoonlight(2);
    game.hud.silver = run.silver;
    if (run.rescuedTonight >= run.quota) {
      _endNight();
    } else {
      _fillField();
    }
  }

  /// Difficulty of the current night, with the run's card bonuses.
  LevelConfig catLevel() {
    final run = this.run!;
    final wave = run.night - 1;
    return LevelConfig(
      id: game.level.id,
      name: game.level.name,
      catTypes: game.level.catTypes,
      timeLimit: 0,
      speedMultiplier: (.8 + wave * .08).clamp(.8, 1.5) * run.speed,
      readySeconds: (3 - wave * .15).clamp(1.5, 3.0) * run.ready,
      gripSeconds: (4 - wave * .12).clamp(2.4, 4.0) * run.grip,
      skillTier: wave.clamp(0, 3),
      isInfinite: true,
    );
  }

  /// Harder breeds turn up more often as the nights go on, and the same
  /// breed never comes three times in a row.
  String _nightCatType() {
    final night = run!.night;
    final weights = {
      'orange': 3.0,
      'himalaya': 2.0 + night * .1,
      'scottish': 2.0 + night * .1,
      'calico': 1.0 + night * .2,
      'black': 1.0 + night * .2,
    };
    if (_recentTypes.length >= 2 && _recentTypes[0] == _recentTypes[1]) {
      weights.remove(_recentTypes[0]);
    }
    var roll = random.nextDouble() * weights.values.reduce((a, b) => a + b);
    var type = weights.keys.last;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) {
        type = entry.key;
        break;
      }
    }
    _recentTypes.insert(0, type);
    if (_recentTypes.length > 2) _recentTypes.removeLast();
    return type;
  }

  final _recentTypes = <String>[];

  /// Tops the field up to the night's crowd size until the quota is out.
  void _fillField() {
    final run = this.run!;
    // Counted from the run, not from game.children: removals and additions are
    // only applied on the next tick.
    var onField = run.spawnedTonight - run.rescuedTonight;
    while (onField < run.fieldSize && run.spawnedTonight < run.quota) {
      run.spawnedTonight += 1;
      onField += 1;
      // The last cat of a boss night is the boss.
      if (run.bossNight && run.spawnedTonight == run.quota) {
        final type = _nightCatType();
        game.spawnCat(type, boss: true);
        GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
        game.hud.showBanner(['Trùm xuất hiện!', CatCatchRule.bossHint(type)]);
      } else {
        game.spawnCat(_nightCatType());
      }
    }
  }

  /// Sets up the next night: map, twist, beds, fish, clock and first cats.
  void beginNight() {
    final run = this.run!;
    final night = run.night;
    _nightStartles = game.stats.startles;
    _nightWrongDrops = game.stats.wrongDrops;
    relicEffects.resetNight();
    cardEffects.resetNight();
    run
      ..rescuedTonight = 0
      ..spawnedTonight = 0;
    if (night > 1) game.shuffleShelters();
    for (final shelter in game.shelters) {
      final center = shelter.position + shelter.size / 2;
      shelter.size = game.bedSize * run.bedScale;
      shelter.position = center - shelter.size / 2;
    }
    // Introduce each map once before adding random night twists.
    var twist = run.night <= NightMap.values.length ? 0 : random.nextInt(4);
    if (twist == 1 && run.has(NightCard.fullMoon)) twist = 0;
    if (twist == 2 && run.has(NightCard.nailedBeds)) twist = 0;
    _thickClouds = twist == 1;
    _bedTwist = twist == 2;
    if (scene.map != run.map) {
      scene.remove();
      _scene = createNightScene(run.map, game,
          onFirstLight: relicEffects.onFirstLight);
      mountScene();
    }
    scene.begin(run,
        thickClouds: _thickClouds,
        afterglowSeconds: relicEffects.afterglowSeconds);
    game.resetBedTimer();
    var fish = twist == 3 ? 6 : 0;
    if (run.has(NightCard.hiddenFish)) fish = fish == 0 ? 8 : min(fish, 8);
    if (fish > 0) fish += run.extraFish;
    game.bait.reset(
        limit: fish,
        portions: run.baitPortions,
        refundAfter: run.has(NightCard.fishReserve) ? 12 : 0);
    game.hud
      ..notificationTop = scene.notificationTop
      ..fishLeft = game.bait.limited ? game.bait.fishCount : null
      ..night = night
      ..tonight = 0
      ..totalCats = run.quota
      ..secondsLeft = run.seconds;
    _secondAccumulator = 0;
    helperEffects.beginNight();
    game.hud
      ..bossNight = run.bossNight
      ..nightNotes = [
        '${run.map.title}: ${run.map.rule}',
        ...scene.rules,
        if (night == 1) 'Mèo trong vùng sáng ngoan hơn, chờ bế lâu gấp đôi',
        if (_thickClouds) 'Mây dày: trăng bị che lâu hơn',
        if (_bedTwist)
          'Các ổ dời chỗ sau mỗi ${MeowShelterGame.bedInterval.round()} giây',
        if (game.bait.limited) 'Chỉ có ${game.bait.fishCount} cá mồi cả đêm',
        if (run.bossNight) 'Con mèo cuối cùng là mèo trùm',
      ]
      ..nightTags = [
        if (_thickClouds) 'Mây dày',
        if (_bedTwist) 'Ổ dời chỗ',
        if (game.bait.limited) '${game.bait.fishCount} cá',
        if (run.bossNight) 'Có trùm',
      ]
      ..startNight();
    _fillField();
    if (run.has(NightCard.preparedBait)) {
      game.bait.place(Vector2(game.size.x * .5, game.size.y * .5), game.size,
          game.children.whereType<CatComponent>(),
          free: true);
    }
    phase = NightPhase.setup;
    if (!game.overlays.isActive('nightSetup')) openNightInfo();
  }

  /// Opens the briefing at night start or from the information button.
  void openNightInfo() {
    if (run == null ||
        game.hud.status != RoundStatus.playing ||
        game.overlays.isActive('nightInfo') ||
        game.overlays.isActive('nightSetup') ||
        game.overlays.isActive('nightCards') ||
        game.overlays.isActive('nightShop') ||
        game.overlays.isActive('catGuide')) return;
    phase = NightPhase.briefing;
    game.pauseEngine();
    game.overlays.remove('nightSkills');
    game.overlays.add('nightInfo');
  }

  void closeNightInfo() {
    if (phase != NightPhase.briefing) return;
    phase = NightPhase.playing;
    game.overlays.remove('nightInfo');
    game.overlays.add('nightSkills');
    game.resumeEngine();
  }

  /// Quota met: bank the night bonus and offer the cards.
  void _endNight() {
    if (phase != NightPhase.playing) return;
    phase = NightPhase.cards;
    final run = this.run!;
    GameAudio.instance.playRescue(GameSound.rescueMilestone, important: true);
    run.rewardSilver(
        secondsLeft: game.hud.secondsLeft,
        clean: game.stats.startles == _nightStartles &&
            game.stats.wrongDrops == _nightWrongDrops);
    game.hud.silver = run.silver;
    game.bait.reset();
    helperEffects.beginNight();
    cardOffer = run.offer(random, run.mapFor(run.night + 1));
    game.overlays.remove('nightSkills');
    game.overlays.add('nightCards');
    game.pauseEngine();
  }

  /// Takes a card from the end-of-night offer and starts the next night.
  void chooseCard(NightCard card) {
    final run = this.run;
    if (run == null || phase != NightPhase.cards || !cardOffer.contains(card)) {
      return;
    }
    run.cards.add(card);
    _afterCards();
  }

  /// An exhausted card pool must not block the rest of an endless run.
  void continueWithoutCard() {
    if (phase != NightPhase.cards || cardOffer.isNotEmpty) return;
    _afterCards();
  }

  void _afterCards() {
    final run = this.run!;
    game.overlays.remove('nightCards');
    if (run.night.isEven) {
      phase = NightPhase.shop;
      shopOffer = run.relicOffer(random);
      game.overlays.add('nightShop');
    } else {
      _nextNight();
    }
  }

  bool buyRelic(NightRelic relic) {
    final run = this.run;
    if (run == null ||
        phase != NightPhase.shop ||
        !shopOffer.contains(relic) ||
        !run.buyRelic(relic)) return false;
    game.hud.silver = run.silver;
    GameAudio.instance.playRescue(GameSound.rescueMilestone, important: true);
    return true;
  }

  bool sellRelic(NightRelic relic) {
    final run = this.run;
    if (run == null || phase != NightPhase.shop || !run.sellRelic(relic)) {
      return false;
    }
    game.hud.silver = run.silver;
    GameAudio.instance.playRescue(GameSound.rescueMilestone, important: true);
    return true;
  }

  void leaveNightShop() {
    if (phase != NightPhase.shop) return;
    game.overlays.remove('nightShop');
    _nextNight();
  }

  void _nextNight() {
    run!.night += 1;
    beginNight();
  }

  double helperCooldownTotal(String type) => helperEffects.cooldownTotal(type);
  double effectLeft(String type) => helperEffects.effectLeft(type);
  void useHelper(String type) => helperEffects.use(type);

  void update(double dt) {
    if (phase != NightPhase.playing) return;
    final wasCloudy = scene.cloudy;
    scene.update(dt);
    relicEffects.update(dt, cloudsStarted: !wasCloudy && scene.cloudy);
    helperEffects.update(dt);
    cardEffects.update(dt);
    if (_bedTwist) game.updateMovingBeds(dt);
    if (game.outOfFish) {
      game.lostReason = 'HẾT CÁ RỒI!';
      game.showResult(RoundStatus.lost);
      return;
    }
    _secondAccumulator += dt;
    while (_secondAccumulator >= 1 && phase == NightPhase.playing) {
      _secondAccumulator -= 1;
      game.hud.secondsLeft -= 1;
      if (game.hud.secondsLeft == 10) {
        GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
      }
      if (game.hud.secondsLeft <= 0) {
        game.lostReason = 'TRỜI SÁNG MẤT RỒI!';
        game.showResult(RoundStatus.lost);
      }
    }
  }
}
