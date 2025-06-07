import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'enemy_component.dart';
import 'crystal_component.dart';
import '../my_game.dart';
import 'player_projectile_component.dart';
import 'tornado_component.dart'; // TornadoComponent 임포트
import 'dart:math' as math;

class PlayerComponent extends PositionComponent with CollisionCallbacks, HasGameRef<MyGame> {
  static final _paint = Paint()..color = Colors.yellow;
  final double _radius;

  double maxHealth = 100.0;
  double currentHealth = 100.0;
  bool isDead = false;

  // 기본 발사체 관련
  double projectileSpeed = 300.0;
  double fireRate = 2.0; // 초당 2번 발사 (0.5초 간격)
  double _fireCooldown = 0;

  // 부요의 깃털 (회오리) 관련
  double tornadoSpawnRate = 3.0; // 3초마다 회오리 소환
  double _tornadoCooldown = 0.0;
  final math.Random _random = math.Random();

  VoidCallback? onHealthChanged;
  VoidCallback? onDeath;

  PlayerComponent({Vector2? position, double radius = 25.0})
      : _radius = radius,
        super(
        position: position ?? Vector2.zero(),
        size: Vector2.all(radius * 2),
        anchor: Anchor.center,
      ) {
    currentHealth = maxHealth;
    _fireCooldown = 1 / fireRate; // 초기 발사 쿨다운
    _tornadoCooldown = tornadoSpawnRate; // 초기 회오리 쿨다운
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: _radius, anchor: Anchor.center));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isDead) {
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), _radius, _paint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || gameRef.isGameOver) return;

    // 기본 발사체 로직
    _fireCooldown -= dt;
    if (_fireCooldown <= 0) {
      fireProjectile();
      _fireCooldown = 1 / fireRate; // 쿨다운 초기화
    }

    // "부요의 깃털" (회오리) 소환 로직 - 조건부 실행
    if (gameRef.hasFeatherOfBuyo) {
      _tornadoCooldown -= dt;
      if (_tornadoCooldown <= 0) {
        spawnTornado();
        _tornadoCooldown = tornadoSpawnRate; // 쿨다운 초기화
      }
    }
  }

  void fireProjectile() {
    EnemyComponent? closestEnemy;
    double minDistanceSq = double.infinity;

    for (final component in gameRef.world.children.whereType<EnemyComponent>()) {
      if (!component.isDead) {
        final distanceSq = component.position.distanceToSquared(position);
        if (distanceSq < minDistanceSq) {
          minDistanceSq = distanceSq;
          closestEnemy = component;
        }
      }
    }

    if (closestEnemy != null) {
      Vector2 direction = (closestEnemy.position - position).normalized();
      final projectile = PlayerProjectileComponent(
        position: position.clone(),
        velocity: direction * projectileSpeed,
      );
      gameRef.world.add(projectile);
    }
  }

  void spawnTornado() {
    double angle = _random.nextDouble() * 2 * math.pi;
    Vector2 initialVelocity = Vector2(math.cos(angle), math.sin(angle));

    final tornado = TornadoComponent(
      position: position.clone(),
      initialVelocity: initialVelocity,
    );
    gameRef.world.add(tornado);

    if (kDebugMode) {
      print("부요의 깃털: 회오리 소환!");
    }
  }

  void takeDamage(double damageAmount) {
    if (isDead) return;
    currentHealth -= damageAmount;
    onHealthChanged?.call();

    if (kDebugMode) {
      print("플레이어 체력: $currentHealth / $maxHealth");
    }

    if (currentHealth <= 0) {
      currentHealth = 0;
      die();
    }
  }

  void die() {
    if (isDead) return;
    isDead = true;
    if (kDebugMode) {
      print("플레이어 사망!");
    }
    onDeath?.call(); // MyGame의 onPlayerDeath 호출
    onHealthChanged?.call(); // 최종 체력 상태 알림
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (isDead) return;

    if (other is EnemyComponent) {
      if (kDebugMode) {
        print("플레이어와 적 충돌! 플레이어가 데미지를 입습니다.");
      }
      takeDamage(other.damageToPlayer);
    } else if (other is CrystalComponent) {
      if (kDebugMode) {
        print("플레이어와 크리스탈 충돌! 크리스탈 제거됨. EXP +${other.expValue}");
      }
      gameRef.addExperience(other.expValue);
      other.removeFromParent();
    }
  }
}