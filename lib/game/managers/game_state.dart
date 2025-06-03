import 'package:flutter/material.dart'; // Offset 등을 사용하기 위해
import 'dart:math' as math; // math.Random 등을 사용하기 위해

// ExperienceCrystal 클래스 정의
// GameState에서 이 클래스 타입의 리스트를 사용합니다.
class ExperienceCrystal {
  final String id; // 고유 ID
  Offset worldPosition; // 월드 좌표
  final double expValue; // 제공하는 경험치 양
  // bool isCollected; // GameState에서 관리하므로 여기서는 제거하거나, Painter에서만 사용하는 플래그로 남길 수 있음
  final double radius; // 충돌 감지를 위한 반지름

  ExperienceCrystal({
    required this.id,
    required this.worldPosition,
    this.expValue = 10.0,
    this.radius = 10.0,
  });
}

class GameState {
  // 월드 및 카메라 상태
  Offset worldCharacterPosition = Offset.zero;
  Offset cameraPosition = Offset.zero;

  // 조이스틱 및 이동 방향 (UI 상태와 밀접하지만, 게임 로직에 직접 영향을 주므로 포함)
  Offset? joystickAnchor; // _GameScreenState에서 관리하는 것이 더 적절할 수 있음
  Offset? currentDrag;    // _GameScreenState에서 관리하는 것이 더 적절할 수 있음
  Offset currentDirection = Offset.zero; // 실제 이동 방향

  // 게임 진행 상태
  double totalElapsedTimeSeconds = 0.0;

  // 플레이어 레벨 및 경험치 상태
  int currentLevel = 1;
  double currentExp = 0; // 현재 누적된 총 경험치
  double expToNextLevel = 100; // 다음 레벨까지 필요한 총 경험치
  double expBarPercentage = 0.0; // EXP 바에 표시될 비율 (0.0 ~ 1.0)

  // 월드 요소 상태
  List<ExperienceCrystal> crystals = [];
  final math.Random random = math.Random(); // 랜덤 로직을 위해 인스턴스 포함

  // 게임 설정 값 (GameState로 옮기거나 별도 설정 클래스로 분리 가능)
  // final double movementSpeedInPixelsPerSecond = 150.0; // GameScreenState에 두는 것이 나을 수 있음
  final int maxCrystals = 20;
  final double crystalSpawnAreaRadius = 500.0;
  final double characterCollisionRadius = 15.0; // 캐릭터 충돌 반경

  // GameState 생성자
  GameState() {
    // 초기화 로직이 필요하면 여기에 추가
    // 예: crystals 초기화
    initializeCrystals();
    updateExpBarPercentage();
  }

  // --- 상태 변경 및 관리 메소드들 ---

  void initializeCrystals() {
    List<ExperienceCrystal> newCrystals = [];
    for (int i = 0; i < maxCrystals; i++) {
      newCrystals.add(_createSingleCrystal());
    }
    crystals = newCrystals; // 상태 업데이트
  }

  ExperienceCrystal _createSingleCrystal({Offset? aroundPosition}) {
    final spawnCenter = aroundPosition ?? worldCharacterPosition;
    double angle = random.nextDouble() * 2 * math.pi;
    double distance = crystalSpawnAreaRadius * (1 + random.nextDouble());

    Offset position = Offset(
      spawnCenter.dx + math.cos(angle) * distance,
      spawnCenter.dy + math.sin(angle) * distance,
    );

    return ExperienceCrystal(
      id: DateTime.now().millisecondsSinceEpoch.toString() + random.nextInt(1000).toString(),
      worldPosition: position,
      expValue: 10.0, // 고정 경험치
    );
  }

  void updateExpBarPercentage() {
    if (expToNextLevel <= 0) {
      expBarPercentage = 1.0;
    } else {
      expBarPercentage = (currentExp / expToNextLevel).clamp(0.0, 1.0);
    }
  }

  void addExperience(double amount) {
    currentExp += amount;
    if (currentExp >= expToNextLevel) {
      levelUp();
    }
    updateExpBarPercentage();
  }

  void levelUp() {
    currentLevel++;
    currentExp -= expToNextLevel;
    expToNextLevel *= 1.05; // 다음 레벨 필요 경험치 5% 증가

    if (currentExp >= expToNextLevel && expToNextLevel > 0) {
      levelUp();
    } else {
      updateExpBarPercentage();
    }
    print("Level Up! Current Level: $currentLevel, Next EXP: $expToNextLevel");
  }

  void checkCrystalCollisions() {
    bool changed = false;
    List<ExperienceCrystal> crystalsToAdd = [];

    // 리스트를 복사하여 순회 중 수정 문제를 방지하거나, 역순으로 순회하며 제거
    List<ExperienceCrystal> newCrystalsList = List.from(crystals);

    for (int i = newCrystalsList.length - 1; i >= 0; i--) {
      var crystal = newCrystalsList[i];
      // GamePainter에서 isCollected를 사용하지 않으므로, 여기서는 충돌 시 바로 제거
      final distance = (worldCharacterPosition - crystal.worldPosition).distance;
      if (distance < characterCollisionRadius + crystal.radius) {
        addExperience(crystal.expValue); // 경험치 추가 로직 호출
        newCrystalsList.removeAt(i); // 충돌된 크리스탈 제거

        double spawnAngle = (currentDirection == Offset.zero ? random.nextDouble() * 2 * math.pi : math.atan2(currentDirection.dy, currentDirection.dx) + math.pi);
        spawnAngle += (random.nextDouble() - 0.5) * (math.pi / 2);
        double spawnDistance = crystalSpawnAreaRadius * (1.2 + random.nextDouble() * 0.8);
        Offset newCrystalPosition = worldCharacterPosition + Offset(math.cos(spawnAngle) * spawnDistance, math.sin(spawnAngle) * spawnDistance);
        crystalsToAdd.add(_createSingleCrystal(aroundPosition: newCrystalPosition));

        changed = true;
        print("Collected crystal! EXP +${crystal.expValue}");
      }
    }

    if (changed) {
      newCrystalsList.addAll(crystalsToAdd);
      crystals = newCrystalsList; // GameState 내부의 crystals 리스트 업데이트
    }
  }

  void updateJoystick(Offset? anchor, Offset? drag, Offset direction) {
    joystickAnchor = anchor;
    currentDrag = drag;
    currentDirection = direction;
  }

  void moveCharacter(double deltaTime, double movementSpeed) {
    if (currentDirection != Offset.zero) {
      final double moveAmount = movementSpeed * deltaTime;
      final Offset moveDelta = currentDirection * moveAmount;
      worldCharacterPosition += moveDelta;
      cameraPosition += moveDelta; // 캐릭터 이동에 따라 맵이 반대로 움직이는 효과
    }
  }
}
