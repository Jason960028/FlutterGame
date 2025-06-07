import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'enemy_component.dart';
import '../my_game.dart';

class TornadoComponent extends PositionComponent with HasGameRef<MyGame>, CollisionCallbacks {
  static final _paint = Paint()..color = Colors.white.withOpacity(0.5);
  final double _radius; // 인스턴스 변수로 변경
  Vector2 velocity;
  double lifetime = 5.0;
  final double damagePerSecond = 15.0; // 또는 충돌 시 데미지
  Set<EnemyComponent> _collidingEnemies = {};
  double _damageTickTimer = 0.0;
  final double _damageInterval = 0.5;

  TornadoComponent({
    required Vector2 position,
    required Vector2 initialVelocity,
    double radius = 20.0, // radius를 생성자 파라미터로 받음
  }) : _radius = radius, // 인스턴스 변수 _radius 초기화
        velocity = initialVelocity.normalized() * 150.0,
        super(
        position: position,
        size: Vector2.all(radius * 2), // 생성자 파라미터 radius 사용
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final hitbox = CircleHitbox(radius: _radius, anchor: Anchor.center); // 인스턴스 변수 _radius 사용
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // gameRef.totalElapsedTimeSeconds 접근 가능 (HasGameRef<MyGame> 사용)
    for (int i = 0; i < 5; i++) {
      final offsetAngle = (2 * math.pi / 5) * i + (gameRef.totalElapsedTimeSeconds * 2);
      final offsetRadius = _radius * 0.6 * (math.sin(gameRef.totalElapsedTimeSeconds * 3 + i) * 0.2 + 0.8);
      final dotX = size.x / 2 + math.cos(offsetAngle) * offsetRadius;
      final dotY = size.y / 2 + math.sin(offsetAngle) * offsetRadius;
      canvas.drawCircle(Offset(dotX, dotY), _radius * 0.2, _paint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifetime -= dt;
    if (lifetime <= 0) {
      removeFromParent();
      return;
    }

    position.add(velocity * dt);

    // 플레이어가 아직 로드되지 않았거나, 이미 제거되었다면 player.position 접근 시 오류 발생 가능
    if (!gameRef.player.isMounted) return;

    final playerPos = gameRef.player.position;
    final limit = 500.0;
    // 히트박스 반지름(_radius)을 고려하여 경계 계산
    final gameMinX = playerPos.x - limit + _radius;
    final gameMaxX = playerPos.x + limit - _radius;
    final gameMinY = playerPos.y - limit + _radius;
    final gameMaxY = playerPos.y + limit - _radius;


    if (position.x - _radius < gameMinX && velocity.x < 0) {
      velocity.x *= -1;
      position.x = gameMinX + _radius;
    } else if (position.x + _radius > gameMaxX && velocity.x > 0) {
      velocity.x *= -1;
      position.x = gameMaxX - _radius;
    }

    if (position.y - _radius < gameMinY && velocity.y < 0) {
      velocity.y *= -1;
      position.y = gameMinY + _radius;
    } else if (position.y + _radius > gameMaxY && velocity.y > 0) {
      velocity.y *= -1;
      position.y = gameMaxY - _radius;
    }

    _damageTickTimer -= dt;
    if(_damageTickTimer <=0) {
      for (var enemy in _collidingEnemies.toList()) {
        if (enemy.isMounted && !enemy.isDead) {
          enemy.takeDamage(damagePerSecond * _damageInterval);
          if (kDebugMode) {
            print("회오리가 적(${enemy.hashCode})에게 데미지: ${damagePerSecond * _damageInterval}");
          }
        }
      }
      _damageTickTimer = _damageInterval;
    }
    _collidingEnemies.removeWhere((enemy) => enemy.isDead || !enemy.isMounted);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EnemyComponent && !other.isDead) {
      _collidingEnemies.add(other);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is EnemyComponent) {
      _collidingEnemies.remove(other);
    }
  }
}