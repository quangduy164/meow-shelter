import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../constants.dart';

/// Trạng thái hành vi mèo
enum CatState {
  idle,
  walk,
  run,
  turnAround,
  dashEscape,
  panic,
  dragged,
  dropWrong,
  vanish,
}

/// Component mèo dùng chung — truyền [catType] để đổi sprite folder.
/// Ví dụ: catType = 'orange' → load từ 'Cat/Orange/cat-orange-idle.png'
///         catType = 'himalaya' → load từ 'Cat/Himalaya/cat-himalaya-idle.png'
class CatComponent extends SpriteAnimationGroupComponent<CatState>
    with HasGameRef<FlameGame>, DragCallbacks, TapCallbacks {
  CatComponent({required Vector2 position, required this.catType})
      : _folder = 'Cat/${catType[0].toUpperCase()}${catType.substring(1)}',
        super(
          position: position,
          size: Vector2(catWidth, catHeight),
          current: CatState.idle,
        );

  final String catType;
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
  bool _isFalling = false;
  double _fallSpeed = 0;
  double _originalY = 0;

  /// Đang trong trạng thái vanish?
  bool _isVanishing = false;

  /// Đã teleport chưa (frame 4)?
  bool _hasTeleported = false;

  static const double _gravity = 800.0;

  /// Khoảng cách dịch chuyển khi vanish
  static const double _vanishTeleportDistance = 200.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    animations = {
      CatState.idle:
          await _loadAnimation('cat-$catType-idle.png', framesIdle),
      CatState.walk:
          await _loadAnimation('cat-$catType-walk.png', framesWalk),
      CatState.run:
          await _loadAnimation('cat-$catType-run.png', framesRun),
      CatState.turnAround:
          await _loadAnimation('cat-$catType-turn-around.png', framesTurnAround),
      CatState.dashEscape:
          await _loadAnimation('cat-$catType-dash-escape.png', framesDashEscape),
      CatState.panic:
          await _loadAnimation('cat-$catType-panic.png', framesPanic),
      CatState.dragged:
          await _loadAnimation('cat-$catType-dragged.png', framesDragged),
      CatState.dropWrong:
          await _loadAnimation('cat-$catType-drop-wrong.png', framesDropWrong),
      CatState.vanish:
          await _loadVanishAnimation('cat-$catType-vanish.png', framesVanish),
    };

    current = CatState.idle;
    _direction = _random.nextBool() ? 1 : -1;
    _applyFlip();
    _pickNextAction();
  }

  Future<SpriteAnimation> _loadAnimation(
      String fileName, int frameCount) async {
    final image = await gameRef.images.load('$_folder/$fileName');
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: animationStepTime,
        textureSize: Vector2(256, 256),
      ),
    );
  }

  Future<SpriteAnimation> _loadVanishAnimation(
      String fileName, int frameCount) async {
    final image = await gameRef.images.load('$_folder/$fileName');
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: vanishStepTime,
        textureSize: Vector2(256, 256),
      ),
    );
  }

  // --- TAP ---

  @override
  void onTapDown(TapDownEvent event) {
    if (_isDragged || _isDropWrong) return;
    _isTapTriggered = true;
    _actionTimer = 0;
    _setState(CatState.panic);
    _currentActionDuration = 0.5;
    _velocityY = 0;
  }

  // --- DRAG ---

  @override
  void onDragStart(DragStartEvent event) {
    if (_isDropWrong) return;
    _isDragged = true;
    _isTapTriggered = false;
    _originalY = position.y;
    _setState(CatState.dragged);
    _velocityY = 0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragged) return;
    position += event.canvasDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!_isDragged) return;
    _isDragged = false;
    if (position.y >= _originalY) {
      _isDropWrong = true;
      _setState(CatState.dropWrong);
      _actionTimer = 0;
      _currentActionDuration = framesDropWrong * animationStepTime;
    } else {
      _isFalling = true;
      _fallSpeed = 0;
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (!_isDragged) return;
    _isDragged = false;
    if (position.y >= _originalY) {
      _isDropWrong = true;
      _setState(CatState.dropWrong);
      _actionTimer = 0;
      _currentActionDuration = framesDropWrong * animationStepTime;
    } else {
      _isFalling = true;
      _fallSpeed = 0;
    }
  }

  // --- UPDATE ---

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDragged) return;

    if (_isFalling) {
      _fallSpeed += _gravity * dt;
      position.y += _fallSpeed * dt;
      if (position.y >= _originalY) {
        position.y = _originalY;
        _isFalling = false;
        _fallSpeed = 0;
        _isDropWrong = true;
        _setState(CatState.dropWrong);
        _actionTimer = 0;
        _currentActionDuration = framesDropWrong * animationStepTime;
      }
      return;
    }

    _actionTimer += dt;

    if (_isDropWrong) {
      if (_actionTimer >= _currentActionDuration) {
        _isDropWrong = false;
        _pickNextAction();
      }
      return;
    }

    // Vanish: frame 4 (index 3) → teleport, frame 6 kết thúc
    if (_isVanishing) {
      final elapsedFrames = (_actionTimer / vanishStepTime).floor();
      // Tới frame 4 (index 3) → teleport
      if (!_hasTeleported && elapsedFrames >= 3) {
        _hasTeleported = true;
        _teleport();
      }
      // Hết animation → quay lại bình thường
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
        _setState(CatState.run);
        _actionTimer = 0;
        _currentActionDuration = _randomBetween(1.0, 2.5);
        _maybeChangeDirection(0.5);
        _velocityY = _random.nextDouble() * 50 - 25;
      }
      return;
    }

    switch (_state) {
      case CatState.idle:
        break;
      case CatState.walk:
        _move(dt, catWalkSpeed);
        break;
      case CatState.run:
        _move(dt, catRunSpeed);
        break;
      case CatState.dashEscape:
        _move(dt, catDashSpeed);
        break;
      case CatState.turnAround:
        break;
      case CatState.panic:
        _move(dt, catRunSpeed * 1.2);
        break;
      case CatState.dragged:
      case CatState.dropWrong:
      case CatState.vanish:
        break;
    }

    _clampPosition();

    if (_actionTimer >= _currentActionDuration) {
      _pickNextAction();
    }
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
    final minY = gameSize.y * 0.15;
    final maxY = gameSize.y - size.y - 10;
    position.y = position.y.clamp(minY, maxY);
  }

  void _pickNextAction() {
    _actionTimer = 0;
    final roll = _random.nextDouble();

    if (roll < 0.28) {
      _setState(CatState.idle);
      _currentActionDuration = _randomBetween(minIdleTime, maxIdleTime);
      _velocityY = 0;
    } else if (roll < 0.50) {
      _setState(CatState.walk);
      _currentActionDuration = _randomBetween(minActionTime, maxActionTime);
      _maybeChangeDirection(0.3);
      _velocityY = _random.nextDouble() * 30 - 15;
    } else if (roll < 0.68) {
      _setState(CatState.run);
      _currentActionDuration = _randomBetween(0.8, 2.0);
      _maybeChangeDirection(0.4);
      _velocityY = _random.nextDouble() * 50 - 25;
    } else if (roll < 0.78) {
      _setState(CatState.turnAround);
      _currentActionDuration = _randomBetween(0.3, 0.6);
      _direction *= -1;
      _applyFlip();
      _velocityY = 0;
    } else if (roll < 0.86) {
      _setState(CatState.dashEscape);
      _currentActionDuration = _randomBetween(0.5, 1.2);
      _maybeChangeDirection(0.5);
      _velocityY = _random.nextDouble() * 60 - 30;
    } else if (roll < 0.93) {
      _setState(CatState.panic);
      _currentActionDuration = _randomBetween(0.6, 1.5);
      _maybeChangeDirection(0.6);
      _velocityY = _random.nextDouble() * 80 - 40;
    } else {
      // Vanish (tốc biến)
      _isVanishing = true;
      _hasTeleported = false;
      _setState(CatState.vanish);
      _currentActionDuration = framesVanish * vanishStepTime;
      _velocityY = 0;
    }
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
    final currentlyFlipped = scale.x < 0;
    if (shouldFlip != currentlyFlipped) {
      flipHorizontallyAroundCenter();
    }
  }

  /// Dịch chuyển tức thời khi vanish (frame 4)
  void _teleport() {
    final gameSize = gameRef.size;
    // Random hướng dịch chuyển
    final dx = (_random.nextDouble() * 2 - 1) * _vanishTeleportDistance;
    final dy = (_random.nextDouble() * 2 - 1) * _vanishTeleportDistance * 0.5;

    position.x += dx;
    position.y += dy;

    // Clamp trong bounds
    final minY = gameSize.y * 0.15;
    final maxY = gameSize.y - size.y - 10;
    position.x = position.x.clamp(0, gameSize.x - size.x);
    position.y = position.y.clamp(minY, maxY);
  }

  double _randomBetween(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
}
