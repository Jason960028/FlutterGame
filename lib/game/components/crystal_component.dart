import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class CrystalComponent extends PositionComponent with CollisionCallbacks {
  static final _paint = Paint()..color = Colors.green;
  final double _radius;
  final double expValue;

  CrystalComponent({
    Vector2? position,
    double radius = 15.0,
    this.expValue = 5.0,
  })  : _radius = radius,
        super(
        position: position ?? Vector2.zero(),
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
}