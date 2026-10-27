import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../constants.dart';
import '../cats/cat_state.dart';
import '../cats/cat_animations.dart';
import '../catch_window.dart';

/// A draggable cat. The game decides whether the cat was dropped in its
/// matching shelter through [onDrop].
class CatComponent extends SpriteAnimationGroupComponent<CatState>
    with HasGameRef<FlameGame>, DragCallbacks, TapCallbacks {
  CatComponent({
    required Vector2 position,
    required this.catType,
    required this.onDrop,
    required this.onDelivered,
    required this.onEscaped,
    required this.isPlaying,
    this.fullBehavior = false,
  }) : super(
          position: position,
          size: Vector2(catWidth, catHeight),
          current: CatState.idle,
        );

  final String catType;
  final bool Function() isPlaying;
  final catchWindow = CatchWindow();
  Vector2? fishTarget;
  double _dodgeTime = 0;
  bool get canLure =>
      isLoaded &&
      !_isDelivered &&
      !_isDragged &&
      !_isDropWrong &&
      !_isEscaping &&
      fishTarget == null &&
      !catchWindow.canCatch &&
      _dodgeTime <= 0;

  void lure(Vector2 target) {
    if (!canLure) return;
    fishTarget = target.clone();
    _isVanishing = false;
    _isTapTriggered = false;
    _velocityY = 0;
    _setState(CatState.walk);
  }

  final bool fullBehavior;
  final bool Function(CatComponent cat) onDrop;
  final void Function(CatComponent cat) onDelivered;
  final void Function(CatComponent cat) onEscaped;
  final _random = Random();

  CatState _state = CatState.idle;
  double _actionTimer = 0;
  double _currentActionDuration = 0;
  int _direction = 1;
  double _velocityY = 0;
  bool _isDragged = false;
  bool _isTapTriggered = false;
  bool _isDropWrong = false;
  bool _isDelivered = false;
  bool _isEscaping = false;
  Vector2 _dragStartPosition = Vector2.zero();

  bool _isVanishing = false;
  bool _hasTeleported = false;
  static const double _vanishTeleportDistance = 200.0;

  @override
  void render(Canvas canvas) {
    if (catchWindow.canCatch || _isDragged) {
      final fraction = _isDragged ? catchWindow.grip / 3 : catchWindow.ready;
      canvas.drawRect(Rect.fromLTWH(8, 0, size.x - 16, 6),
          Paint()..color = const Color(0xAA34221A));
      canvas.drawRect(
          Rect.fromLTWH(8, 0, (size.x - 16) * fraction, 6),
          Paint()
            ..color =
                _isDragged ? const Color(0xFFFFB52A) : const Color(0xFF74FF97));
      canvas.drawOval(Rect.fromLTWH(6, size.y * .8, size.x - 12, 12),
          Paint()..color = const Color(0x8874FF97));
    }
    final needsSmallerArtwork = ((catType == 'himalaya' ||
                catType == 'calico') &&
            (current == CatState.dashEscape || current == CatState.vanish)) ||
        (catType == 'scottish' &&
            (current == CatState.run ||
                current == CatState.dashEscape ||
                current == CatState.vanish)) ||
        (catType == 'orange' &&
            (current == CatState.run || current == CatState.walk));
    if (!needsSmallerArtwork) {
      super.render(canvas);
      return;
    }
    // Scale only the artwork around its feet; keep the drag bounds unchanged.
    const factor = 0.8;
    canvas.save();
    canvas.translate(size.x * (1 - factor) / 2, size.y * 0.82 * (1 - factor));
    canvas.scale(factor);
    super.render(canvas);
    canvas.restore();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animations = await loadCatAnimations(gameRef.images, catType);
    _direction = _random.nextBool() ? 1 : -1;
    _applyFlip();
    _pickNextAction();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!isPlaying() || catchWindow.canCatch) return;
    if (_isDragged || _isDropWrong || _isDelivered || _isEscaping) return;
    _dodge();
  }

  void _dodge() {
    fishTarget = null;
    catchWindow.clear();
    _isTapTriggered = false;
    _isVanishing = false;
    _hasTeleported = false;
    _dodgeTime = 0.7;
    _actionTimer = 0;
    _setState(CatState.dashEscape);
    _direction *= -1;
    _applyFlip();
    _velocityY = 0;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!isPlaying() || _isDropWrong || _isDelivered) return;
    if (!catchWindow.grab()) {
      if (_dodgeTime <= 0) _dodge();
      return;
    }
    fishTarget = null;
    _isDragged = true;
    _isTapTriggered = false;
    _isEscaping = false;
    _isVanishing = false;
    _hasTeleported = false;
    _dragStartPosition = position.clone();
    _setState(CatState.dragged);
    _velocityY = 0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_isDragged) position += event.canvasDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _finishDrop();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (_isDragged) {
      _isDragged = false;
      position = _dragStartPosition.clone();
      _dodge();
    }
  }

  void _finishDrop() {
    if (!_isDragged) return;
    _isDragged = false;
    catchWindow.clear();
    if (!isPlaying()) return;
    if (onDrop(this)) {
      _isDelivered = true;
      _setState(CatState.dropSuccess);
      _actionTimer = 0;
      _currentActionDuration = framesDropSuccess * animationStepTime;
      return;
    }

    _isDropWrong = true;
    _setState(CatState.dropWrong);
    _actionTimer = 0;
    _currentActionDuration = framesDropWrong * animationStepTime;
  }

  @override
  void update(double dt) {
    if (!isPlaying()) return;
    super.update(dt);
    final wasReady = catchWindow.canCatch;
    catchWindow.tick(dt);
    if (_isDragged) {
      if (catchWindow.grip <= 0) {
        _isDragged = false;
        _clampPosition();
        _dodge();
      }
      return;
    }
    if (wasReady) {
      if (!catchWindow.canCatch) _dodge();
      return;
    }
    if (_dodgeTime > 0) {
      _dodgeTime -= dt;
      _move(dt, catDashSpeed);
      _clampPosition();
      if (_dodgeTime <= 0) _pickNextAction();
      return;
    }
    final target = fishTarget;
    if (target != null) {
      final delta = target - (position + size / 2);
      final distance = delta.length;
      if (distance <= catWalkSpeed * dt + 4) {
        fishTarget = null;
        catchWindow.open();
        _setState(CatState.idle);
      } else {
        _direction = delta.x >= 0 ? 1 : -1;
        _applyFlip();
        position += delta / distance * catWalkSpeed * dt;
      }
      return;
    }

    _actionTimer += dt;

    if (_isDelivered) {
      if (_state == CatState.dropSuccess &&
          _actionTimer >= _currentActionDuration) {
        _setState(CatState.celebrate);
        _actionTimer = 0;
        _currentActionDuration = framesCelebrate * animationStepTime;
      } else if (_state == CatState.celebrate &&
          _actionTimer >= _currentActionDuration) {
        onDelivered(this);
        removeFromParent();
      }
      return;
    }

    if (_isDropWrong) {
      if (_actionTimer >= _currentActionDuration) {
        position = _dragStartPosition;
        _isDropWrong = false;
        _pickNextAction();
      }
      return;
    }

    if (_isEscaping) {
      position.x += _direction * catDashSpeed * 1.35 * dt;
      final hasLeftScreen = (_direction < 0 && position.x + size.x < 0) ||
          (_direction > 0 && position.x > gameRef.size.x);
      if (hasLeftScreen) {
        onEscaped(this);
        removeFromParent();
      }
      return;
    }

    if (_isVanishing) {
      final elapsedFrames = (_actionTimer / vanishStepTime).floor();
      if (!_hasTeleported && elapsedFrames >= 3) {
        _hasTeleported = true;
        _teleport();
      }
      if (_actionTimer >= _currentActionDuration) {
        _isVanishing = false;
        _hasTeleported = false;
        _pickNextAction();
      }
      return;
    }

    if (_isTapTriggered) {
      if (_actionTimer >= _currentActionDuration) {
        _isTapTriggered = false;
        _startEscape();
      }
      return;
    }

    switch (_state) {
      case CatState.walk:
        _move(dt, catWalkSpeed);
      case CatState.run:
      case CatState.panic:
        _move(dt, catRunSpeed);
      case CatState.dashEscape:
        _move(dt, catDashSpeed);
      case CatState.idle:
      case CatState.turnAround:
      case CatState.dragged:
      case CatState.dropSuccess:
      case CatState.celebrate:
      case CatState.dropWrong:
      case CatState.vanish:
        break;
    }

    _clampPosition();
    if (_actionTimer >= _currentActionDuration) _pickNextAction();
  }

  void _move(double dt, double speed) {
    position.x += _direction * speed * dt;
    position.y += _velocityY * dt;
  }

  void _clampPosition() {
    final gameSize = gameRef.size;
    if (position.x <= 0) {
      position.x = 0;
      _direction = 1;
      _applyFlip();
    } else if (position.x >= gameSize.x - size.x) {
      position.x = gameSize.x - size.x;
      _direction = -1;
      _applyFlip();
    }
    position.y = position.y.clamp(gameSize.y * 0.15, gameSize.y - size.y - 10);
  }

  void _pickNextAction() {
    _actionTimer = 0;
    final roll = _random.nextDouble();
    if (fullBehavior && roll >= 0.68) {
      _velocityY = 0;
      if (roll < 0.78) {
        _setState(CatState.turnAround);
        _direction *= -1;
        _applyFlip();
        _currentActionDuration = framesTurnAround * animationStepTime;
      } else if (roll < 0.86) {
        _setState(CatState.dashEscape);
        _currentActionDuration = framesDashEscape * animationStepTime;
      } else if (roll < 0.93) {
        _setState(CatState.panic);
        _currentActionDuration = framesPanic * animationStepTime;
      } else {
        _isVanishing = true;
        _hasTeleported = false;
        _setState(CatState.vanish);
        _currentActionDuration = framesVanish * vanishStepTime;
      }
      return;
    }
    if (roll < 0.3) {
      _setState(CatState.idle);
      _currentActionDuration = _randomBetween(minIdleTime, maxIdleTime);
      _velocityY = 0;
    } else if (roll < 0.58) {
      _setState(CatState.walk);
      _currentActionDuration = _randomBetween(minActionTime, maxActionTime);
      _velocityY = _random.nextDouble() * 30 - 15;
    } else {
      _startRun();
    }
    _maybeChangeDirection(0.35);
  }

  void _startRun() {
    _setState(CatState.run);
    _actionTimer = 0;
    _currentActionDuration = _randomBetween(0.8, 2.0);
    _velocityY = _random.nextDouble() * 50 - 25;
    _maybeChangeDirection(0.4);
  }

  void _setState(CatState newState) {
    _state = newState;
    current = newState;
    animationTicker?.reset();
  }

  void _maybeChangeDirection(double probability) {
    if (_random.nextDouble() < probability) {
      _direction *= -1;
      _applyFlip();
    }
  }

  void _applyFlip() {
    final shouldFlip = _direction == -1;
    if (shouldFlip != (scale.x < 0)) flipHorizontallyAroundCenter();
  }

  /// A tapped cat panics first, then dashes toward the nearest edge.
  void _startEscape() {
    _isEscaping = true;
    _velocityY = 0;
    _direction = position.x + size.x / 2 < gameRef.size.x / 2 ? -1 : 1;
    _applyFlip();
    _setState(CatState.dashEscape);
  }

  void _teleport() {
    final dx = (_random.nextDouble() * 2 - 1) * _vanishTeleportDistance;
    final dy = (_random.nextDouble() * 2 - 1) * _vanishTeleportDistance * 0.5;
    position += Vector2(dx, dy);
    _clampPosition();
    if (dx != 0) {
      _direction = dx > 0 ? 1 : -1;
      _applyFlip();
    }
  }

  double _randomBetween(double min, double max) =>
      min + _random.nextDouble() * (max - min);
}
