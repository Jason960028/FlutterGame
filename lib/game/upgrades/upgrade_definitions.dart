import 'package:flutter/foundation.dart';
import 'upgrade_data.dart';
import '../weapons/weapon_definitions.dart';

// 게임 내 모든 가능한 업그레이드 목록
final List<UpgradeData> allUpgrades = [
  // --- 부요의 깃털 ---
  UpgradeData(
    id: 'feather_of_buyo_acquire',
    name: '부요의 깃털',
    description: '일정 시간마다 회오리를 소환해 주변의 적을 공격합니다.',
    type: UpgradeType.weapon,
    apply: (game) {
      game.player.weaponManager.acquireWeapon(getWeaponDataById('feather_of_buyo'));
    },
  ),
  UpgradeData(
    id: 'feather_of_buyo_lv1_count',
    name: '부요의 깃털 (LV1)',
    description: '생성되는 회오리 수가 1개 증가합니다.', // 총 2개가 됨
    type: UpgradeType.weapon,
    apply: (game) {
      final weapon = game.player.weaponManager.getWeaponById('feather_of_buyo');
      if (weapon != null) {
        weapon.count++; // 기본값 1에서 2로 증가
        weapon.level++;
        if (kDebugMode) print("부요의 깃털 LV1: 회오리 개수 증가 -> ${weapon.count}");
      }
    },
  ),
  UpgradeData(
    id: 'feather_of_buyo_lv2_damage',
    name: '부요의 깃털 (LV2)',
    description: '회오리의 데미지가 50% 증가합니다.',
    type: UpgradeType.weapon,
    apply: (game) {
      final weapon = game.player.weaponManager.getWeaponById('feather_of_buyo');
      if (weapon != null) {
        weapon.damageMultiplier += 0.5;
        weapon.level++;
        if (kDebugMode) print("부요의 깃털 LV2: 데미지 배율 증가 -> ${weapon.damageMultiplier}");
      }
    },
  ),
  UpgradeData(
    id: 'feather_of_buyo_lv3_duration',
    name: '부요의 깃털 (LV3)',
    description: '회오리 지속시간이 3초 증가합니다.',
    type: UpgradeType.weapon,
    apply: (game) {
      final weapon = game.player.weaponManager.getWeaponById('feather_of_buyo');
      if (weapon != null) {
        // 기본 지속시간 5초에 대한 비율로 증가 (5초의 60% 증가 = 3초 증가)
        weapon.durationMultiplier += 0.6;
        weapon.level++;
        if (kDebugMode) print("부요의 깃털 LV3: 지속시간 배율 증가 -> ${weapon.durationMultiplier}");
      }
    },
  ),
  UpgradeData(
    id: 'feather_of_buyo_lv4_speed',
    name: '부요의 깃털 (LV4)',
    description: '회오리의 이동속도가 2배 증가합니다.',
    type: UpgradeType.weapon,
    apply: (game) {
      final weapon = game.player.weaponManager.getWeaponById('feather_of_buyo');
      if (weapon != null) {
        weapon.speedMultiplier *= 2; // 속도 배율 2배
        weapon.level++;
        if (kDebugMode) print("부요의 깃털 LV4: 속도 배율 증가 -> ${weapon.speedMultiplier}");
      }
    },
  ),
  // TODO: 여기에 다른 무기 및 패시브 업그레이드 추가
  ...List.generate(5, (i) {
    final level = i + 1;
    return UpgradeData(
      id: 'projectile_size_lv${level}',
      name: '발사체 크기 증가 (LV$level)',
      description: '모든 발사체의 크기가 30% 증가합니다. (현재: +${level * 30}%)',
      type: UpgradeType.passive,
      apply: (game) {
        final passiveManager = game.player.passiveManager;
        // 기본 크기 1.0에 0.3씩 더해감
        passiveManager.projectileSizeMultiplier += 1;
        // 현재 패시브 레벨 저장
        passiveManager.passiveLevels['projectile_size'] = level;
        if (kDebugMode) print("패시브: 발사체 크기 배율 -> ${passiveManager.projectileSizeMultiplier}");
      },
    );
  }),
  ...List.generate(5, (i) {
    final level = i + 1;
    final multiplier = 1 << level;
    return UpgradeData(
      id: 'exp_collect_range_lv$level',
      name: '크리스탈 흡수 범위 증가 (LV$level)',
      description: '경험치 크리스탈을 끌어들이는 범위가 두 배 증가합니다. (현재: ×$multiplier)',
      type: UpgradeType.passive,
      apply: (game) {
        final passiveManager = game.player.passiveManager;
        passiveManager.expCollectingRange *= 1.5;
        passiveManager.passiveLevels['exp_collect_range'] = level;
        if (kDebugMode) print('패시브: 크리스탈 수집 범위 -> ${passiveManager.expCollectingRange}');
      },
    );
  }),
];

// 업그레이드 ID로 업그레이드 데이터를 찾는 함수
UpgradeData? getUpgradeById(String id) {
  try {
    return allUpgrades.firstWhere((u) => u.id == id);
  } catch (e) {
    return null;
  }
}