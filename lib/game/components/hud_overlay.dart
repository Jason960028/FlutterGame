import 'package:flutter/material.dart';

class HudOverlay extends StatelessWidget {
  final int currentLevel;
  final double currentExp; // 현재 경험치 (0.0 ~ 1.0 사이의 비율)
  final int nextLevelExp; // 다음 레벨까지 필요한 총 경험치 (표시용)
  final int elapsedTimeInSeconds; // 게임 진행 시간 (초)

  const HudOverlay({
    super.key,
    required this.currentLevel,
    required this.currentExp,
    required this.nextLevelExp,
    required this.elapsedTimeInSeconds,
  });

  // 초를 MM:SS 형식의 문자열로 변환하는 함수
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // 화면 상단에 안전 영역(Safe Area)을 고려하여 패딩을 줍니다.
    return Positioned(
      top: MediaQuery.of(context).padding.top, // 상태 표시줄 바로 아래부터 시작
      left: 0, // 화면 왼쪽 끝부터 시작
      right: 0, // 화면 오른쪽 끝까지 채움
      child: Padding( // 내부 여백을 위해 Padding 추가
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Column 내용만큼만 높이 차지
          children: [
            // EXP 바 컨테이너
            Container(
              height: 22, // 높이 약간 증가
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6), // 배경색 명확하게
                borderRadius: BorderRadius.circular(11), // 테두리 반지름에 맞춤
                border: Border.all(color: Colors.grey[700]!, width: 2),
              ),
              child: ClipRRect( // 내부 바가 둥근 모서리를 넘지 않도록 ClipRRect 사용
                borderRadius: BorderRadius.circular(9), // 내부 컨테이너의 radius
                child: Stack(
                  children: [
                    // 배경색 (항상 꽉 차도록)
                    Container(color: Colors.grey[800]),
                    // 실제 경험치 바 (애니메이션 효과를 위해 AnimatedFractionallySizedBox 사용 가능)
                    FractionallySizedBox(
                      widthFactor: currentExp.clamp(0.0, 1.0), // 0.0과 1.0 사이 값으로 제한
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient( // 그라데이션으로 좀 더 보기 좋게
                            colors: [Colors.lightBlueAccent[100]!, Colors.blueAccent[400]!],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    // EXP 텍스트 (중앙 정렬, 선택 사항)
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'EXP: ${(currentExp * 100).toStringAsFixed(0)}%', // 퍼센트로 표시
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            shadows: [
                              Shadow(blurRadius: 1, color: Colors.black.withOpacity(0.8))
                            ]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 레벨 및 시간 표시를 위한 Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 끝으로 정렬
              children: [
                // 레벨 표시
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level: $currentLevel',
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black.withOpacity(0.7),
                          offset: const Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                ),
                // 진행 시간 표시
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(elapsedTimeInSeconds), // MM:SS 형식으로 표시
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()], // 숫자 너비 고정
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black.withOpacity(0.7),
                          offset: const Offset(1.0, 1.0),
                        ),
                      ],
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
