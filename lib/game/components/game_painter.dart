import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../managers/game_state.dart'; // GameState에서 ExperienceCrystal, Enemy, Projectile 클래스를 가져옴

// 게임 요소를 그리는 CustomPainter 클래스
class GamePainter extends CustomPainter {
  final GameState gameState; // GameState 전체를 받도록 변경
  final Offset screenCenterPosition; // 화면 중앙은 UI 종속적이므로 계속 받음

  GamePainter({
    required this.gameState,
    required this.screenCenterPosition,
  });

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1.0;
    const double gridSize = 50.0;
    // gameState.cameraPosition 사용
    double startWorldX = (gameState.cameraPosition.dx / gridSize).floor() * gridSize;
    double endWorldX = ((gameState.cameraPosition.dx + size.width) / gridSize).ceil() * gridSize;
    for (double worldX = startWorldX; worldX <= endWorldX; worldX += gridSize) {
      final screenX = worldX - gameState.cameraPosition.dx;
      canvas.drawLine(Offset(screenX, 0), Offset(screenX, size.height), paint);
    }
    double startWorldY = (gameState.cameraPosition.dy / gridSize).floor() * gridSize;
    double endWorldY = ((gameState.cameraPosition.dy + size.height) / gridSize).ceil() * gridSize;
    for (double worldY = startWorldY; worldY <= endWorldY; worldY += gridSize) {
      final screenY = worldY - gameState.cameraPosition.dy;
      canvas.drawLine(Offset(0, screenY), Offset(size.width, screenY), paint);
    }
  }

  void _drawCharacter(Canvas canvas, Size size) {
    final characterPaint = Paint()
      ..color = Colors.blue // 캐릭터 색상
      ..style = PaintingStyle.fill;
    final path = Path();
    const double charHeight = 30.0;
    const double charWidth = 20.0;
    // screenCenterPosition 사용
    path.moveTo(screenCenterPosition.dx, screenCenterPosition.dy - charHeight / 2);
    path.lineTo(screenCenterPosition.dx - charWidth / 2, screenCenterPosition.dy + charHeight / 2);
    path.lineTo(screenCenterPosition.dx + charWidth / 2, screenCenterPosition.dy + charHeight / 2);
    path.close();
    canvas.drawPath(path, characterPaint);
  }

  void _drawCrystals(Canvas canvas, Size size) {
    // gameState.crystals 사용
    for (var crystal in gameState.crystals) {
      final crystalPaint = Paint()
        ..color = crystal.color // 크리스탈 고유 색상 사용
        ..style = PaintingStyle.fill;

      final screenPosition = crystal.worldPosition - gameState.cameraPosition;

      if (screenPosition.dx < -crystal.radius || screenPosition.dx > size.width + crystal.radius ||
          screenPosition.dy < -crystal.radius || screenPosition.dy > size.height + crystal.radius) {
        continue;
      }

      Path crystalPath = Path();
      crystalPath.moveTo(screenPosition.dx, screenPosition.dy - crystal.radius); // Top
      crystalPath.lineTo(screenPosition.dx + crystal.radius * 0.7, screenPosition.dy); // Right
      crystalPath.lineTo(screenPosition.dx, screenPosition.dy + crystal.radius); // Bottom
      crystalPath.lineTo(screenPosition.dx - crystal.radius * 0.7, screenPosition.dy); // Left
      crystalPath.close();
      canvas.drawPath(crystalPath, crystalPaint);
    }
  }

  void _drawEnemies(Canvas canvas, Size size) {
    // gameState.enemies 사용
    for (var enemy in gameState.enemies) {
      if (enemy.health <= 0) continue; // 죽은 적은 그리지 않음

      final enemyPaint = Paint()
        ..color = enemy.color // 적 등급별 색상 사용
        ..style = PaintingStyle.fill;

      final screenPosition = enemy.worldPosition - gameState.cameraPosition;

      if (screenPosition.dx < -enemy.radius || screenPosition.dx > size.width + enemy.radius ||
          screenPosition.dy < -enemy.radius || screenPosition.dy > size.height + enemy.radius) {
        continue;
      }
      canvas.drawCircle(screenPosition, enemy.radius, enemyPaint);

      // (선택) 적 체력 바 표시
      // GameState.enemyStats를 사용하여 해당 적 타입의 최대 체력 가져오기
      final enemyMaxHealth = GameState.enemyStats[enemy.type]!['health'];
      if (enemy.health < enemyMaxHealth) {
        final double healthBarWidth = enemy.radius * 1.5;
        final double healthBarHeight = 5.0;
        final Offset healthBarOffset = Offset(screenPosition.dx - healthBarWidth / 2, screenPosition.dy - enemy.radius - healthBarHeight - 2);

        final backgroundPaint = Paint()..color = Colors.black54;
        canvas.drawRect(Rect.fromLTWH(healthBarOffset.dx, healthBarOffset.dy, healthBarWidth, healthBarHeight), backgroundPaint);

        final currentHealthRatio = enemy.health / enemyMaxHealth;
        final healthPaint = Paint()..color = Colors.red;
        canvas.drawRect(Rect.fromLTWH(healthBarOffset.dx, healthBarOffset.dy, healthBarWidth * currentHealthRatio, healthBarHeight), healthPaint);
      }
    }
  }

  void _drawProjectiles(Canvas canvas, Size size) {
    for (var projectile in gameState.projectiles) {
      if (!projectile.isActive) continue;

      final projectilePaint = Paint()
        ..color = projectile.color
        ..style = PaintingStyle.fill;

      final screenPosition = projectile.worldPosition - gameState.cameraPosition;

      if (screenPosition.dx < -projectile.radius || screenPosition.dx > size.width + projectile.radius ||
          screenPosition.dy < -projectile.radius || screenPosition.dy > size.height + projectile.radius) {
        continue;
      }
      canvas.drawCircle(screenPosition, projectile.radius, projectilePaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawCrystals(canvas, size);
    _drawEnemies(canvas, size);
    _drawProjectiles(canvas, size);
    _drawCharacter(canvas, size); // 캐릭터를 가장 위에 그림
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    // GameState 객체 자체가 변경되거나 (거의 없음), 내부 값 변경 시 setState가 호출되므로
    // GameScreen에서 GameState의 변경을 감지하여 CustomPaint를 다시 빌드하게 됨.
    // 여기서는 gameState 객체의 참조가 바뀌거나, screenCenterPosition이 바뀔 때만 다시 그리도록 할 수 있음.
    // 혹은 더 간단하게 항상 true로 두어 GameScreen의 setState에 의존.
    return true; // GameScreen의 setState에 의해 다시 그려짐
  }
}
