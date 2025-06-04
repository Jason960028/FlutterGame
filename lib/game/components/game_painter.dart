import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui; // ui.Image 사용을 위해 추가
import '../managers/game_state.dart';

// 게임 요소를 그리는 CustomPainter 클래스
class GamePainter extends CustomPainter {
  final GameState gameState;
  final Offset screenCenterPosition;
  final ui.Image? backgroundImage; // 배경 이미지 파라미터 추가

  GamePainter({
    required this.gameState,
    required this.screenCenterPosition,
    this.backgroundImage, // 생성자에 추가
  });

  void _drawTiledBackground(Canvas canvas, Size size) {
    if (backgroundImage == null) {
      // 이미지가 아직 로드되지 않았거나 실패한 경우, 단색 배경 또는 아무것도 그리지 않음
      canvas.drawColor(Colors.green[900]!, BlendMode.srcOver); // 예: 이전 배경색으로 대체
      return;
    }

    final double imageWidth = backgroundImage!.width.toDouble();
    final double imageHeight = backgroundImage!.height.toDouble();

    if (imageWidth <= 0 || imageHeight <= 0) return; // 유효하지 않은 이미지 크기

    final double cameraX = gameState.cameraPosition.dx;
    final double cameraY = gameState.cameraPosition.dy;

    // 화면에 보일 첫 번째 타일의 시작 월드 좌표 계산
    final double startWorldX = (cameraX / imageWidth).floor() * imageWidth;
    final double startWorldY = (cameraY / imageHeight).floor() * imageHeight;

    // 화면을 덮기 위해 필요한 타일 개수 계산 (여유분으로 +1 또는 +2)
    final int numTilesX = (size.width / imageWidth).ceil() + 2;
    final int numTilesY = (size.height / imageHeight).ceil() + 2;

    final paint = Paint();

    for (int iy = 0; iy < numTilesY; iy++) {
      for (int ix = 0; ix < numTilesX; ix++) {
        final double currentWorldX = startWorldX + ix * imageWidth;
        final double currentWorldY = startWorldY + iy * imageHeight;

        // 현재 타일의 화면상 위치 계산
        final double screenX = currentWorldX - cameraX;
        final double screenY = currentWorldY - cameraY;

        // 화면 범위를 벗어나는 타일은 그리지 않음 (약간의 최적화)
        if (screenX > size.width || screenX + imageWidth < 0 ||
            screenY > size.height || screenY + imageHeight < 0) {
          continue;
        }

        canvas.drawImage(backgroundImage!, Offset(screenX, screenY), paint);
      }
    }
  }


  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1.0;
    const double gridSize = 50.0;
    // Grid 그리기 로직은 카메라 위치를 고려해야 함
    double startGridWorldX = (gameState.cameraPosition.dx / gridSize).floor() * gridSize;
    double endGridWorldX = ((gameState.cameraPosition.dx + size.width) / gridSize).ceil() * gridSize;

    for (double worldX = startGridWorldX; worldX <= endGridWorldX; worldX += gridSize) {
      final screenX = worldX - gameState.cameraPosition.dx;
      canvas.drawLine(Offset(screenX, 0), Offset(screenX, size.height), paint);
    }

    double startGridWorldY = (gameState.cameraPosition.dy / gridSize).floor() * gridSize;
    double endGridWorldY = ((gameState.cameraPosition.dy + size.height) / gridSize).ceil() * gridSize;

    for (double worldY = startGridWorldY; worldY <= endGridWorldY; worldY += gridSize) {
      final screenY = worldY - gameState.cameraPosition.dy;
      // X축 라인과 Y축 라인의 canvas.drawLine 두번째 Offset 파라미터 수정
      canvas.drawLine(Offset(0, screenY), Offset(size.width, screenY), paint);
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
    _drawTiledBackground(canvas, size); // 배경을 가장 먼저 그림
    // _drawGrid(canvas, size);
    _drawCrystals(canvas, size);
    _drawEnemies(canvas, size);
    _drawProjectiles(canvas, size);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    // backgroundImage가 변경되었거나 gameState가 변경되었을 때 다시 그리도록 수정
    return oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.gameState != gameState ||
        true; // 또는 항상 true로 두어 매 프레임 다시 그리도록 할 수 있음 (게임의 경우 일반적)
  }
}