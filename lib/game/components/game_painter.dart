import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../managers/game_state.dart';

// 게임 요소를 그리는 CustomPainter 클래스
class GamePainter extends CustomPainter {
  final Offset cameraPosition;
  final Offset screenCenterPosition;
  final List<ExperienceCrystal> crystals; // 크리스탈 리스트 받기

  GamePainter({
    required this.cameraPosition,
    required this.screenCenterPosition,
    required this.crystals,
  });

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1.0;
    const double gridSize = 50.0;
    double startWorldX = (cameraPosition.dx / gridSize).floor() * gridSize;
    double endWorldX = ((cameraPosition.dx + size.width) / gridSize).ceil() * gridSize;
    for (double worldX = startWorldX; worldX <= endWorldX; worldX += gridSize) {
      final screenX = worldX - cameraPosition.dx;
      canvas.drawLine(Offset(screenX, 0), Offset(screenX, size.height), paint);
    }
    double startWorldY = (cameraPosition.dy / gridSize).floor() * gridSize;
    double endWorldY = ((cameraPosition.dy + size.height) / gridSize).ceil() * gridSize;
    for (double worldY = startWorldY; worldY <= endWorldY; worldY += gridSize) {
      final screenY = worldY - cameraPosition.dy;
      canvas.drawLine(Offset(0, screenY), Offset(size.width, screenY), paint);
    }
  }

  void _drawCharacter(Canvas canvas, Size size) {
    final characterPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    final path = Path();
    const double charHeight = 30.0;
    const double charWidth = 20.0;
    path.moveTo(screenCenterPosition.dx, screenCenterPosition.dy - charHeight / 2);
    path.lineTo(screenCenterPosition.dx - charWidth / 2, screenCenterPosition.dy + charHeight / 2);
    path.lineTo(screenCenterPosition.dx + charWidth / 2, screenCenterPosition.dy + charHeight / 2);
    path.close();
    canvas.drawPath(path, characterPaint);
  }

  void _drawCrystals(Canvas canvas, Size size) {
    final crystalPaint = Paint()
      ..color = Colors.purpleAccent // 크리스탈 색상
      ..style = PaintingStyle.fill;

    for (var crystal in crystals) {
      // GameState에서 이미 수집된 크리스탈은 리스트에서 제거되므로 isCollected 플래그 불필요
      final screenPosition = crystal.worldPosition - cameraPosition;

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

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawCrystals(canvas, size);
    _drawCharacter(canvas, size);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return oldDelegate.cameraPosition != cameraPosition ||
        oldDelegate.screenCenterPosition != screenCenterPosition ||
        !listEquals(oldDelegate.crystals, crystals);
  }

  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    // ExperienceCrystal 객체는 ID로 비교하거나, 더 간단하게는 참조로 비교 (리스트가 새로 생성되면 항상 다름)
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
