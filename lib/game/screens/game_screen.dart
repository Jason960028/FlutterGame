import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../components/hud_overlay.dart';
import '../components/game_painter.dart';
import '../managers/game_state.dart';
import 'game_over_overlay.dart';
import '../managers/knight_state.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import for GIF



class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameState gameState;

  Offset _screenCenterPosition = Offset.zero;
  Offset? _joystickAnchorForUI;
  Offset? _currentDragForUI;

  final double _movementSpeedInPixelsPerSecond = 150.0;
  bool _isInitialized = false;

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  bool _isGameOver = false;

  // Add character image dimensions
  final double _characterImageWidth = 100.0; // Adjust as needed
  final double _characterImageHeight = 100.0; // Adjust as needed

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    _ticker = createTicker(_gameLoop);
    if (!_isGameOver && !_ticker!.isTicking) {
      _lastTick = Duration.zero;
      _ticker!.start();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      _screenCenterPosition = Offset(screenSize.width / 2, screenSize.height / 2);
      gameState.cameraPosition = gameState.worldCharacterPosition - _screenCenterPosition;
      _isInitialized = true;
    }
  }

  String _formatDurationForGameOver(double totalSeconds) {
    final duration = Duration(seconds: totalSeconds.toInt());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getCharacterAsset() {
    switch (gameState.playerState) {
      case KnightState.attack:
        return 'assets/knight/knight_attack.gif';
      case KnightState.death:
        return 'assets/knight/knight_death.gif';
      case KnightState.hurt:
        return 'assets/knight/knight_hurt.gif';
      case KnightState.idle:
      default:
        if (gameState.currentDirection == Offset.zero) {
          return 'assets/knight/knight_idle.gif';
        } else {
          return 'assets/knight/knight_run.gif';
        }
    }
  }

  void _handlePlayerDeathInGameScreen() {
    if (_isGameOver) return; // 이미 게임 오버 처리 중이면 중복 실행 방지

    setState(() {
      _isGameOver = true;
    });
    _ticker?.stop();

    // GameOverScreen으로 이동하면서 현재 게임 결과 전달
    // Navigator.of(context).pushReplacement( // 현재 화면을 GameOverScreen으로 대체
    //   MaterialPageRoute(
    //     builder: (context) => GameOverScreen(
    //       finalLevel: gameState.currentLevel,
    //       elapsedTime: _formatDurationForGameOver(gameState.totalElapsedTimeSeconds),
    //     ),
    //   ),
    // );
  }


  void _gameLoop(Duration elapsed) {
    if (_isGameOver) return;

    final Duration deltaTimeDuration = elapsed - _lastTick;
    _lastTick = elapsed;
    final double deltaTime = deltaTimeDuration.inMicroseconds / Duration.microsecondsPerSecond;

    gameState.totalElapsedTimeSeconds += deltaTime;
    gameState.moveCharacter(deltaTime, _movementSpeedInPixelsPerSecond);
    gameState.updateEnemySpawns(deltaTime);
    gameState.moveEnemies(deltaTime);
    gameState.updatePlayerAttack(deltaTime);
    gameState.updateStateTimers(deltaTime);
    gameState.moveProjectiles(deltaTime);

    if (_isInitialized) {
      gameState.checkCollisions();
      if (gameState.isGameOver && !_isGameOver) {
        _handlePlayerDeathInGameScreen();
      }
    }

    if (mounted && !_isGameOver) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlAreaStartY = MediaQuery.of(context).size.height / 3;

    // _isGameOver 상태는 _handlePlayerDeathInGameScreen에서 화면 전환으로 처리하므로,
    // build 메소드에서 _isGameOver에 따른 분기 처리는 제거해도 됩니다.
    // 만약 GameOverScreen으로 즉시 전환되지 않고 GameScreen 위에 오버레이 형태로
    // 게임 오버 UI를 표시하고 싶다면 이 분기 로직이 필요할 수 있습니다.
    // 현재는 pushReplacement로 화면을 완전히 전환합니다.

    return Scaffold(
      backgroundColor: Colors.green[900],
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              if (_isGameOver) return;
              if (details.localPosition.dy >= controlAreaStartY) {
                Offset newDirection = Offset.zero;
                gameState.updateJoystick(details.localPosition, details.localPosition, newDirection);
                _joystickAnchorForUI = details.localPosition;
                _currentDragForUI = details.localPosition;
                if(mounted) setState(() {});
              } else {
                gameState.updateJoystick(null, null, Offset.zero);
                _joystickAnchorForUI = null;
                _currentDragForUI = null;
                if(mounted) setState(() {});
              }
            },
            onPanUpdate: (details) {
              if (_isGameOver) return;
              if (gameState.joystickAnchor != null && _isInitialized) {
                final delta = details.localPosition - gameState.joystickAnchor!;
                Offset newDirection;
                if (delta.distanceSquared > 0) {
                  newDirection = delta / delta.distance;
                } else {
                  newDirection = Offset.zero;
                }
                gameState.updateJoystick(gameState.joystickAnchor, details.localPosition, newDirection);
                _currentDragForUI = details.localPosition;
                if(mounted) setState(() {});
              }
            },
            onPanEnd: (details) {
              if (_isGameOver) return;
              gameState.updateJoystick(null, null, Offset.zero);
              _joystickAnchorForUI = null;
              _currentDragForUI = null;
              if(mounted) setState(() {});
            },
            child: CustomPaint(
              painter: GamePainter(
                gameState: gameState,
                screenCenterPosition: _screenCenterPosition,
              ),
              size: Size.infinite,
            ),
          ),
          Positioned(
            left: _screenCenterPosition.dx - _characterImageWidth / 2,
            top: _screenCenterPosition.dy - _characterImageHeight / 2,
            width: _characterImageWidth,
            height: _characterImageHeight,
            child: AnimatedSwitcher( // Use AnimatedSwitcher for smooth transitions if character state changes later
              duration: const Duration(milliseconds: 100),
              child: Image.asset(
                _getCharacterAsset(),
                key: ValueKey('${gameState.playerState}_${gameState.currentDirection}'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (_isInitialized && !_isGameOver)
            HudOverlay(
              currentLevel: gameState.currentLevel,
              currentExp: gameState.expBarPercentage,
              nextLevelExp: gameState.expToNextLevel.toInt(),
              elapsedTimeInSeconds: gameState.totalElapsedTimeSeconds.toInt(),
              playerCurrentHealth: gameState.playerCurrentHealth,
              playerMaxHealth: gameState.playerMaxHealth,
            ),
          if (_isGameOver)
            GameOverOverlay(
              finalLevel: gameState.currentLevel,
              elapsedTime: _formatDurationForGameOver(
                gameState.totalElapsedTimeSeconds,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    super.dispose();
  }
}
