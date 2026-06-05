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
}

class OrangeCat extends SpriteAnimationGroupComponent<CatState>
    with HasGameRef<FlameGame>, DragCallbacks, TapCallbacks {
  OrangeCat({required Vector2 position})
      : super(
          position: position,
          size: Vector2(catWidth, catHeight),
          current: CatState.idle,
        );

  final _random = Random();

  CatState _state = CatState.idle;
  double _actionTimer = 0;
  double _currentActionDuration = 0;

  /// Hướng di chuyển: 1 = phải, -1 = trái
  int _direction = 1;

  /// Velocity Y hiện tại
  double _velocityY = 0;

  /// Đang bị kéo?
  bool _isDragged = false;

  /// Đang trong trạng thái bị chạm (panic → run)?
  bool _isTapTriggered = false;

  /// Đang chơi animation drop wrong?
  bool _isDropWrong = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    animations = {
      CatState.idle: await _loadAnimation('cat-orange-idle.png', framesIdle),
      CatState.walk: await _loadAnimation('cat-orange-walk.png', framesWalk),
      CatState.run: await _loadAnimation('cat-orange-run.png', framesRun),
      CatState.turnAround:
          await _loadAnimation('cat-orange-turn-around.png', framesTurnAround),
      CatState.dashEscape:
          await _loadAnimation('cat-orange-dash-escape.png', framesDashEscape),
      CatState.panic:
          await _loadAnimation('cat-orange-panic.png', framesPanic),
      CatState.dragged:
          await _loadAnimation('cat-orange-dragged.png', framesDragged),
      CatState.dropWrong:
          await _loadAnimation('cat-orange-drop-wrong.png', framesDropWrong),
    };

    current = CatState.idle;
    _direction = _random.nextBool() ? 1 : -1;
    _applyFlip();
    _pickNextAction();
  }

  /// Load sprite sheet ngang (1 row, N columns)
  /// Mỗi frame cố định 256x256
  Future<SpriteAnimation> _loadAnimation(
      String fileName, int frameCount) async {
    final image = await gameRef.images.load('Cat/$fileName');

    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: animationStepTime,
        textureSize: Vector2(256, 256),
      ),
    );
  }

  // --- TAP: chạm 1 cái → panic rồi run ---

  @override
  void onTapDown(TapDownEvent event) {
    if (_isDragged || _isDropWrong) return;
    _isTapTriggered = true;
    _actionTimer = 0;
    _setState(CatState.panic);
    _currentActionDuration = 0.5; // panic ngắn
    _velocityY = 0;
  }

  // --- DRAG: bấm giữ kéo → dragged ---

  /// Vị trí Y trước khi bị bắt lên
  double _originalY = 0;

  @override
  void onDragStart(DragStartEvent event) {
    if (_isDropWrong) return;
    _isDragged = true;
    _isTapTriggered = false;
    _originalY = position.y; // Ghi nhớ vị trí trước khi kéo
    _setState(CatState.dragged);
    _velocityY = 0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragged) return;
    position += event.canvasDelta;
  }

  /// Đang rơi xuống đất sau khi thả?
  bool _isFalling = false;

  /// Tốc độ rơi hiện tại
  double _fallSpeed = 0;

  /// Gia tốc rơi (trọng lực)
  static const double _gravity = 800.0;

  /// Vị trí đất (sẽ tính theo game size)
  double get _groundY => gameRef.size.y - size.y - 10;

  @override
  void onDragEnd(DragEndEvent event) {
    if (!_isDragged) return;
    _isDragged = false;
    // Nếu đang thấp hơn hoặc bằng vị trí cũ → không rơi, dropWrong luôn
    if (position.y >= _originalY) {
      _isDropWrong = true;
      _setState(CatState.dropWrong);
      _actionTimer = 0;
      _currentActionDuration = framesDropWrong * animationStepTime;
    } else {
      // Cao hơn vị trí cũ → rơi xuống
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

    // Nếu đang bị kéo → không update logic
    if (_isDragged) return;

    // Đang rơi xuống vị trí cũ (vẫn animation dragged)
    if (_isFalling) {
      _fallSpeed += _gravity * dt;
      position.y += _fallSpeed * dt;

      // Chạm vị trí cũ
      if (position.y >= _originalY) {
        position.y = _originalY;
        _isFalling = false;
        _fallSpeed = 0;
        // Chạm đất → chuyển sang dropWrong
        _isDropWrong = true;
        _setState(CatState.dropWrong);
        _actionTimer = 0;
        _currentActionDuration = framesDropWrong * animationStepTime;
      }
      return;
    }

    _actionTimer += dt;

    // Nếu đang drop wrong, chờ hết animation rồi quay lại tự do
    if (_isDropWrong) {
      if (_actionTimer >= _currentActionDuration) {
        _isDropWrong = false;
        _pickNextAction();
      }
      return;
    }

    // Nếu đang tap-triggered panic → hết thời gian thì chuyển sang run
    if (_isTapTriggered) {
      if (_actionTimer >= _currentActionDuration) {
        _isTapTriggered = false;
        // Chạy trốn sau khi panic
        _setState(CatState.run);
        _actionTimer = 0;
        _currentActionDuration = _randomBetween(1.0, 2.5);
        _maybeChangeDirection(0.5);
        _velocityY = _random.nextDouble() * 50 - 25;
      }
      return;
    }

    // Logic tự do bình thường
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

  /// Chọn hành động tiếp theo ngẫu nhiên
  void _pickNextAction() {
    _actionTimer = 0;

    final roll = _random.nextDouble();

    if (roll < 0.30) {
      _setState(CatState.idle);
      _currentActionDuration = _randomBetween(minIdleTime, maxIdleTime);
      _velocityY = 0;
    } else if (roll < 0.55) {
      _setState(CatState.walk);
      _currentActionDuration = _randomBetween(minActionTime, maxActionTime);
      _maybeChangeDirection(0.3);
      _velocityY = _random.nextDouble() * 30 - 15;
    } else if (roll < 0.75) {
      _setState(CatState.run);
      _currentActionDuration = _randomBetween(0.8, 2.0);
      _maybeChangeDirection(0.4);
      _velocityY = _random.nextDouble() * 50 - 25;
    } else if (roll < 0.85) {
      _setState(CatState.turnAround);
      _currentActionDuration = _randomBetween(0.3, 0.6);
      _direction *= -1;
      _applyFlip();
      _velocityY = 0;
    } else if (roll < 0.93) {
      _setState(CatState.dashEscape);
      _currentActionDuration = _randomBetween(0.5, 1.2);
      _maybeChangeDirection(0.5);
      _velocityY = _random.nextDouble() * 60 - 30;
    } else {
      _setState(CatState.panic);
      _currentActionDuration = _randomBetween(0.6, 1.5);
      _maybeChangeDirection(0.6);
      _velocityY = _random.nextDouble() * 80 - 40;
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

  double _randomBetween(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
}
