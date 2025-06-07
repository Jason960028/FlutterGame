import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'enemy_component.dart';
import 'crystal_component.dart';
import '../my_game.dart';
import 'weapon_manager_component.dart';
import 'passive_manager_component.dart'; // PassiveManagerComponent 임포트

class PlayerComponent extends PositionComponent with CollisionCallbacks, HasGameRef<MyGame> {
  static final _paint = Paint()..color = Colors.yellow;
  final double _radius;

  double maxHealth = 100.0;
  double currentHealth = 100.0;
  bool isDead = false;

  late final WeaponManagerComponent weaponManager;
  late final PassiveManagerComponent passiveManager; // PassiveManager 추가

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
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: _radius, anchor: Anchor.center));

    weaponManager = WeaponManagerComponent(player: this);
    passiveManager = PassiveManagerComponent(); // PassiveManager 생성
    await add(weaponManager);
    await add(passiveManager); // Player의 자식으로 추가
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
    onDeath?.call();
    onHealthChanged?.call();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (isDead) return;
    if (other is EnemyComponent) {
      takeDamage(other.damageToPlayer);
    } else if (other is CrystalComponent) {
      gameRef.addExperience(other.expValue);
      other.removeFromParent();
    }
  }
}