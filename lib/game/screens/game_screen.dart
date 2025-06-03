import 'package:flutter/material.dart';
import 'dart:math' as math; // math.Random은 GameState로 이동
import 'package:flutter/scheduler.dart';
import '../components/game_painter.dart';
import '../components/hud_overlay.dart';
import '../managers/game_state.dart';


class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameState gameState; // GameState 인스턴스

  // UI 관련 상태 변수들은 _GameScreenState에 남겨둘 수 있음
  Offset _screenCenterPosition = Offset.zero;
  Offset? _joystickAnchorForUI; // UI 표시용 조이스틱 앵커 (필요하다면)
  Offset? _currentDragForUI; // UI 표시용 현재 드래그 위치 (필요하다면)


  // 설정값 (const 또는 final로 관리)
  final double _movementSpeedInPixelsPerSecond = 150.0;
  bool _isInitialized = false;

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    gameState = GameState(); // GameState 인스턴스 생성
    _ticker = createTicker(_gameLoop);
    if (!_ticker!.isTicking) {
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
      // GameState의 카메라 위치는 캐릭터 위치와 화면 중앙을 기반으로 초기화 필요
      gameState.cameraPosition = gameState.worldCharacterPosition - _screenCenterPosition;
      _isInitialized = true;
    }
  }

  void _gameLoop(Duration elapsed) {
    final Duration deltaTimeDuration = elapsed - _lastTick;
    _lastTick = elapsed;
    final double deltaTime = deltaTimeDuration.inMicroseconds / Duration.microsecondsPerSecond;

    gameState.totalElapsedTimeSeconds += deltaTime;

    // 캐릭터 이동 로직을 GameState의 메소드로 호출
    gameState.moveCharacter(deltaTime, _movementSpeedInPixelsPerSecond);

    if (_isInitialized) {
      // 크리스탈 충돌 체크 로직을 GameState의 메소드로 호출
      gameState.checkCrystalCollisions();
    }

    if (mounted) {
      setState(() {}); // GameState 내부 변경에 따른 UI 갱신
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final controlAreaStartY = screenSize.height / 3;

    return Scaffold(
      backgroundColor: Colors.green[800],
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              if (details.localPosition.dy >= controlAreaStartY) {
                // 조이스틱 관련 상태는 GameState의 메소드를 통해 업데이트
                // 또는 _GameScreenState에서 UI용 조이스틱 상태를 별도로 관리하고,
                // 이동 방향만 GameState에 전달할 수도 있음.
                // 여기서는 GameState의 updateJoystick을 직접 호출하는 방식으로 단순화.
                Offset newDirection = Offset.zero; // 시작 시 방향 초기화
                gameState.updateJoystick(details.localPosition, details.localPosition, newDirection);
                _joystickAnchorForUI = details.localPosition; // UI 표시용
                _currentDragForUI = details.localPosition; // UI 표시용
                setState(() {}); // UI 상태 변경 시에도 setState 필요할 수 있음
              } else {
                gameState.updateJoystick(null, null, Offset.zero);
                _joystickAnchorForUI = null;
                _currentDragForUI = null;
                setState(() {});
              }
            },
            onPanUpdate: (details) {
              if (gameState.joystickAnchor != null && _isInitialized) {
                final delta = details.localPosition - gameState.joystickAnchor!;
                Offset newDirection;
                if (delta.distanceSquared > 0) {
                  newDirection = delta / delta.distance;
                } else {
                  newDirection = Offset.zero;
                }
                gameState.updateJoystick(gameState.joystickAnchor, details.localPosition, newDirection);
                _currentDragForUI = details.localPosition; // UI 표시용
                setState(() {});
              }
            },
            onPanEnd: (details) {
              gameState.updateJoystick(null, null, Offset.zero);
              _joystickAnchorForUI = null;
              _currentDragForUI = null;
              setState(() {});
            },
            child: CustomPaint(
              painter: GamePainter(
                // GameState에서 직접 값 가져오기
                cameraPosition: gameState.cameraPosition,
                screenCenterPosition: _screenCenterPosition, // 이건 GameScreenState에서 관리
                crystals: gameState.crystals,
              ),
              size: Size.infinite,
            ),
          ),
          if (_isInitialized)
            HudOverlay(
              currentLevel: gameState.currentLevel,
              currentExp: gameState.expBarPercentage,
              nextLevelExp: gameState.expToNextLevel.toInt(),
              elapsedTimeInSeconds: gameState.totalElapsedTimeSeconds.toInt(),
            ),
          // (선택 사항) UI 전용 조이스틱 시각화 (GamePainter와 별개)
          // if (_joystickAnchorForUI != null && _currentDragForUI != null)
          //   Positioned.fill(
          //     child: CustomPaint(
          //       painter: JoystickPainter(_joystickAnchorForUI!, _currentDragForUI!),
          //     ),
          //   )
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

// (선택 사항) UI 전용 조이스틱을 화면에 그리고 싶다면 별도의 Painter 클래스
// class JoystickPainter extends CustomPainter {
//   final Offset anchor;
//   final Offset currentDrag;
//   JoystickPainter(this.anchor, this.currentDrag);
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.white.withOpacity(0.3);
//     canvas.drawCircle(anchor, 60, paint..style = PaintingStyle.stroke..strokeWidth = 2);
//     canvas.drawCircle(anchor, 50, paint..style = PaintingStyle.fill);
//     canvas.drawCircle(currentDrag, 25, paint..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.fill);
//   }
//   @override
//   bool shouldRepaint(covariant JoystickPainter oldDelegate) => true;
// }
