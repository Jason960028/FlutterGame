import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'enemy_component.dart';

class PlayerProjectileComponent extends PositionComponent with CollisionCallbacks {
  static final _paint = Paint()..color = Colors.lightBlueAccent;
  final Vector2 velocity;
  final double _radius;
  final double damage; // final로 유지, 생성 시 값을 받음

  PlayerProjectileComponent({
    required Vector2 position,
    required this.velocity,
    required this.damage, // 필수로 받도록 변경
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