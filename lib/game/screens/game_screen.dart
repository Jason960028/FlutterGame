import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../my_game.dart';
import 'game_over_overlay.dart';
import '../components/hud_overlay.dart';
import 'level_up_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MyGame _myGame;

  @override
  void initState() {
    super.initState();
    _myGame = MyGame();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<MyGame>(
      game: _myGame,
      overlayBuilderMap: {
        'GameOverOverlay': (context, game) {
          return AnimatedBuilder(
            animation: game,
            builder: (context, child) {
              return GameOverOverlay(
                finalLevel: game.currentLevel,
                elapsedTime: game.formattedElapsedTime,
              );
            },
          );
        },
        'HudOverlay': (context, game) {
          return AnimatedBuilder(
            animation: game,
            builder: (context, child) {
              // MyGame의 onLoad에서 player가 초기화된 후 HudOverlay가 추가되므로,
              // 이 시점에는 game.player가 null이 아니라고 가정할 수 있습니다.
              // 좀 더 방어적으로 하려면 game.player.isMounted 등을 체크할 수 있습니다.
              if (!game.player.isMounted && !game.isGameOver) {
                return const Center(child: CircularProgressIndicator());
              }
              return HudOverlay(
                currentLevel: game.currentLevel,
                currentExp: game.expBarPercentage,
                nextLevelExp: game.expToNextLevel.toInt(),
                elapsedTimeInSeconds: game.totalElapsedTimeSeconds.toInt(),
                playerCurrentHealth: game.player.currentHealth,
                playerMaxHealth: game.player.maxHealth,
              );
            },
          );
        },
        'LevelUpOverlay': (context, game) { // 레벨업 오버레이 추가
          return LevelUpOverlay(game: game);
        },
      },
      // initialActiveOverlays는 MyGame.onLoad에서 HudOverlay를 추가하므로 여기서 제거
    );
  }
}