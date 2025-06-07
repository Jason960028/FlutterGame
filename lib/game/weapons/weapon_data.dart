import 'package:flame/components.dart';
import '../components/player_component.dart';

typedef ComponentFactory = Component Function({
required Vector2 position,
required Vector2 direction,
required PlayerComponent player,
});

class WeaponData {
  final String id;
  final String name;
  double cooldown;
  final double damage; // 무기의 기본 데미지
  final ComponentFactory spawnComponent;
  double speedMultiplier = 1.0; // 속도 배율 속성 추가

  double timer = 0.0;
  int level = 0;

  int count = 1;
  double damageMultiplier = 1.0;
  double durationMultiplier = 1.0;

  WeaponData({
    required this.id,
    required this.name,
    required this.cooldown,
    required this.damage, // 생성자에서 기본 데미지를 받도록 함
    required this.spawnComponent,
  });
}