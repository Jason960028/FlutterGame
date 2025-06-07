// lib/main.dart
import 'package:flutter/material.dart';
import 'game/screens/home_screen.dart'; // HomeScreen 임포트

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life of Shooter',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // 앱의 기본 색상 견본
        visualDensity: VisualDensity.adaptivePlatformDensity, // 다양한 플랫폼에 적응하는 시각적 밀도
      ),
      home: const HomeScreen(), // 앱의 첫 화면으로 HomeScreen을 설정
      debugShowCheckedModeBanner: false, // 디버그 배너 숨기기
    );
  }
}