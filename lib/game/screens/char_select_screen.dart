import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_screen.dart'; // SystemUiOverlayStyle을 위해 추가

// 캐릭터 정보를 담을 간단한 클래스
class Character {
  final String id;
  final String name;
  final IconData icon;
  final String playStyle;
  final String weapon;

  Character({
    required this.id,
    required this.name,
    required this.icon,
    required this.playStyle,
    required this.weapon,
  });
}

class CharSelectScreen extends StatefulWidget {
  const CharSelectScreen({super.key});

  @override
  State<CharSelectScreen> createState() => _CharSelectScreenState();
}

class _CharSelectScreenState extends State<CharSelectScreen> {
  // 샘플 캐릭터 데이터
  final List<Character> characters = [
    Character(
      id: 'char1',
      name: '용감한 기사',
      icon: Icons.shield,
      playStyle: '근접전에 능하며 강력한 방어력을 자랑합니다. 초보자에게 추천합니다.',
      weapon: '롱소드 - 넓은 범위를 공격할 수 있는 기본 무기입니다.',
    ),
    Character(
      id: 'char2',
      name: '신비한 마법사',
      icon: Icons.auto_stories, // 책 아이콘 (마법서)
      playStyle: '원거리에서 강력한 마법을 사용하지만 체력이 약합니다. 컨트롤이 중요합니다.',
      weapon: '파이어볼 - 단일 대상에게 강력한 화염 피해를 입힙니다.',
    ),
    Character(
      id: 'char3',
      name: '민첩한 궁수',
      icon: Icons.radar, // 조준점 아이콘 (활)
      playStyle: '빠른 이동 속도와 원거리 공격으로 적을 교란합니다. 치고 빠지는 전략에 능합니다.',
      weapon: '장궁 - 사거리가 길고 빠른 연사가 가능한 활입니다.',
    ),
  ];

  Character? selectedCharacter; // 선택된 캐릭터

  @override
  void initState() {
    super.initState();
    // 초기 선택 캐릭터 (첫 번째 캐릭터)
    if (characters.isNotEmpty) {
      selectedCharacter = characters[0];
    }
  }

  void _selectCharacter(Character character) {
    setState(() {
      selectedCharacter = character;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[850], // 홈 화면과 유사한 배경색
        appBar: AppBar(
          title: const Text(
            '캐릭터 선택',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent, // AppBar 배경 투명
          elevation: 0, // AppBar 그림자 제거
          iconTheme: const IconThemeData(color: Colors.white), // 뒤로가기 버튼 흰색
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 캐릭터 선택 부분
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: characters.map((char) {
                    bool isSelected = selectedCharacter?.id == char.id;
                    return GestureDetector(
                      onTap: () => _selectCharacter(char),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12.0),
                          border: isSelected
                              ? Border.all(color: Colors.redAccent, width: 3.0)
                              : Border.all(color: Colors.transparent, width: 3.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(char.icon, size: 60.0, color: Colors.white),
                            const SizedBox(height: 8.0),
                            Text(
                              char.name,
                              style: const TextStyle(color: Colors.white, fontSize: 14.0),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30.0),

                // 선택된 캐릭터 정보 표시
                if (selectedCharacter != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView( // 내용이 길어질 경우 스크롤 가능하도록
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedCharacter!.name,
                              style: const TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              '플레이 스타일:',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent[100],
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              selectedCharacter!.playStyle,
                              style: const TextStyle(fontSize: 16.0, color: Colors.white70, height: 1.5),
                            ),
                            const SizedBox(height: 20.0),
                            Text(
                              '주요 무기:',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent[100],
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              selectedCharacter!.weapon,
                              style: const TextStyle(fontSize: 16.0, color: Colors.white70, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (selectedCharacter == null)
                  const Expanded(
                    child: Center(
                      child: Text(
                        '캐릭터를 선택해주세요.',
                        style: TextStyle(color: Colors.white70, fontSize: 18.0),
                      ),
                    ),
                  ),

                const SizedBox(height: 30.0),

                // GO 버튼
                ElevatedButton(
                  onPressed: selectedCharacter != null
                      ? () {
                    print('${selectedCharacter!.name}(으)로 게임 시작!');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GameScreen()), // GameScreen으로 이동
                    );
                  }
                      : null, // 선택된 캐릭터가 없으면 버튼 비활성화
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCharacter != null ? Colors.redAccent : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'GO!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
