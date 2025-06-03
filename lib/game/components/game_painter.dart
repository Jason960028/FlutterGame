import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../managers/game_state.dart';

// 게임 요소를 그리는 CustomPainter 클래스
class GamePainter extends CustomPainter {
  final GameState gameState;
  final Offset screenCenterPosition;

  GamePainter({
    required this.gameState,
    required this.screenCenterPosition,
  });

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1.0;
    const double gridSize = 50.0;
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
      canvas.drawLine(Offset(0, screenY), Offset(0, size.width), paint);
    }
  }

  // _drawCharacter method removed

  void _drawCrystals(Canvas canvas, Size size) {
    for (var crystal in gameState.crystals) {
      final crystalPaint = Paint()
        ..color = crystal.color
        ..style = PaintingStyle.fill;

      final screenPosition = crystal.worldPosition - gameState.cameraPosition;

      if (screenPosition.dx < -crystal.radius || screenPosition.dx > size.width + crystal.radius ||
          screenPosition.dy < -crystal.radius || screenPosition.dy > size.height + crystal.radius) {
        continue;
      }

      Path crystalPath = Path();
      crystalPath.moveTo(screenPosition.dx, screenPosition.dy - crystal.radius);
      crystalPath.lineTo(screenPosition.dx + crystal.radius * 0.7, screenPosition.dy);
      crystalPath.lineTo(screenPosition.dx, screenPosition.dy + crystal.radius);
      crystalPath.lineTo(screenPosition.dx - crystal.radius * 0.7, screenPosition.dy);
      crystalPath.close();
      canvas.drawPath(crystalPath, crystalPaint);
    }
  }

  void _drawEnemies(Canvas canvas, Size size) {
    for (var enemy in gameState.enemies) {
      if (enemy.health <= 0) continue;

      final enemyPaint = Paint()
        ..color = enemy.color
        ..style = PaintingStyle.fill;

      final screenPosition = enemy.worldPosition - gameState.cameraPosition;

      if (screenPosition.dx < -enemy.radius || screenPosition.dx > size.width + enemy.radius ||
          screenPosition.dy < -enemy.radius || screenPosition.dy > size.height + enemy.radius) {
        continue;
      }
      canvas.drawCircle(screenPosition, enemy.radius, enemyPaint);

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
    // _drawCharacter(canvas, size); // Removed
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return true;
  }
}