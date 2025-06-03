import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'char_select_screen.dart'; // SystemUiOverlayStyle을 위해 추가

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // HomeScreen 위젯을 빌드합니다.
    // Scaffold는 기본적인 Material Design 시각적 레이아웃 구조를 구현합니다.
    return AnnotatedRegion<SystemUiOverlayStyle>( // AnnotatedRegion으로 감싸서 시스템 UI 스타일을 적용
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light, // 상태 표시줄 아이콘을 밝게 (흰색)
        statusBarBrightness: Brightness.dark, // iOS에서 상태 표시줄 배경과의 대비 (어두운 배경용)
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity, // 컨테이너 너비를 최대로 설정
          height: double.infinity, // 컨테이너 높이를 최대로 설정
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[850]!, Colors.grey[900]!], // 배경 그라데이션
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          // SafeArea를 사용하여 시스템 UI에 의해 콘텐츠가 가려지지 않도록 합니다.
          child: SafeArea(
            // 내용을 중앙에 배치하기 위해 Center 위젯을 사용합니다.
            child: Center(
              // 세로 방향으로 위젯들을 배치하기 위해 Column을 사용합니다.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 자식들을 세로축 중앙에 정렬
                children: <Widget>[
                  // 게임 제목을 표시하는 Text 위젯
                  const Text(
                    'Life of Shooter', // 게임 제목
                    style: TextStyle(
                      fontSize: 48.0, // 글자 크기
                      fontWeight: FontWeight.bold, // 글자 굵기
                      color: Colors.white, // 글자 색상
                      shadows: [ // 텍스트 그림자 효과
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black54,
                          offset: Offset(5.0, 5.0),
                        ),
                      ],
                    ),
                  ),
                  // 제목과 버튼 사이의 간격을 주기 위한 SizedBox
                  const SizedBox(height: 60.0),
                  // PLAY 버튼을 표시하는 ElevatedButton 위젯
                  ElevatedButton(
                    // 버튼을 눌렀을 때 실행될 동작 (현재는 비어 있음)
                    onPressed: () {
                      print('PLAY button pressed! Navigating to CharSelectScreen...');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CharSelectScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, // 버튼 배경색
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20), // 버튼 내부 패딩
                      textStyle: const TextStyle(
                        fontSize: 24, // 버튼 텍스트 크기
                        fontWeight: FontWeight.bold, // 버튼 텍스트 굵기
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // 버튼 모서리 둥글게
                      ),
                      elevation: 5, // 버튼 그림자
                    ),
                    child: const Text(
                      'PLAY', // 버튼 텍스트
                      style: TextStyle(color: Colors.white), // 버튼 텍스트 색상
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