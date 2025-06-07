import 'dart:math' as math;
import 'package:flame/components.dart';
import 'weapon_data.dart';
import '../components/player_projectile_component.dart';
import '../components/tornado_component.dart';

final math.Random _random = math.Random();

// WeaponManager에서 player 객체를 전달받을 수 있으므로, MyGame 인스턴스를 직접 참조할 필요 없음
final Map<String, WeaponData> _allWeapons = {
  'default_projectile': WeaponData(
    id: 'default_projectile',
    name: '기본 발사체',
    cooldown: 0.5,
    damage: 15.0, // 기본 발사체의 기본 데미지
    spawnComponent: ({required position, required direction, required player}) {
      final weaponData = player.weaponManager.getWeaponById('default_projectile')!;
      final sizeMultiplier = player.passiveManager.projectileSizeMultiplier;
      final damageMultiplier = weaponData.damageMultiplier;

      return PlayerProjectileComponent(
        position: position,
        velocity: direction * 300.0,
        radius: 5.0 * sizeMultiplier,
        damage: weaponData.damage * damageMultiplier, // 최종 데미지 전달
      );
    },
  ),
  'feather_of_buyo': WeaponData(
    id: 'feather_of_buyo',
    name: '부요의 깃털',
    cooldown: 3.0,
    damage: 30.0, // 회오리의 초당 기본 데미지
    spawnComponent: ({required position, required direction, required player}) {
      final weaponData = player.weaponManager.getWeaponById('feather_of_buyo')!;
      final sizeMultiplier = player.passiveManager.projectileSizeMultiplier;
      final damageMultiplier = weaponData.damageMultiplier;
      final durationMultiplier = weaponData.durationMultiplier;

      final randomAngle = _random.nextDouble() * 2 * math.pi;
      final randomDirection = Vector2(math.cos(randomAngle), math.sin(randomAngle));

      return TornadoComponent(
        position: position,
        initialVelocity: randomDirection,
        radius: 20.0 * sizeMultiplier,
        lifetime: 5.0 * durationMultiplier, // 최종 지속시간 전달
        damagePerSecond: weaponData.damage * damageMultiplier, // 최종 초당 데미지 전달
      );
    },
  ),
};

WeaponData getWeaponDataById(String id) {
  final data = _allWeapons[id]!;
  return WeaponData(
    id: data.id,
    name: data.name,
    cooldown: data.cooldown,
    damage: data.damage, // damage 속성 복사
    spawnComponent: data.spawnComponent,
  );
}