import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart'; // Ticker를 위해 추가

// 게임 화면 위젯
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin { // TickerProvider를 위해 mixin 추가
  // 캐릭터의 논리적 월드 위치
  Offset _worldCharacterPosition = Offset.zero; // 월드 좌표계에서의 캐릭터 위치
  // 카메라의 현재 위치 (월드 좌표계에서 화면 좌상단에 해당하는 지점)
  Offset _cameraPosition = Offset.zero;
  // 화면 중앙 위치 (캐릭터가 시각적으로 표시될 위치)
  Offset _screenCenterPosition = Offset.zero;

  // 조이스틱의 시작 터치 위치 (드래그 시작점)
  Offset? _joystickAnchor;
  // 현재 드래그 위치
  Offset? _currentDrag;
  // 현재 캐릭터 이동 방향 (정규화됨)
  Offset _currentDirection = Offset.zero;

  // 캐릭터의 초당 이동 속도
  final double _movementSpeedInPixelsPerSecond = 150.0;
  bool _isInitialized = false;

  Ticker? _ticker; // 게임 루프를 위한 Ticker
  Duration _lastTick = Duration.zero; // 마지막 틱 시간

  @override
  void initState() {
    super.initState();
    // Ticker 초기화 (아직 시작은 안 함)
    _ticker = createTicker(_gameLoop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면 크기가 결정된 후 초기화 수행
    if (!_isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      _screenCenterPosition = Offset(screenSize.width / 2, screenSize.height / 2);
      // 캐릭터의 초기 월드 위치를 화면 중앙에 대응하는 월드 좌표로 설정
      // 이 예제에서는 월드 (0,0)에서 시작하도록 변경하여 카메라와 캐릭터 초기 위치를 명확히 함
      _worldCharacterPosition = Offset.zero;
      // 초기 카메라 위치 설정 (캐릭터가 화면 중앙에 오도록 하려면, 월드 (0,0)의 캐릭터는 화면 중앙에 와야 함)
      // 즉, 카메라의 좌상단은 _worldCharacterPosition - _screenCenterPosition 이 되어야 함.
      _cameraPosition = _worldCharacterPosition - _screenCenterPosition;
      _isInitialized = true;
    }
  }

  void _gameLoop(Duration elapsed) {
    // deltaTime 계산 (이번 틱과 저번 틱 사이의 시간)
    final Duration deltaTime = elapsed - _lastTick;
    _lastTick = elapsed;

    if (_currentDirection != Offset.zero && _isInitialized) {
      final double deltaSeconds = deltaTime.inMicroseconds / Duration.microsecondsPerSecond;
      final double moveAmount = _movementSpeedInPixelsPerSecond * deltaSeconds;
      final Offset moveDelta = _currentDirection * moveAmount;

      setState(() {
        _worldCharacterPosition += moveDelta;
        _cameraPosition += moveDelta; // 캐릭터 이동에 따라 맵이 반대로 움직이는 효과
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final controlAreaStartY = screenSize.height / 3;

    return Scaffold(
      backgroundColor: Colors.green[800], // 맵 배경색 (예: 잔디)
      body: GestureDetector(
        onPanStart: (details) {
          if (details.localPosition.dy >= controlAreaStartY) {
            setState(() {
              _joystickAnchor = details.localPosition;
              _currentDrag = details.localPosition;
              _currentDirection = Offset.zero; // 시작 시 방향 초기화
              _lastTick = Duration.zero; // Ticker가 새로 시작될 때 lastTick 초기화
              if (!_ticker!.isTicking) {
                _ticker!.start();
              }
            });
          } else {
            _joystickAnchor = null;
            _currentDrag = null;
            _currentDirection = Offset.zero;
            if (_ticker!.isTicking) {
              // _ticker!.stop(); // 컨트롤 영역 밖에서 시작하면 멈출 필요는 없음. onPanEnd에서 처리.
            }
          }
        },
        onPanUpdate: (details) {
          if (_joystickAnchor != null && _isInitialized) {
            setState(() {
              _currentDrag = details.localPosition;
              final delta = _currentDrag! - _joystickAnchor!;

              if (delta.distanceSquared > 0) {
                _currentDirection = delta/delta.distance; // 정규화된 방향 저장
              } else {
                _currentDirection = Offset.zero; // 움직임이 없으면 방향도 없음
              }
              // Ticker는 onPanStart에서 이미 시작되었거나 계속 Ticking 상태임
            });
          }
        },
        onPanEnd: (details) {
          setState(() {
            _joystickAnchor = null;
            _currentDrag = null;
            _currentDirection = Offset.zero; // 손을 떼면 이동 방향 초기화 -> 움직임 멈춤
            // Ticker를 여기서 멈추지 않고 계속 돌게 할 수도 있지만,
            // _currentDirection이 Offset.zero이므로 _gameLoop에서 움직이지 않음.
            // 배터리 절약을 위해 멈추는 것이 좋을 수 있음.
            // if (_ticker!.isTicking) {
            //   _ticker!.stop();
            // }
          });
        },
        child: Stack(
          children: [
            CustomPaint(
              painter: GamePainter(
                cameraPosition: _cameraPosition,
                screenCenterPosition: _screenCenterPosition,
              ),
              size: Size.infinite,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.dispose(); // State가 dispose될 때 Ticker도 dispose
    super.dispose();
  }
}

// 게임 요소를 그리는 CustomPainter 클래스
class GamePainter extends CustomPainter {
  final Offset cameraPosition; // 카메라의 월드 좌표 (화면 좌상단)
  final Offset screenCenterPosition; // 캐릭터가 그려질 화면 중앙 좌표

  GamePainter({required this.cameraPosition, required this.screenCenterPosition});

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2) // 그리드 선 색상 및 투명도
      ..strokeWidth = 1.0;

    const double gridSize = 50.0; // 그리드 한 칸의 크기

    double startWorldX = (cameraPosition.dx / gridSize).floor() * gridSize;
    double endWorldX = ((cameraPosition.dx + size.width) / gridSize).ceil() * gridSize;

    for (double worldX = startWorldX; worldX <= endWorldX; worldX += gridSize) {
      final screenX = worldX - cameraPosition.dx;
      canvas.drawLine(Offset(screenX, 0), Offset(screenX, size.height), paint);
    }

    double startWorldY = (cameraPosition.dy / gridSize).floor() * gridSize;
    double endWorldY = ((cameraPosition.dy + size.height) / gridSize).ceil() * gridSize;

    for (double worldY = startWorldY; worldY <= endWorldY; worldY += gridSize) {
      final screenY = worldY - cameraPosition.dy;
      canvas.drawLine(Offset(0, screenY), Offset(size.width, screenY), paint);
    }
  }

  void _drawCharacter(Canvas canvas, Size size) {
    final characterPaint = Paint()
      ..color = Colors.blue // 캐릭터 색상
      ..style = PaintingStyle.fill;

    final path = Path();
    const double charHeight = 30.0;
    const double charWidth = 20.0;

    path.moveTo(screenCenterPosition.dx, screenCenterPosition.dy - charHeight / 2);
    path.lineTo(screenCenterPosition.dx - charWidth / 2, screenCenterPosition.dy + charHeight / 2);
    path.lineTo(screenCenterPosition.dx + charWidth / 2, screenCenterPosition.dy + charHeight / 2);
    path.close();

    canvas.drawPath(path, characterPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawCharacter(canvas, size);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return oldDelegate.cameraPosition != cameraPosition ||
        oldDelegate.screenCenterPosition != screenCenterPosition;
  }
}
