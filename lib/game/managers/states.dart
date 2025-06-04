import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'states.dart';

enum KnightState {
  idle,
  attack,
  death,
  hurt,
}

// 크리스탈 등급
enum ExperienceCrystalType { normal, elite, boss }


// 적 등급 정의
enum EnemyType { normal, elite, boss }

// ExperienceCrystal 클래스 수정
class ExperienceCrystal {
  final String id;
  Offset worldPosition;
  final double expValue;
  final double radius;
  final Color color; // 경험치 크리스탈 색상 추가
  final ExperienceCrystalType crystalType; // 경험치 크리스탈 등급

  ExperienceCrystal({
    required this.id,
    required this.worldPosition,
    required this.expValue,
    this.radius = 8.0, // 크리스탈 기본 크기 약간 줄임
    required this.color,
    required this.crystalType,
  });
}

// 적 클래스 정의
class Enemy {
  final String id;
  final EnemyType type;
  Offset worldPosition;
  double health;
  final double speed;
  final Color color; // 등급별 색상
  final double radius;
  final double damageToPlayer; // 플레이어에게 주는 데미지
  final double expToDrop; // 처치 시 드랍할 경험치 양
  final ExperienceCrystalType crystalTypeToDrop; // 드랍할 경험치 크리스탈 등급

  // 보스 전용
  bool isBoss = false;
  double projectileTimer = 0.0;
  final double projectileInterval; // 발사체 발사 간격 (보스만 해당)

  Enemy({
    required this.id,
    required this.type,
    required this.worldPosition,
    required this.health,
    required this.speed,
    required this.color,
    this.radius = 15.0,
    required this.damageToPlayer,
    required this.expToDrop,
    required this.crystalTypeToDrop,
    this.projectileInterval = 2.0, // 기본 보스 발사 간격 2초
  }) {
    isBoss = (type == EnemyType.boss);
  }
}

// 보스 발사체 클래스 (간단하게)
class Projectile {
  final String id;
  Offset worldPosition;
  final Offset direction;
  final double speed;
  final Color color;
  final double radius;
  final double damageToPlayer;
  final double damageToEnemy;
  final bool isFromPlayer;
  bool isActive = true;

  Projectile({
    required this.id,
    required this.worldPosition,
    required this.direction,
    this.speed = 200.0,
    this.color = Colors.redAccent,
    this.radius = 8.0,
    this.damageToPlayer = 15.0,
    this.damageToEnemy = 10.0,
    this.isFromPlayer = false,
  });
}