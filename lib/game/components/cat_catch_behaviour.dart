part of 'cat_component.dart';

/// Per-breed catch rules (see [CatBreed.catchRule] for the player-facing text
/// and [CatCatchRule] for the tuning numbers), plus the small overlays drawn
/// above a cat. Kept apart from movement and drag handling in [CatComponent]
/// so a breed's rule can be read and changed in one place.
extension CatCatchBehaviour on CatComponent {
  /// Per-breed bait rules; see [CatCatchRule].
  bool acceptsBait(Vector2 point, Iterable<CatComponent> cats) =>
      switch (catType) {
        'calico' => false,
        'himalaya' => (_center - point).length >= CatCatchRule.shyDistance,
        'black' => !cats.any((other) =>
            other != this &&
            !other.isDelivered &&
            (other._center - point).length < CatCatchRule.lonelyDistance),
        _ => true,
      };

  /// A shy cat bolts when fish lands right next to it.
  void startleBy(Vector2 point) {
    if (catType != 'himalaya' || !canLure) return;
    if ((_center - point).length >= CatCatchRule.shyDistance) return;
    _dodge();
    _dialogue.say('Á! Giật cả mình!');
  }

  /// Small counter above the cat for multi-step catches.
  void _drawProgress(Canvas canvas) {
    final label = catType == 'scottish' && _meals > 0 && !hasEaten
        ? '🐟 $_meals/${CatCatchRule.scottishMeals}'
        : catType == 'calico' && _playTaps > 0
            ? '♥ $_playTaps/${CatCatchRule.calicoTaps}'
            : null;
    if (label == null) return;
    final text = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(
                color: Color(0xFFFFF4DA),
                fontSize: 12,
                fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr)
      ..layout();
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
    final text = TextPainter(
        text: TextSpan(
            text: line,
            style: const TextStyle(
                color: Color(0xFF31564C),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center)
      ..layout(maxWidth: min(154, gameRef.size.x - 32));
    final width = text.width + 16;
    final left = (size.x / 2 - width / 2)
        .clamp(8 - position.x, gameRef.size.x - position.x - width - 8);
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
    if (catType == 'scottish' && _meals < CatCatchRule.scottishMeals) {
      _dialogue.say('Chưa no! Thêm cá nữa đi!');
      _pickNextAction();
      return;
    }
    hasEaten = true;
    _setState(CatState.idle);
    if (catType == 'orange') {
      catchWindow.open(CatCatchRule.orangeNap);
      _dialogue.say('No quá… khò khò');
    } else {
      catchWindow.open();
    }
  }

  /// Calico ignores fish; three quick taps tire it out instead.
  void _play() {
    _playTaps += 1;
    _playTimer = 3;
    _actionTimer = 0;
    _velocityY = 0;
    _setState(CatState.idle);
    _currentActionDuration = .8;
    if (_playTaps < CatCatchRule.calicoTaps) {
      _dialogue.say('Chơi nữa đi!');
      return;
    }
    _playTaps = 0;
    hasEaten = true;
    catchWindow.open();
    _dialogue.say('Mệt rồi, bế em đi…');
  }
}
