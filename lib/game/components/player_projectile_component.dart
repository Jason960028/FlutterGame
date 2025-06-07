import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'enemy_component.dart';

class PlayerProjectileComponent extends PositionComponent with CollisionCallbacks {
  static final _paint = Paint()..color = Colors.lightBlueAccent;
  final Vector2 velocity;
  final double _radius;
  final double damage;

  PlayerProjectileComponent({
    required Vector2 position,
    required this.velocity,
    this.damage = 10.0,
    double radius = 5.0,
  }) : _radius = radius,
        super(
        position: position,
        size: Vector2.all(radius * 2),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: _radius, anchor: Anchor.center));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), _radius, _paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);
    // TODO: 화면 밖으로 나가면 제거하는 로직 추가 (예: if (!gameRef.camera.visibleWorldRect.overlaps(toRect())) removeFromParent();)
    // 이를 위해서는 HasGameRef<MyGame> 믹스인이 필요합니다.
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EnemyComponent) {
      if (!other.isDead) {
        other.takeDamage(damage);
      }
      removeFromParent();
    }
  }
}