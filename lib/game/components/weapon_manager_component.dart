import 'package:flame/components.dart';
import '../my_game.dart';
import 'enemy_component.dart';
import '../weapons/weapon_data.dart';
import 'player_component.dart';

class WeaponManagerComponent extends Component with HasGameRef<MyGame> {
  final PlayerComponent player;
  List<WeaponData> activeWeapons = [];

  WeaponManagerComponent({required this.player});

  @override
  void update(double dt) {
    super.update(dt);
    for (final weapon in activeWeapons) {
      weapon.timer -= dt;
      if (weapon.timer <= 0) {
        weapon.timer = weapon.cooldown;
        _fireWeapon(weapon);
      }
    }
  }

  void _fireWeapon(WeaponData weapon) {
    for (int i = 0; i < weapon.count; i++) { // 업그레이드된 count만큼 반복
      // ... (기존 가장 가까운 적 찾기 로직) ...
      EnemyComponent? closestEnemy;
      double minDistanceSq = double.infinity;
      for (final component in gameRef.world.children.whereType<EnemyComponent>()) {
        if (!component.isDead) {
          final distanceSq = component.position.distanceToSquared(player.position);
          if (distanceSq < minDistanceSq) {
            minDistanceSq = distanceSq;
            closestEnemy = component;
          }
        }
      }
      Vector2 direction = Vector2(1, 0);
      if (closestEnemy != null) {
        direction = (closestEnemy.position - player.position).normalized();
      }

      final componentToSpawn = weapon.spawnComponent(
        position: player.position.clone(),
        direction: direction,
        player: player, // player 객체 전달
      );

      gameRef.world.add(componentToSpawn);
    }
  }

  void acquireWeapon(WeaponData weaponData) {
    if (!activeWeapons.any((w) => w.id == weaponData.id)) {
      weaponData.timer = weaponData.cooldown;
      weaponData.level = 1; // 처음 획득 시 레벨 1 (기본 효과)
      activeWeapons.add(weaponData);
    }
  }

  WeaponData? getWeaponById(String id) {
    try {
      return activeWeapons.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }
}