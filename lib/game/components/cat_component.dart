import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../constants.dart';

enum CatState {
  idle,
  walk,
  run,
  turnAround,
  dashEscape,
  panic,
  dragged,
  dropSuccess,
  celebrate,
  dropWrong,
  vanish,
}

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
  })  : _folder = 'Cat/${catType[0].toUpperCase()}${catType.substring(1)}',
        super(
          position: position,
          size: Vector2(catWidth, catHeight),
          current: CatState.idle,
        );

  final String catType;
  final bool Function(CatComponent cat) onDrop;
  final void Function(CatComponent cat) onDelivered;
  final void Function(CatComponent cat) onEscaped;
  final String _folder;
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
  Future<void> onLoad() async {
    await super.onLoad();
    animations = {
      CatState.idle: await _loadAnimation('cat-$catType-idle.png', framesIdle),
      CatState.walk: await _loadAnimation('cat-$catType-walk.png', framesWalk),
      CatState.run: await _loadAnimation('cat-$catType-run.png', framesRun),
      CatState.turnAround: await _loadAnimation(
        'cat-$catType-turn-around.png',
        framesTurnAround,
      ),
      CatState.dashEscape: await _loadAnimation(
        'cat-$catType-dash-escape.png',
        framesDashEscape,
      ),
      CatState.panic: await _loadAnimation('cat-$catType-panic.png', framesPanic),
      CatState.dragged: await _loadAnimation(
        'cat-$catType-dragged.png',
        framesDragged,
      ),
      CatState.dropSuccess: await _loadAnimation(
        'cat-$catType-drop-success.png',
        framesDropSuccess,
      ),
      CatState.celebrate: await _loadAnimation(
        'cat-$catType-celebrate.png',
        framesCelebrate,
      ),
      CatState.dropWrong: await _loadAnimation(
        'cat-$catType-drop-wrong.png',
        framesDropWrong,
      ),
      CatState.vanish: await _loadAnimation(
        'cat-$catType-vanish.png',
        framesVanish,
        stepTime: vanishStepTime,
      ),
    };
    _direction = _random.nextBool() ? 1 : -1;
    _applyFlip();
    _pickNextAction();
  }

  Future<SpriteAnimation> _loadAnimation(
    String fileName,
    int frameCount, {
    double stepTime = animationStepTime,
  }) async {
    final image = await gameRef.images.load('$_folder/$fileName');
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: stepTime,
        textureSize: Vector2(256, 256),
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (_isDragged || _isDropWrong || _isDelivered || _isEscaping) return;
    _isTapTriggered = true;
    _actionTimer = 0;
    _setState(CatState.panic);
    _currentActionDuration = 0.45;
    _velocityY = 0;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_isDropWrong || _isDelivered) return;
    _isDragged = true;
    _isTapTriggered = false;
    _isEscaping = false;
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
    _finishDrop();
  }

  void _finishDrop() {
    if (!_isDragged) return;
    _isDragged = false;
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
    super.update(dt);
    if (_isDragged) return;

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
      final hasLeftScreen =
          (_direction < 0 && position.x + size.x < 0) ||
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
