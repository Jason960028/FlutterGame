import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';

class GameOverScreen extends StatelessWidget {
  final int finalLevel;
  final String elapsedTime;

  const GameOverScreen({
    super.key,
    required this.finalLevel,
    required this.elapsedTime,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[850]!, Colors.grey[900]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'GAME OVER', // 메인 텍스트 변경
                    style: TextStyle(
                      fontSize: 64.0, // 폰트 크기 증가
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent, // 색상 변경
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(5.0, 5.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  Text(
                    'Level: $finalLevel',
                    style: const TextStyle(
                      fontSize: 28.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Time: $elapsedTime',
                    style: const TextStyle(
                      fontSize: 24.0,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 60.0),
                  ElevatedButton(
                    onPressed: () {
                      // 홈 화면으로 네비게이션 (모든 이전 라우트 제거)
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                            (Route<dynamic> route) => false, // 모든 이전 라우트를 제거하는 조건
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[600], // 버튼 색상 변경
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Back to Menu', // 버튼 텍스트 변경
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
