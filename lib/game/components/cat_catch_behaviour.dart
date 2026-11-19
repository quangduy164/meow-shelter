part of 'cat_component.dart';

/// Per-breed catch rules (see [CatBreed.catchRule] for the player-facing text
/// and [CatCatchRule] for the tuning numbers), plus the small overlays drawn
/// above a cat. Kept apart from movement and drag handling in [CatComponent]
/// so a breed's rule can be read and changed in one place.
extension CatCatchBehaviour on CatComponent {
  /// Per-breed bait rules; see [CatCatchRule].
  bool acceptsBait(Vector2 point, Iterable<CatComponent> cats,
          [Dish dish = Dish.fish]) =>
      (lureWaypoint == null || lureWaypoint!(this, point) != null) &&
      (craving == null || craving == dish) &&
      (catType != 'black' || moonlit == null || moonlit!(point)) &&
      (dish != Dish.yarn ||
          catType == 'calico' ||
          (_center - point).length < CatCatchRule.yarnPull) &&
      switch (catType) {
        'calico' => dish == Dish.yarn,
        _ when dish == Dish.yarn => true,
        'himalaya' => (_center - point).length >= _shyDistance,
        'black' => !cats.any((other) =>
            other != this &&
            !other.isDelivered &&
            (other._center - point).length <
                CatCatchRule.lonelyDistance *
                    (isBoss ? CatCatchRule.bossLonelyScale : 1)),
        _ => true,
      };

  double get _shyDistance =>
      CatCatchRule.shyDistance * (isBoss ? CatCatchRule.bossShyScale : 1);

  int get mealsNeeded => _mealsNeeded;

  int get _mealsNeeded =>
      menu?.length ?? CatCatchRule.mealsFor(catType, boss: isBoss);

  /// Random courses with no dish twice in a row.
  List<Dish> _orderMenu(int courses) {
    final dishes = <Dish>[];
    while (dishes.length < courses) {
      final next = Dish.foods[_random.nextInt(Dish.foods.length)];
      if (dishes.isEmpty || dishes.last != next) dishes.add(next);
    }
    return dishes;
  }

  /// A Scottish turning its nose up at the wrong dish.
  void refuseDish(Dish dish) {
    _dialogue
        .say('Không ăn ${dish.label} đâu! Muốn ${craving?.label ?? ''} cơ');
  }

  /// Thought bubble with the wanted dish; the boss also shows what is next.
  void _drawCraving(Canvas canvas) {
    final wants = craving;
    if (wants == null || _isDelivered || catchWindow.canCatch || _isDragged) {
      return;
    }
    final upcoming = menu!.skip(_meals).toList();
    final bob = sin(_bubbleClock * 3) * 1.5;
    final width = 34.0 + (upcoming.length - 1) * 22;
    // Float above the right ear; flip to the left ear near the screen edge.
    final right = position.x + size.x * .82 + width < game.size.x - 4;
    final dotX = right ? size.x * .62 : size.x * .38;
    final dot2X = right ? size.x * .7 : size.x * .3;
    final firstX = right ? size.x * .82 : size.x * .18 - (width - 34);
    final center = Offset(firstX, -16 + bob);
    final bubble = Rect.fromLTWH(firstX - 17, center.dy - 15, width, 30);
    final fill = Paint()..color = const Color(0xF7FFFDF4);
    final edge = Paint()
      ..color = const Color(0xFF8A6446)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(dotX, 4 + bob), 3, fill);
    canvas.drawCircle(Offset(dotX, 4 + bob), 3, edge);
    canvas.drawCircle(Offset(dot2X, -4 + bob), 4.5, fill);
    canvas.drawCircle(Offset(dot2X, -4 + bob), 4.5, edge);
    final shape = RRect.fromRectAndRadius(bubble, const Radius.circular(15));
    canvas.drawRRect(shape, fill);
    canvas.drawRRect(shape, edge);
    for (var i = 0; i < upcoming.length; i++) {
      canvas.save();
      canvas.translate(center.dx + i * 22, center.dy);
      canvas.scale(i == 0 ? .6 : .42);
      drawDish(canvas, Offset.zero, upcoming[i]);
      canvas.restore();
    }
    if (upcoming.length > 1) {
      // Arrows between courses read as "then".
      for (var i = 1; i < upcoming.length; i++) {
        final x = center.dx + i * 22 - 11;
        canvas.drawLine(
            Offset(x - 2, center.dy - 3), Offset(x + 1, center.dy), edge);
        canvas.drawLine(
            Offset(x + 1, center.dy), Offset(x - 2, center.dy + 3), edge);
      }
    }
  }

  int get _tapsNeeded =>
      isBoss ? CatCatchRule.bossTaps : CatCatchRule.calicoTaps;

  /// Small gold crown that marks a boss cat.
  void _drawCrown(Canvas canvas) {
    final cx = size.x / 2;
    final top = size.y * .02;
    final crown = Path()
      ..moveTo(cx - 13, top + 12)
      ..lineTo(cx - 15, top)
      ..lineTo(cx - 7, top + 6)
      ..lineTo(cx, top - 4)
      ..lineTo(cx + 7, top + 6)
      ..lineTo(cx + 15, top)
      ..lineTo(cx + 13, top + 12)
      ..close();
    canvas.drawPath(crown.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x55402616));
    canvas.drawPath(crown, Paint()..color = const Color(0xFFFFC24D));
    canvas.drawPath(
        crown,
        Paint()
          ..color = const Color(0xFF9A6028)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    for (final x in [-7.0, 0.0, 7.0]) {
      canvas.drawCircle(Offset(cx + x, top + 9), 1.8,
          Paint()..color = const Color(0xFFD9657B));
    }
  }

  /// A shy cat bolts when fish lands right next to it.
  void startleBy(Vector2 point) {
    if (catType != 'himalaya' || !canLure) return;
    if ((_center - point).length >= _shyDistance) return;
    _startle();
    _dialogue.say('Á! Giật cả mình!');
  }

  /// Small counter above the cat for multi-step catches.
  void _drawProgress(Canvas canvas) {
    final label = _mealsNeeded > 1 && _meals > 0 && !hasEaten
        ? '🐟 $_meals/$_mealsNeeded'
        : catType == 'calico' && _playTaps > 0
            ? '♥ $_playTaps/$_tapsNeeded'
            : null;
    if (label == null) return;
    final text = TextCache.layout(
        label,
        const TextStyle(
            color: Color(0xFFFFF4DA),
            fontSize: DS.fontBody,
            fontWeight: FontWeight.w800));
    final box = Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 10),
        width: text.width + 12,
        height: text.height + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(8)),
        Paint()..color = const Color(0xCC5A3214));
    text.paint(canvas, Offset(box.left + 6, box.top + 2));
  }

  void _drawDialogue(Canvas canvas) {
    final line = _dialogue.text;
    if (line == null) return;
    final text = TextCache.layout(
        line,
        const TextStyle(
            color: Color(0xFF31564C),
            fontSize: DS.fontCaption,
            fontWeight: FontWeight.w600),
        maxWidth: min(154, game.size.x - 32),
        textAlign: TextAlign.center);
    final width = text.width + 16;
    final left = (size.x / 2 - width / 2)
        .clamp(8 - position.x, game.size.x - position.x - width - 8);
    final below = position.y < text.height + 34;
    final top = below ? size.y + 8 : -text.height - 20;
    final bubble = Rect.fromLTWH(left, top, width, text.height + 12);
    final fill = Paint()..color = const Color(0xF5FFFBEA);
    final tailX = (size.x / 2).clamp(bubble.left + 8, bubble.right - 8);
    canvas.drawPath(
        Path()
          ..moveTo(tailX - 4, below ? bubble.top : bubble.bottom)
          ..lineTo(tailX, below ? bubble.top - 6 : bubble.bottom + 6)
          ..lineTo(tailX + 4, below ? bubble.top : bubble.bottom)
          ..close(),
        fill);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bubble, const Radius.circular(7)), fill);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bubble, const Radius.circular(7)),
        Paint()
          ..color = const Color(0x99658670)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    text.paint(canvas, Offset(bubble.left + 8, bubble.top + 6));
  }

  void _eat() {
    _meals += 1;
    onFed?.call(this);
    final mat =
        _meals >= _mealsNeeded && isBoss ? napSpot?.call(_center) : null;
    if (mat != null) {
      // Full: the fat orange boss waddles to the nearest straw mat first
      // and can only be picked up once it is asleep there.
      GameAudio.instance.playRescue(GameSound.catEat);
      _goingToNap = true;
      fishTarget = mat;
      _lureDish = Dish.fish;
      _velocityY = 0;
      _setState(CatState.walk);
      _dialogue.say('No căng bụng! Về ổ rơm ngủ thôi…');
      return;
    }
    if (_meals < _mealsNeeded) {
      GameAudio.instance.playRescue(GameSound.catEat);
      final wants = menu;
      if (wants != null && isBoss && !_changedMind && _meals == 1) {
        // The boss changes its mind about the next course, once.
        _changedMind = true;
        final old = wants[1];
        var next = old;
        while (next == old || next == wants[0]) {
          next = Dish.foods[_random.nextInt(Dish.foods.length)];
        }
        wants[1] = next;
        _dialogue.say('Đổi ý rồi! Giờ muốn ${next.label} cơ');
      } else if (wants != null) {
        _dialogue.say('Ngon! Món tiếp: ${craving!.label}');
      } else {
        _dialogue
            .say(isBoss ? 'Bụng to lắm, thêm cá!' : 'Chưa no! Thêm cá nữa đi!');
      }
      _pickNextAction();
      return;
    }
    hasEaten = true;
    GameAudio.instance.playRescue(GameSound.catFed, important: true);
    _setState(CatState.idle);
    if (catType == 'orange') {
      catchWindow.open(CatCatchRule.orangeNap);
      _dialogue.say('No quá… khò khò');
    } else {
      catchWindow.open();
    }
  }

  /// Whether the Himalaya helper's blessing can fill this cat up now.
  bool get canBless =>
      !trapManaged &&
      !hiddenInCover &&
      isLoaded &&
      !_isDelivered &&
      !_isDragged &&
      !_isDropWrong &&
      !_isEscaping &&
      !catchWindow.canCatch;

  /// Relics advance the normal multi-step rule; they never deliver a cat.
  void advanceRescueStep() {
    if (!canBless) return;
    if (trapCapture) {
      bless();
      return;
    }
    fishTarget = null;
    _dodgeTime = 0;
    _isVanishing = false;
    _isTapTriggered = false;
    _skillActive = false;
    _velocityY = 0;
    if (catType == 'calico') {
      _play();
    } else {
      _eat();
    }
  }

  /// Night-shift blessing: the cat is full at once and ready to carry.
  void bless() {
    fishTarget = null;
    _meals = _mealsNeeded;
    _playTaps = 0;
    hasEaten = true;
    _dodgeTime = 0;
    _isVanishing = false;
    _hasTeleported = false;
    _isTapTriggered = false;
    _skillActive = false;
    _velocityY = 0;
    _setState(CatState.idle);
    catchWindow.open(catType == 'orange' ? CatCatchRule.orangeNap : 1);
    _dialogue.say('Được ban phước, ngoan rồi!');
  }

  /// Calico ignores fish; three quick taps tire it out instead.
  /// Reached the straw mat (or gave up getting there): fall asleep.
  void _napNow() {
    _goingToNap = false;
    hasEaten = true;
    GameAudio.instance.playRescue(GameSound.catFed, important: true);
    _setState(CatState.idle);
    catchWindow.open(CatCatchRule.orangeNap);
    _dialogue.say('Khò khò… bế em đi');
  }

  /// Seconds per beat the Calico boss taps along to; taps count only on it.
  static const _beat = .9;
  double get beatPhase => (_bubbleClock % _beat) / _beat;
  bool get _onBeat => beatPhase < .2 || beatPhase > .8;
  bool get _keepsRhythm => isBoss && level.toys && catType == 'calico';

  /// Arrived at a ball of yarn. Calico plays and tires itself out (the boss
  /// only sits still to play); anyone else just bats the ball away.
  void _reachYarn() {
    _velocityY = 0;
    if (catType != 'calico') {
      _dialogue.say('Lăn nè!');
      onKickToy?.call(this);
      _pickNextAction();
      return;
    }
    _setState(CatState.celebrate);
    if (_keepsRhythm) {
      _yarnPlay = 3.5;
      _dialogue.say('Len! Chạm theo nhịp với em nào!');
      return;
    }
    _yarnPlay = 1.2;
    _playTaps = 0;
    hasEaten = true;
    GameAudio.instance.playRescue(GameSound.catReady, important: true);
    catchWindow.open();
    _dialogue.say('Chơi len vui quá… mệt rồi');
  }

  /// Pulsing beat ring around the Calico boss: tap when it flashes gold.
  void _drawBeat(Canvas canvas) {
    // Shown whenever taps are judged on the beat, including after an unused
    // catch window ran out (hasEaten stays true then).
    if (!_keepsRhythm || catchWindow.canCatch || _isDelivered || _isDragged) {
      return;
    }
    final on = _onBeat;
    final pulse = 1 - (beatPhase < .5 ? beatPhase : 1 - beatPhase) * 2;
    final center = Offset(size.x / 2, size.y * .55);
    canvas.drawCircle(
        center,
        size.x * (.42 + pulse * .12),
        Paint()
          ..color = on ? const Color(0xCCFFC24D) : const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = on ? 4 : 2);
    for (var i = 0; i < _tapsNeeded; i++) {
      final x = size.x / 2 + (i - (_tapsNeeded - 1) / 2) * 9;
      canvas.drawCircle(
          Offset(x, size.y + 4),
          3.2,
          Paint()
            ..color = i < _playTaps
                ? const Color(0xFFE77FA0)
                : const Color(0x88FFFFFF));
    }
  }

  void _play() {
    if (_keepsRhythm && !_onBeat) {
      // Off the beat: the boss throws a tantrum and knocks toys over.
      _playTaps = 0;
      _dialogue.say('Sai nhịp rồi! Hứ!');
      GameAudio.instance.playRescue(GameSound.catWrong);
      onTantrum?.call(this);
      return;
    }
    _playTaps += 1;
    _playTimer = 3;
    _actionTimer = 0;
    _velocityY = 0;
    _setState(CatState.idle);
    _currentActionDuration = .8;
    if (_playTaps < _tapsNeeded) {
      GameAudio.instance.playRescue(GameSound.catGrab);
      _dialogue.say('Chơi nữa đi!');
      return;
    }
    _playTaps = 0;
    hasEaten = true;
    GameAudio.instance.playRescue(GameSound.catReady, important: true);
    catchWindow.open();
    _dialogue.say('Mệt rồi, bế em đi…');
  }
}
