import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;

class HudOverlay extends StatelessWidget {
  final int currentLevel;
  final double currentExp; // 현재 경험치 (0.0 ~ 1.0 사이의 비율)
  final int nextLevelExp; // 다음 레벨까지 필요한 총 경험치 (표시용)
  final int elapsedTimeInSeconds; // 게임 진행 시간 (초)
  final double playerCurrentHealth;
  final double playerMaxHealth;

  const HudOverlay({
    super.key,
    required this.currentLevel,
    required this.currentExp,
    required this.nextLevelExp,
    required this.elapsedTimeInSeconds,
    required this.playerCurrentHealth,
    required this.playerMaxHealth,
  });

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    double healthPercentage = 0.0;
    if (playerMaxHealth > 0) {
      healthPercentage = (playerCurrentHealth / playerMaxHealth).clamp(0.0, 1.0);
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // HP 바 컨테이너
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[700]!, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.5),
                child: Stack(
                  children: [
                    Container(color: Colors.grey[800]), // 배경
                    FractionallySizedBox(
                      widthFactor: healthPercentage,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[400]!, Colors.red[700]!],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'HP: ${playerCurrentHealth.toStringAsFixed(0)} / ${playerMaxHealth.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11,
                            shadows: [Shadow(blurRadius: 1, color: Colors.black.withOpacity(0.8))]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            // EXP 바 컨테이너 (기존과 동일)
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.grey[700]!, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  children: [
                    Container(color: Colors.grey[800]),
                    FractionallySizedBox(
                      widthFactor: currentExp.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.lightBlueAccent[100]!, Colors.blueAccent[400]!],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'EXP: ${(currentExp * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12,
                            shadows: [Shadow(blurRadius: 1, color: Colors.black.withOpacity(0.8))]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 레벨 및 시간 표시 (기존과 동일)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level: $currentLevel',
                    style: TextStyle(
                      color: Colors.yellowAccent, fontSize: 18, fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.7), offset: const Offset(1.0, 1.0))],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(elapsedTimeInSeconds),
                    style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: [Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.7), offset: const Offset(1.0, 1.0))],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
