import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../my_game.dart';
import 'player_component.dart'; // PlayerComponent 참조를 위해 필요 (gameRef.player 타입 명시)
import 'crystal_component.dart'; // CrystalComponent 임포트

class EnemyComponent extends PositionComponent with HasGameRef<MyGame>, CollisionCallbacks {
  static final _paint = Paint()..color = Colors.red;
  double speed = 100.0;
  double damageToPlayer;

  double maxHealth; // 초기 체력에 따라 설정되도록 변경
  double currentHealth;
  bool isDead = false;
  double expDropAmount; // 적 처치 시 드랍할 경험치 크리스탈의 값

  EnemyComponent({
    Vector2? position,
    Vector2? size,
    this.damageToPlayer = 10.0,
    double? health,
    this.expDropAmount = 20.0, // 기본 드랍 경험치
  }) : currentHealth = health ?? 30.0, // health가 null이면 30.0으로 초기화
        maxHealth = health ?? 30.0,    // maxHealth도 동일하게 초기화
        super(
        position: position ?? Vector2.zero(),
        size: size ?? Vector2.all(40.0),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isDead) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
    }
  }

  void takeDamage(double damageAmount) {
    if (isDead) return;
    currentHealth -= damageAmount;
    if (kDebugMode) {
      print("적 체력 (${hashCode}): $currentHealth / $maxHealth");
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
      print("적 사망! (${hashCode}) 경험치 크리스탈 드랍.");
    }

    final crystal = CrystalComponent(
      position: position.clone(),
      expValue: expDropAmount,
    );
    gameRef.world.add(crystal);

    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || gameRef.isGameOver) return;

    // player가 아직 로드되지 않았을 수 있으므로 체크
    if (!gameRef.player.isMounted) return;

    final PlayerComponent player = gameRef.player;
    Vector2 directionToPlayer = (player.position - position).normalized();
    if (!directionToPlayer.isZero()) {
      position.add(directionToPlayer * speed * dt);
    }
  }
}