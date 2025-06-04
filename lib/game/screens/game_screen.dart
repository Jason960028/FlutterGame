import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle; // ByteData, rootBundle 추가
import 'dart:ui' as ui; // ui.Image 사용을 위해 추가

import '../components/hud_overlay.dart';
import '../components/game_painter.dart';
import '../managers/game_state.dart';
import 'game_over_overlay.dart';
import '../managers/states.dart';

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

  final double _characterImageWidth = 100.0;
  final double _characterImageHeight = 100.0;

  ui.Image? _backgroundImage; // 로드된 배경 이미지를 저장할 변수
  bool _isBackgroundImageLoading = true; // 배경 이미지 로딩 상태

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    _loadBackgroundImage(); // initState에서 배경 이미지 로딩 시작
    _ticker = createTicker(_gameLoop);
    if (!_isGameOver && !_ticker!.isTicking) {
      _lastTick = Duration.zero;
      _ticker!.start();
    }
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/background/background.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _backgroundImage = frame.image;
          _isBackgroundImageLoading = false;
        });
      }
    } catch (e) {
      print("배경 이미지 로딩 실패: $e");
      if (mounted) {
        setState(() {
          _isBackgroundImageLoading = false; // 실패 시에도 로딩 상태 변경
        });
      }
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
    if (_isGameOver) return;

    setState(() {
      _isGameOver = true;
    });
    _ticker?.stop();
  }


  void _gameLoop(Duration elapsed) {
    if (_isGameOver || _isBackgroundImageLoading) return; // 이미지 로딩 중에는 게임 루프 미실행

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

    if (_isBackgroundImageLoading) {
      return Scaffold( // 이미지 로딩 중일 때 로딩 인디케이터 표시
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          // Positioned.fill(...) 제거됨
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
            child: CustomPaint( // CustomPaint 위젯에 로드된 이미지 전달
              painter: GamePainter(
                gameState: gameState,
                screenCenterPosition: _screenCenterPosition,
                backgroundImage: _backgroundImage, // 배경 이미지 전달
              ),
              size: Size.infinite,
            ),
          ),
          Positioned(
            left: _screenCenterPosition.dx - _characterImageWidth / 2,
            top: _screenCenterPosition.dy - _characterImageHeight / 2,
            width: _characterImageWidth,
            height: _characterImageHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(gameState.isFacingRight ? 1.0 : -1.0, 1.0),
                child: Image.asset(
                  _getCharacterAsset(),
                  key: ValueKey(_getCharacterAsset()),
                  fit: BoxFit.contain,
                ),
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
    _backgroundImage?.dispose(); // 이미지 객체 dispose
    super.dispose();
  }
}