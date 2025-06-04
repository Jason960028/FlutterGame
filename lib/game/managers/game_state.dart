import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'knight_state.dart';


// 경험치 크리스탈 등급 (색상 구분을 위함)
enum ExperienceCrystalType { normal, elite, boss }

// ExperienceCrystal 클래스 수정
class ExperienceCrystal {
  final String id;
  Offset worldPosition;
  final double expValue;
  final double radius;
  final Color color; // 경험치 크리스탈 색상 추가
  final ExperienceCrystalType crystalType; // 경험치 크리스탈 등급

  ExperienceCrystal({
    required this.id,
    required this.worldPosition,
    required this.expValue,
    this.radius = 8.0, // 크리스탈 기본 크기 약간 줄임
    required this.color,
    required this.crystalType,
  });
}

// 적 등급 정의
enum EnemyType { normal, elite, boss }

// 적 클래스 정의
class Enemy {
  final String id;
  final EnemyType type;
  Offset worldPosition;
  double health;
  final double speed;
  final Color color; // 등급별 색상
  final double radius;
  final double damageToPlayer; // 플레이어에게 주는 데미지
  final double expToDrop; // 처치 시 드랍할 경험치 양
  final ExperienceCrystalType crystalTypeToDrop; // 드랍할 경험치 크리스탈 등급

  // 보스 전용
  bool isBoss = false;
  double projectileTimer = 0.0;
  final double projectileInterval; // 발사체 발사 간격 (보스만 해당)

  Enemy({
    required this.id,
    required this.type,
    required this.worldPosition,
    required this.health,
    required this.speed,
    required this.color,
    this.radius = 15.0,
    required this.damageToPlayer,
    required this.expToDrop,
    required this.crystalTypeToDrop,
    this.projectileInterval = 2.0, // 기본 보스 발사 간격 2초
  }) {
    isBoss = (type == EnemyType.boss);
  }
}

// 보스 발사체 클래스 (간단하게)
class Projectile {
  final String id;
  Offset worldPosition;
  final Offset direction;
  final double speed;
  final Color color;
  final double radius;
  final double damageToPlayer;
  final double damageToEnemy;
  final bool isFromPlayer;
  bool isActive = true;

  Projectile({
    required this.id,
    required this.worldPosition,
    required this.direction,
    this.speed = 200.0,
    this.color = Colors.redAccent,
    this.radius = 8.0,
    this.damageToPlayer = 15.0,
    this.damageToEnemy = 10.0,
    this.isFromPlayer = false,
  });
}

class GameState {
  // --- 기존 상태 변수들 ---
  Offset worldCharacterPosition = Offset.zero;
  Offset cameraPosition = Offset.zero;
  Offset? joystickAnchor;
  Offset? currentDrag;
  Offset currentDirection = Offset.zero;
  double totalElapsedTimeSeconds = 0.0;
  int currentLevel = 1;
  double currentExp = 0;
  double expToNextLevel = 100;
  double expBarPercentage = 0.0;
  List<ExperienceCrystal> crystals = [];
  final math.Random random = math.Random();
  final Uuid uuid = const Uuid();

  // --- 플레이어 상태 관련 ---
  KnightState playerState = KnightState.idle;
  double _hurtTimer = 0.0;
  double _attackTimer = 0.0;
  final double hurtStateDuration = 0.5;
  final double attackStateDuration = 0.3;


  // --- 게임 설정 값 ---
  final int maxCrystals = 50; // 맵의 크리스탈 수 약간 줄임
  final double crystalSpawnAreaRadius = 1000.0;
  final double characterCollisionRadius = 15.0;
  final double playerMaxHealth = 100.0; // 플레이어 최대 체력
  double playerCurrentHealth = 100.0; // 플레이어 현재 체력

  bool isGameOver = false; // 플레이어 사망 여부

  // --- 플레이어 발사체 관련 ---
  double playerProjectileTimer = 0.0;
  final double playerProjectileInterval = 1;


  // --- 적 관련 상태 변수 ---
  List<Enemy> enemies = [];
  List<Projectile> projectiles = []; // 보스 발사체 리스트
  final int maxNormalEnemies = 100000; // 일반 적 최대 수
  double normalEnemySpawnTimer = 0.0;
  final double normalEnemySpawnInterval = 2.0; // 일반 적 스폰 간격 (초)

  double eliteEnemySpawnTimer = 0.0;
  final double eliteEnemySpawnInterval = 30.0; // 엘리트 적 스폰 간격 (초)

  double bossEnemySpawnTimer = 0.0;
  final double bossEnemySpawnInterval = 10.0; // 보스 적 스폰 간격 (5분)

  // 적 등급별 설정 값
  static const Map<EnemyType, Map<String, dynamic>> enemyStats = {
    EnemyType.normal: {
      'health': 20.0, 'speed': 80.0, 'color': Colors.grey, 'radius': 12.0,
      'damage': 5.0, 'exp': 10.0, 'crystalType': ExperienceCrystalType.normal,
    },
    EnemyType.elite: {
      'health': 100.0, 'speed': 60.0, 'color': Colors.orange, 'radius': 18.0,
      'damage': 15.0, 'exp': 50.0, 'crystalType': ExperienceCrystalType.elite,
    },
    EnemyType.boss: {
      'health': 500.0, 'speed': 40.0, 'color': Colors.red, 'radius': 25.0,
      'damage': 25.0, 'exp': 200.0, 'crystalType': ExperienceCrystalType.boss,
      'projectileInterval': 2.5,
    },
  };

  // 경험치 크리스탈 등급별 색상
  static const Map<ExperienceCrystalType, Color> crystalColors = {
    ExperienceCrystalType.normal: Colors.lightGreenAccent,
    ExperienceCrystalType.elite: Colors.cyanAccent,
    ExperienceCrystalType.boss: Colors.pinkAccent,
  };


  GameState() {
    initializeCrystals();
    updateExpBarPercentage();
    playerCurrentHealth = playerMaxHealth; // 게임 시작 시 체력 초기화
  }

  // --- 크리스탈 관리 ---
  void initializeCrystals() {
    List<ExperienceCrystal> newCrystals = [];
    for (int i = 0; i < maxCrystals; i++) {
      newCrystals.add(_createSingleCrystal(ExperienceCrystalType.normal, 5.0)); // 기본 크리스탈
    }
    crystals = newCrystals;
  }

  ExperienceCrystal _createSingleCrystal(ExperienceCrystalType type, double expValue, {Offset? atPosition}) {
    final spawnCenter = atPosition ?? worldCharacterPosition;
    double angle = random.nextDouble() * 2 * math.pi;
    // 크리스탈은 캐릭터 주변 좀 더 가까이 스폰되도록 수정
    double distance = (atPosition == null) ? (100 + random.nextDouble() * crystalSpawnAreaRadius * 0.5) : 0;


    Offset position = Offset(
      spawnCenter.dx + math.cos(angle) * distance,
      spawnCenter.dy + math.sin(angle) * distance,
    );

    return ExperienceCrystal(
      id: uuid.v4(),
      worldPosition: position,
      expValue: expValue,
      color: crystalColors[type] ?? Colors.white, // 등급별 색상 적용
      crystalType: type,
    );
  }

  // --- 경험치 및 레벨 관리 ---
  void updateExpBarPercentage() {
    if (expToNextLevel <= 0) {
      expBarPercentage = 1.0;
    } else {
      expBarPercentage = (currentExp / expToNextLevel).clamp(0.0, 1.0);
    }
  }

  void addExperience(double amount) {
    currentExp += amount;
    if (currentExp >= expToNextLevel) {
      levelUp();
    }
    updateExpBarPercentage();
  }

  void levelUp() {
    currentLevel++;
    currentExp -= expToNextLevel;
    expToNextLevel *= 1.10;
    if (currentExp >= expToNextLevel && expToNextLevel > 0) {
      levelUp();
    } else {
      updateExpBarPercentage();
    }
    print("Level Up! Current Level: $currentLevel, Next EXP: $expToNextLevel");
  }

  // --- 적 스폰 로직 ---
  void updateEnemySpawns(double deltaTime) {
    // 일반 적 스폰
    normalEnemySpawnTimer += deltaTime;
    if (normalEnemySpawnTimer >= normalEnemySpawnInterval && enemies.where((e) => e.type == EnemyType.normal).length < maxNormalEnemies) {
      _spawnEnemy(EnemyType.normal);
      normalEnemySpawnTimer = 0.0;
    }

    // 엘리트 적 스폰
    eliteEnemySpawnTimer += deltaTime;
    if (eliteEnemySpawnTimer >= eliteEnemySpawnInterval) {
      if (enemies.where((e) => e.type == EnemyType.elite).isEmpty) { // 엘리트는 한 번에 하나만
        _spawnEnemy(EnemyType.elite);
      }
      eliteEnemySpawnTimer = 0.0;
    }

    // 보스 적 스폰
    bossEnemySpawnTimer += deltaTime;
    if (bossEnemySpawnTimer >= bossEnemySpawnInterval) {
      if (enemies.where((e) => e.type == EnemyType.boss).isEmpty) { // 보스도 한 번에 하나만
        _spawnEnemy(EnemyType.boss);
      }
      bossEnemySpawnTimer = 0.0;
    }
  }

  void _spawnEnemy(EnemyType type) {
    // 플레이어 시야 바깥쪽에 스폰
    double spawnAngle = random.nextDouble() * 2 * math.pi;
    // 화면 대각선 길이보다 약간 더 멀리 스폰하도록 수정 (screenSize 필요)
    // 임시로 crystalSpawnAreaRadius 사용
    double spawnDistance = crystalSpawnAreaRadius * 1.5;
    Offset position = worldCharacterPosition + Offset(math.cos(spawnAngle) * spawnDistance, math.sin(spawnAngle) * spawnDistance);

    final stats = enemyStats[type]!;
    enemies.add(Enemy(
      id: uuid.v4(),
      type: type,
      worldPosition: position,
      health: stats['health'],
      speed: stats['speed'],
      color: stats['color'],
      radius: stats['radius'],
      damageToPlayer: stats['damage'],
      expToDrop: stats['exp'],
      crystalTypeToDrop: stats['crystalType'],
      projectileInterval: stats['projectileInterval'] ?? 2.0,
    ));
    print("Spawned ${type.toString()} at $position");
  }

  // --- 적 이동 로직 ---
  void moveEnemies(double deltaTime) {
    for (var enemy in enemies) {
      if (enemy.health <= 0) continue; // 이미 죽은 적은 움직이지 않음

      Offset directionToPlayer = (worldCharacterPosition - enemy.worldPosition);
      if (directionToPlayer.distanceSquared > 0) {
        directionToPlayer = directionToPlayer / directionToPlayer.distance; // 정규화
        enemy.worldPosition += directionToPlayer * enemy.speed * deltaTime;
      }

      // 보스 발사체 로직
      if (enemy.isBoss) {
        enemy.projectileTimer += deltaTime;
        if (enemy.projectileTimer >= enemy.projectileInterval) {
          _fireBossProjectile(enemy);
          enemy.projectileTimer = 0.0;
        }
      }
    }
    _resolveEnemyOverlaps();
  }

  void _resolveEnemyOverlaps() {
    for (int i = 0; i < enemies.length; i++) {
      final e1 = enemies[i];
      if (e1.health <= 0) continue;
      for (int j = i + 1; j < enemies.length; j++) {
        final e2 = enemies[j];
        if (e2.health <= 0) continue;
        final diff = e2.worldPosition - e1.worldPosition;
        final distance = diff.distance;
        final minDistance = e1.radius + e2.radius;
        if (distance < minDistance && distance > 0) {
          final move = diff / distance * (minDistance - distance) / 2;
          e1.worldPosition -= move;
          e2.worldPosition += move;
        }
      }
    }
  }

  void updateStateTimers(double deltaTime) {
    if (_hurtTimer > 0) {
      _hurtTimer -= deltaTime;
      if (_hurtTimer <= 0) {
        _hurtTimer = 0.0;
        playerState = KnightState.idle;
      }
    }
    if (_attackTimer > 0) {
      _attackTimer -= deltaTime;
      if (_attackTimer <= 0) {
        _attackTimer = 0.0;
        playerState = currentDirection == Offset.zero
            ? KnightState.idle
            : KnightState.idle;
      }
    }
  }



  void _fireBossProjectile(Enemy boss) {
    Offset directionToPlayer = (worldCharacterPosition - boss.worldPosition);
    if (directionToPlayer.distanceSquared == 0) return; // 플레이어와 같은 위치면 발사 안함
    directionToPlayer = directionToPlayer / directionToPlayer.distance;

    projectiles.add(Projectile(
      id: uuid.v4(),
      worldPosition: boss.worldPosition + directionToPlayer * (boss.radius + 5.0), // 보스 약간 앞에서 발사
      direction: directionToPlayer,
      damageToPlayer: enemyStats[EnemyType.boss]!['damage'] * 0.5, // 보스 발사체 데미지 (예시)
    ));
  }

  void updatePlayerAttack(double deltaTime) {
    playerProjectileTimer += deltaTime;
    if (playerProjectileTimer >= playerProjectileInterval) {
      _firePlayerProjectile();
      playerProjectileTimer = 0.0;
    }
  }

  void _firePlayerProjectile() {
    if (enemies.isEmpty) return;
    // 가장 가까운 적을 찾음
    Enemy? target;
    double shortest = double.infinity;
    for (var e in enemies) {
      if (e.health <= 0) continue;
      final d = (e.worldPosition - worldCharacterPosition).distanceSquared;
      if (d < shortest) {
        shortest = d;
        target = e;
      }
    }
    if (target == null) return;
    Offset dir = (target.worldPosition - worldCharacterPosition);
    if (dir.distanceSquared == 0) return;
    dir = dir / dir.distance;

    projectiles.add(Projectile(
      id: uuid.v4(),
      worldPosition: worldCharacterPosition + dir * (characterCollisionRadius + 5.0),
      direction: dir,
      color: Colors.yellowAccent,
      speed: 250.0,
      radius: 6.0,
      damageToPlayer: 0.0,
      damageToEnemy: 20.0,
      isFromPlayer: true,
    ));
    playerState = KnightState.attack;
    _attackTimer = attackStateDuration;
  }

  void moveProjectiles(double deltaTime) {
    projectiles.removeWhere((p) {
      p.worldPosition += p.direction * p.speed * deltaTime;
      // 화면 밖으로 나가거나 비활성화된 발사체 제거 (간단한 범위 체크)
      final distSqFromPlayer = (p.worldPosition - worldCharacterPosition).distanceSquared;
      return !p.isActive || distSqFromPlayer > (crystalSpawnAreaRadius * 2) * (crystalSpawnAreaRadius * 2); // 너무 멀어지면 제거
    });
  }


  // --- 충돌 처리 로직 ---
  void checkCollisions() {
    // 플레이어와 크리스탈 충돌
    crystals.removeWhere((crystal) {
      final distance = (worldCharacterPosition - crystal.worldPosition).distance;
      if (distance < characterCollisionRadius + crystal.radius) {
        addExperience(crystal.expValue);
        print("Collected crystal! EXP +${crystal.expValue}");
        return true; // 제거
      }
      return false;
    });
    // 수집된 크리스탈만큼은 아니지만, 주기적으로 일반 크리스탈 스폰 (맵이 비지 않도록)
    if (random.nextDouble() < 0.05 && crystals.length < maxCrystals) { // 5% 확률로 스폰 시도
      crystals.add(_createSingleCrystal(ExperienceCrystalType.normal, 5.0 + random.nextDouble() * 5));
    }


    // 플레이어와 적 충돌
    List<Enemy> enemiesToRemove = [];
    for (var enemy in enemies) {
      if (enemy.health <= 0) continue;

      final distance = (worldCharacterPosition - enemy.worldPosition).distance;
      if (distance < characterCollisionRadius + enemy.radius) {
        playerCurrentHealth -= enemy.damageToPlayer;
        print("Player hit by ${enemy.type}! HP: $playerCurrentHealth");
        playerState = KnightState.hurt;
        _hurtTimer = hurtStateDuration;
        // 적은 플레이어와 충돌 시 바로 죽는 대신, 플레이어 공격에 의해 죽도록 변경 예정
        // 현재는 충돌 시 적도 데미지를 입고 죽는다고 가정 (간단하게)
        enemy.health -= 50; // 예시: 플레이어 몸빵 데미지
        if (enemy.health <= 0) {
          enemiesToRemove.add(enemy);
          // 죽은 위치에 경험치 크리스탈 드랍
          crystals.add(_createSingleCrystal(
            enemy.crystalTypeToDrop,
            enemy.expToDrop,
            atPosition: enemy.worldPosition,
          ));
        }
        if (playerCurrentHealth <= 0) {
          _handlePlayerDeath();
          return; // 게임 오버
        }
      }
    }

    // 플레이어 발사체와 적 충돌
    List<Projectile> playerProjectilesToRemove = [];
    for (var projectile in projectiles) {
      if (!projectile.isFromPlayer || !projectile.isActive) continue;
      for (var enemy in enemies) {
        if (enemy.health <= 0) continue;
        final distance = (enemy.worldPosition - projectile.worldPosition).distance;
        if (distance < enemy.radius + projectile.radius) {
          enemy.health -= projectile.damageToEnemy;
          projectile.isActive = false;
          playerProjectilesToRemove.add(projectile);
          if (enemy.health <= 0) {
            enemiesToRemove.add(enemy);
            crystals.add(_createSingleCrystal(
              enemy.crystalTypeToDrop,
              enemy.expToDrop,
              atPosition: enemy.worldPosition,
            ));
          }
          break;
        }
      }
    }
    projectiles.removeWhere((p) => playerProjectilesToRemove.contains(p));

    // 플레이어와 보스 발사체 충돌
    projectiles.removeWhere((projectile) {
      if (!projectile.isActive || projectile.isFromPlayer) return false;
      final distance = (worldCharacterPosition - projectile.worldPosition).distance;
      if (distance < characterCollisionRadius + projectile.radius) {
        playerCurrentHealth -= projectile.damageToPlayer;
        print("Player hit by projectile! HP: $playerCurrentHealth");
        playerState = KnightState.hurt;
        _hurtTimer = hurtStateDuration;
        projectile.isActive = false; // 발사체 비활성화 (제거 예약)
        if (playerCurrentHealth <= 0) {
          _handlePlayerDeath();
        }
        return true; // 충돌 시 제거
      }
      return false;
    });
    enemies.removeWhere((e) => enemiesToRemove.contains(e) || e.health <= 0);
  }

  void _handlePlayerDeath() {
    if (isGameOver) return;
    playerCurrentHealth = 0;
    isGameOver = true;
    playerState = KnightState.death;
    print("GAME OVER!");
  }


  // --- 조이스틱 및 캐릭터 이동 (기존 로직 유지) ---
  void updateJoystick(Offset? anchor, Offset? drag, Offset direction) {
    joystickAnchor = anchor;
    currentDrag = drag;
    currentDirection = direction;
  }

  void moveCharacter(double deltaTime, double movementSpeed) {
    if (currentDirection != Offset.zero) {
      final double moveAmount = movementSpeed * deltaTime;
      final Offset moveDelta = currentDirection * moveAmount;
      worldCharacterPosition += moveDelta;
      cameraPosition += moveDelta;
    }
    if (_attackTimer <= 0 && _hurtTimer <= 0 && !isGameOver) {
      playerState = KnightState.idle;
    }
  }
}
