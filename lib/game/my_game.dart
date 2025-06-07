// lib/game/my_game.dart
import 'dart:math' as math; // math.Random, math.cos, math.sin 사용
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'components/player_component.dart';
import 'components/enemy_component.dart';
import 'package:flame/palette.dart';
import 'components/crystal_component.dart';
import 'components/tornado_component.dart';

class MyGame extends FlameGame with HasCollisionDetection, ChangeNotifier {
  late final PlayerComponent player;
  late final JoystickComponent joystick;

  final double playerSpeed = 200.0;

  final Paint gridPaint = Paint()
    ..color = Colors.white.withOpacity(0.1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final double gridSize = 50.0;

  bool _isGameOver = false;
  int _currentLevel = 1;
  double _currentExp = 0.0;
  double _expToNextLevel = 100.0;
  double _totalElapsedTimeSeconds = 0.0;

  bool hasFeatherOfBuyo = false;

  // 스폰 관련 변수
  final math.Random _random = math.Random();

  // 크리스탈 스폰
  final double crystalSpawnInterval = 5.0; // 5초마다 크리스탈 스폰 시도
  double _crystalSpawnTimer = 0.0;
  final int maxCrystalsOnField = 10; // 필드 위 최대 크리스탈 수
  final double crystalSpawnMinRadiusFromPlayer = 200.0; // 플레이어로부터 최소 스폰 거리
  final double crystalSpawnMaxRadiusFromPlayer = 500.0; // 플레이어로부터 최대 스폰 거리

  // 적 스폰
  final double enemySpawnInterval = 3.0; // 3초마다 적 스폰 시도
  double _enemySpawnTimer = 0.0;
  final int maxEnemiesOnField = 15; // 필드 위 최대 적 수
  final double enemySpawnMinRadiusFromPlayer = 300.0; // 플레이어로부터 최소 스폰 거리 (화면 밖에 스폰되도록)
  final double enemySpawnMaxRadiusFromPlayer = 600.0; // 플레이어로부터 최대 스폰 거리


  // Getter들 ... (이전과 동일)
  bool get isGameOver => _isGameOver;
  int get currentLevel => _currentLevel;
  double get expBarPercentage {
    if (_expToNextLevel <= 0) return 1.0;
    return (_currentExp / _expToNextLevel).clamp(0.0, 1.0);
  }
  String get formattedElapsedTime {
    final duration = Duration(seconds: _totalElapsedTimeSeconds.toInt());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  double get totalElapsedTimeSeconds => _totalElapsedTimeSeconds; // getter 추가
  double get expToNextLevel => _expToNextLevel; // getter 추가


  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _isGameOver = false;
    _currentLevel = 1;
    _currentExp = 0.0;
    _expToNextLevel = 100.0;
    _totalElapsedTimeSeconds = 0.0;
    hasFeatherOfBuyo = false;
    _crystalSpawnTimer = crystalSpawnInterval; // 첫 스폰까지 시간 부여
    _enemySpawnTimer = enemySpawnInterval;   // 첫 스폰까지 시간 부여

    player = PlayerComponent(position: Vector2.zero(), radius: 25.0);
    player.onHealthChanged = notifyListeners;
    player.onDeath = onPlayerDeath;
    world.add(player);

    // 초기 적 및 크리스탈 제거 (이제 update에서 스폰)
    // final enemy1 = EnemyComponent(position: Vector2(200, 100), damageToPlayer: 10.0, health: 30.0, expDropAmount: 20.0);
    // final enemy2 = EnemyComponent(position: Vector2(-150, -50), size: Vector2.all(30.0), damageToPlayer: 5.0, health: 30.0, expDropAmount: 15.0);
    // world.add(enemy1);
    // world.add(enemy2);

    // final crystal1 = CrystalComponent(position: Vector2(100, -100), expValue: 10.0);
    // final crystal2 = CrystalComponent(position: Vector2(-50, 150), radius: 10.0, expValue: 5.0);
    // world.add(crystal1);
    // world.add(crystal2);

    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25.0, paint: knobPaint),
      background: CircleComponent(radius: 60.0, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    camera.viewport.add(joystick);

    debugMode = true;
    camera.follow(player);

    overlays.add('HudOverlay');
    notifyListeners();
  }

  void _spawnCrystal() {
    // 현재 필드 위 크리스탈 수 확인
    if (world.children.whereType<CrystalComponent>().length >= maxCrystalsOnField) {
      return;
    }

    final angle = _random.nextDouble() * 2 * math.pi;
    final radius = crystalSpawnMinRadiusFromPlayer +
        _random.nextDouble() * (crystalSpawnMaxRadiusFromPlayer - crystalSpawnMinRadiusFromPlayer);

    final spawnPosition = player.position + Vector2(math.cos(angle) * radius, math.sin(angle) * radius);

    // 크리스탈 경험치 값 랜덤 설정 (예시)
    final expValue = 5.0 + _random.nextInt(11); // 5 ~ 15
    final crystal = CrystalComponent(position: spawnPosition, expValue: expValue);
    world.add(crystal);
    if (kDebugMode) {
      print("크리스탈 스폰: $spawnPosition, EXP: $expValue");
    }
  }

  void _spawnEnemy() {
    if (world.children.whereType<EnemyComponent>().length >= maxEnemiesOnField) {
      return;
    }

    final angle = _random.nextDouble() * 2 * math.pi;
    // 적은 주로 화면 가장자리 또는 약간 밖에서 스폰되도록 합니다.
    final radius = enemySpawnMinRadiusFromPlayer +
        _random.nextDouble() * (enemySpawnMaxRadiusFromPlayer - enemySpawnMinRadiusFromPlayer);

    final spawnPosition = player.position + Vector2(math.cos(angle) * radius, math.sin(angle) * radius);

    // 적 스탯 랜덤화 또는 레벨에 따른 강화 (예시)
    final health = 20.0 + _currentLevel * 5;
    final damage = 5.0 + _currentLevel * 1;
    final expDrop = 10.0 + _currentLevel * 3;

    final enemy = EnemyComponent(
      position: spawnPosition,
      health: health,
      damageToPlayer: damage,
      expDropAmount: expDrop,
    );
    world.add(enemy);
    if (kDebugMode) {
      print("적 스폰: $spawnPosition, HP: $health");
    }
  }


  @override
  void update(double dt) {
    super.update(dt);

    if (_isGameOver) {
      return;
    }

    final previousTimeInt = _totalElapsedTimeSeconds.toInt();
    _totalElapsedTimeSeconds += dt;
    if (_totalElapsedTimeSeconds.toInt() != previousTimeInt) {
      notifyListeners();
    }

    // 크리스탈 스폰 로직
    _crystalSpawnTimer -= dt;
    if (_crystalSpawnTimer <= 0) {
      _spawnCrystal();
      _crystalSpawnTimer = crystalSpawnInterval; // 타이머 초기화
    }

    // 적 스폰 로직
    _enemySpawnTimer -= dt;
    if (_enemySpawnTimer <= 0) {
      _spawnEnemy();
      _enemySpawnTimer = enemySpawnInterval; // 타이머 초기화
    }


    if (!player.isDead && joystick.direction != JoystickDirection.idle) {
      if (!joystick.delta.isZero()) {
        player.position.add(joystick.relativeDelta * playerSpeed * dt);
      }
    }
  }

  // ... (addExperience, levelUp, render, onPlayerDeath는 이전과 동일) ...
  void addExperience(double amount) {
    if (_isGameOver) return;
    _currentExp += amount;
    if (kDebugMode) {
      print("경험치 획득: +$amount. 현재 EXP: $_currentExp / $_expToNextLevel");
    }
    if (_currentExp >= _expToNextLevel) {
      levelUp();
    }
    notifyListeners();
  }

  void levelUp() {
    _currentLevel++;
    _currentExp -= _expToNextLevel;
    _expToNextLevel *= 1.2;
    if (kDebugMode) {
      print("레벨 업! 현재 레벨: $_currentLevel. 다음 레벨까지 EXP: $_expToNextLevel");
    }

    if (_currentLevel >= 2 && !hasFeatherOfBuyo) {
      hasFeatherOfBuyo = true;
      if (kDebugMode) {
        print("부요의 깃털 획득!");
      }
    }
    notifyListeners();
    if (_currentExp >= _expToNextLevel) {
      levelUp();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final Rect visibleWorldRect = camera.visibleWorldRect;
    final double camWorldX = camera.viewfinder.position.x;
    final double camWorldY = camera.viewfinder.position.y;
    final Vector2 gameScreenSize = size;
    double startGridWorldX = (visibleWorldRect.left / gridSize).floor() * gridSize;
    for (double worldX = startGridWorldX; worldX <= visibleWorldRect.right; worldX += gridSize) {
      final double screenX = worldX - camWorldX + gameScreenSize.x / 2;
      if (screenX >= 0 && screenX <= gameScreenSize.x) {
        canvas.drawLine(Offset(screenX, 0), Offset(screenX, gameScreenSize.y), gridPaint);
      }
    }
    double startGridWorldY = (visibleWorldRect.top / gridSize).floor() * gridSize;
    for (double worldY = startGridWorldY; worldY <= visibleWorldRect.bottom; worldY += gridSize) {
      final double screenY = worldY - camWorldY + gameScreenSize.y / 2;
      if (screenY >= 0 && screenY <= gameScreenSize.y) {
        canvas.drawLine(Offset(0, screenY), Offset(gameScreenSize.x, screenY), gridPaint);
      }
    }
  }

  void onPlayerDeath() {
    if (_isGameOver) return;
    _isGameOver = true;
    if (joystick.isMounted) {
      joystick.removeFromParent();
    }
    overlays.add('GameOverOverlay');
    notifyListeners();
  }
}