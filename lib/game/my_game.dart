// lib/game/my_game.dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/player_component.dart';
import 'package:flame/palette.dart';
import 'managers/level_manager.dart';
import 'managers/spawn_manager.dart';
import 'weapons/weapon_definitions.dart';
import 'upgrades/upgrade_data.dart';

class MyGame extends FlameGame with HasCollisionDetection, ChangeNotifier {
  late final PlayerComponent player;
  late final JoystickComponent joystick;
  late final LevelManager levelManager;
  late final SpawnManager spawnManager;

  final double playerSpeed = 200.0;
  final Paint gridPaint = Paint()
    ..color = Colors.white.withOpacity(0.1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final double gridSize = 50.0;

  bool _isGameOver = false;

  double _totalElapsedTimeSeconds = 0.0;
  final double crystalSpawnInterval = 5.0;
  double _crystalSpawnTimer = 0.0;
  final int maxCrystalsOnField = 10;
  final double crystalSpawnMinRadiusFromPlayer = 200.0;
  final double crystalSpawnMaxRadiusFromPlayer = 500.0;
  final double enemySpawnInterval = 3.0;
  double _enemySpawnTimer = 0.0;
  final int maxEnemiesOnField = 15;
  final double enemySpawnMinRadiusFromPlayer = 300.0;
  final double enemySpawnMaxRadiusFromPlayer = 600.0;

  bool get isGameOver => _isGameOver;
  int get currentLevel => levelManager.currentLevel;
  double get expToNextLevel => levelManager.expToNextLevel;
  double get totalElapsedTimeSeconds => _totalElapsedTimeSeconds;
  double get expBarPercentage {
    return levelManager.expBarPercentage;
  }
  String get formattedElapsedTime {
    final duration = Duration(seconds: _totalElapsedTimeSeconds.toInt());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _isGameOver = false;
    _totalElapsedTimeSeconds = 0.0;
    _crystalSpawnTimer = crystalSpawnInterval;
    _enemySpawnTimer = enemySpawnInterval;
    levelManager = LevelManager(game: this);
    spawnManager = SpawnManager(game: this);
    player = PlayerComponent(position: Vector2.zero(), radius: 25.0);
    player.onHealthChanged = notifyListeners;
    player.onDeath = onPlayerDeath;
    await world.add(player);

    player.weaponManager.acquireWeapon(getWeaponDataById('default_projectile'));

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

  void addExperience(double amount) => levelManager.addExperience(amount);
  void levelUp() => levelManager.levelUp();
  List<UpgradeData> getLevelUpChoices() => levelManager.getLevelUpChoices();
  void selectUpgrade(UpgradeData upgrade) => levelManager.selectUpgrade(upgrade);

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;
    final previousTimeInt = _totalElapsedTimeSeconds.toInt();
    _totalElapsedTimeSeconds += dt;
    if (_totalElapsedTimeSeconds.toInt() != previousTimeInt) {
      notifyListeners();
    }
    _crystalSpawnTimer -= dt;
    if (_crystalSpawnTimer <= 0) {
      spawnManager.spawnCrystal();
      _crystalSpawnTimer = crystalSpawnInterval;
    }
    _enemySpawnTimer -= dt;
    if (_enemySpawnTimer <= 0) {
      spawnManager.spawnEnemy();
      spawnManager.spawnEnemy();

      _enemySpawnTimer = enemySpawnInterval;
    }
    if (!player.isDead && joystick.direction != JoystickDirection.idle) {
      if (!joystick.delta.isZero()) {
        player.position.add(joystick.relativeDelta * playerSpeed * dt);
      }
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
    paused = true;
    overlays.add('GameOverOverlay');
    notifyListeners();
  }
}