// lib/game/my_game.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'components/player_component.dart';
import 'components/enemy_component.dart';
import 'package:flame/palette.dart';
import 'components/crystal_component.dart';
import 'weapons/weapon_definitions.dart';
import 'upgrades/upgrade_definitions.dart';
import 'upgrades/upgrade_data.dart';

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
  final math.Random _random = math.Random();
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
  int get currentLevel => _currentLevel;
  double get expToNextLevel => _expToNextLevel;
  double get totalElapsedTimeSeconds => _totalElapsedTimeSeconds;
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
    _crystalSpawnTimer = crystalSpawnInterval;
    _enemySpawnTimer = enemySpawnInterval;
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

  void addExperience(double amount) {
    if (_isGameOver) return;
    _currentExp += amount;
    if (kDebugMode) print("경험치 획득: +$amount. 현재 EXP: $_currentExp / $_expToNextLevel");
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

    // --- 수정된 로직 시작 ---
    // 1. 먼저 선택 가능한 업그레이드가 있는지 확인합니다.
    final choices = getLevelUpChoices();

    // 2. 선택지가 있을 경우에만 게임을 멈추고 오버레이를 표시합니다.
    if (choices.isNotEmpty) {
      paused = true;
      overlays.add('LevelUpOverlay');
    } else {
      // 선택지가 없으면 게임을 계속 진행하고 로그만 남깁니다.
      if (kDebugMode) {
        print("레벨업 했지만, 선택 가능한 업그레이드가 없습니다.");
      }
      // 경험치가 남아서 또 레벨업이 가능한지 여기서 체크할 수 있습니다.
      if (_currentExp >= _expToNextLevel) {
        levelUp();
      }
    }
    notifyListeners(); // 레벨업 상태는 항상 UI에 반영
  }

  List<UpgradeData> getLevelUpChoices() {
    List<UpgradeData> possibleUpgrades = [];
    final currentWeapons = player.weaponManager.activeWeapons;
    final currentPassives = player.passiveManager.passiveLevels;

    for (final upgrade in allUpgrades) {
      if (upgrade.type == UpgradeType.weapon) {
        if (upgrade.id.endsWith('_acquire')) {
          final weaponId = upgrade.id.replaceAll('_acquire', '');
          if (!currentWeapons.any((w) => w.id == weaponId)) {
            possibleUpgrades.add(upgrade);
          }
        } else {
          final weaponId = upgrade.id.substring(0, upgrade.id.indexOf('_lv'));
          final weapon = player.weaponManager.getWeaponById(weaponId);
          if (weapon != null && upgrade.id.contains('_lv${weapon.level}_')) {
            possibleUpgrades.add(upgrade);
          }
        }
      } else if (upgrade.type == UpgradeType.passive) {
        final passiveId = upgrade.id.split('_lv')[0];
        final currentLevel = currentPassives[passiveId] ?? 0;

        // 다음 레벨의 패시브 업그레이드인지 확인
        if (upgrade.id.contains('_lv${currentLevel + 1}')) {
          possibleUpgrades.add(upgrade);
        }
      }
    }
    possibleUpgrades.shuffle(_random);
    return possibleUpgrades.take(3).toList();
  }

  void selectUpgrade(UpgradeData upgrade) {
    upgrade.apply(this);
    overlays.remove('LevelUpOverlay');
    paused = false;
    notifyListeners();
    if (_currentExp >= _expToNextLevel) {
      levelUp();
    }
  }

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
      _spawnCrystal();
      _crystalSpawnTimer = crystalSpawnInterval;
    }
    _enemySpawnTimer -= dt;
    if (_enemySpawnTimer <= 0) {
      _spawnEnemy();
      _spawnEnemy();

      _enemySpawnTimer = enemySpawnInterval;
    }
    if (!player.isDead && joystick.direction != JoystickDirection.idle) {
      if (!joystick.delta.isZero()) {
        player.position.add(joystick.relativeDelta * playerSpeed * dt);
      }
    }
  }

  void _spawnCrystal() {
    if (world.children.whereType<CrystalComponent>().length >= maxCrystalsOnField) return;
    final angle = _random.nextDouble() * 2 * math.pi;
    final radius = crystalSpawnMinRadiusFromPlayer + _random.nextDouble() * (crystalSpawnMaxRadiusFromPlayer - crystalSpawnMinRadiusFromPlayer);
    final spawnPosition = player.position + Vector2(math.cos(angle) * radius, math.sin(angle) * radius);
    final expValue = 5.0 + _random.nextInt(11);
    final crystal = CrystalComponent(position: spawnPosition, expValue: expValue);
    world.add(crystal);
  }

  void _spawnEnemy() {
    if (world.children.whereType<EnemyComponent>().length >= maxEnemiesOnField) return;
    final angle = _random.nextDouble() * 2 * math.pi;
    final radius = enemySpawnMinRadiusFromPlayer + _random.nextDouble() * (enemySpawnMaxRadiusFromPlayer - enemySpawnMinRadiusFromPlayer);
    final spawnPosition = player.position + Vector2(math.cos(angle) * radius, math.sin(angle) * radius);
    final health = 1.0 + _currentLevel * 5;
    final damage = 0.0 + _currentLevel * 1;
    final expDrop = 500.0 + _currentLevel * 3;
    final enemy = EnemyComponent(
      position: spawnPosition,
      health: health,
      damageToPlayer: damage,
      expDropAmount: expDrop,
    );
    world.add(enemy);
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