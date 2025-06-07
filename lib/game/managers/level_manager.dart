import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../my_game.dart';
import '../upgrades/upgrade_data.dart';
import '../upgrades/upgrade_definitions.dart';

class LevelManager {
  LevelManager({required this.game});

  final MyGame game;

  int currentLevel = 1;
  double currentExp = 0.0;
  double expToNextLevel = 100.0;
  final math.Random _random = math.Random();

  double get expBarPercentage {
    if (expToNextLevel <= 0) return 1.0;
    return (currentExp / expToNextLevel).clamp(0.0, 1.0);
  }

  void addExperience(double amount) {
    if (game.isGameOver) return;
    currentExp += amount;
    if (kDebugMode) {
      print('경험치 획득: +$amount. 현재 EXP: $currentExp / $expToNextLevel');
    }
    if (currentExp >= expToNextLevel) {
      levelUp();
    }
    game.notifyListeners();
  }

  void levelUp() {
    currentLevel++;
    currentExp -= expToNextLevel;
    expToNextLevel *= 1.2;
    if (kDebugMode) {
      print('레벨 업! 현재 레벨: $currentLevel. 다음 레벨까지 EXP: $expToNextLevel');
    }
    final choices = getLevelUpChoices();
    if (choices.isNotEmpty) {
      game.paused = true;
      game.overlays.add('LevelUpOverlay');
    } else {
      if (kDebugMode) {
        print('레벨업 했지만, 선택 가능한 업그레이드가 없습니다.');
      }
      if (currentExp >= expToNextLevel) {
        levelUp();
      }
    }
    game.notifyListeners();
  }

  List<UpgradeData> getLevelUpChoices() {
    final possibleUpgrades = <UpgradeData>[];
    final currentWeapons = game.player.weaponManager.activeWeapons;
    final currentPassives = game.player.passiveManager.passiveLevels;

    for (final upgrade in allUpgrades) {
      if (upgrade.type == UpgradeType.weapon) {
        if (upgrade.id.endsWith('_acquire')) {
          final weaponId = upgrade.id.replaceAll('_acquire', '');
          if (!currentWeapons.any((w) => w.id == weaponId)) {
            possibleUpgrades.add(upgrade);
          }
        } else {
          final weaponId = upgrade.id.substring(0, upgrade.id.indexOf('_lv'));
          final weapon = game.player.weaponManager.getWeaponById(weaponId);
          if (weapon != null && upgrade.id.contains('_lv${weapon.level}_')) {
            possibleUpgrades.add(upgrade);
          }
        }
      } else if (upgrade.type == UpgradeType.passive) {
        final passiveId = upgrade.id.split('_lv')[0];
        final currentLevel = currentPassives[passiveId] ?? 0;
        if (upgrade.id.contains('_lv${currentLevel + 1}')) {
          possibleUpgrades.add(upgrade);
        }
      }
    }

    possibleUpgrades.shuffle(_random);
    return possibleUpgrades.take(3).toList();
  }

  void selectUpgrade(UpgradeData upgrade) {
    upgrade.apply(game);
    game.overlays.remove('LevelUpOverlay');
    game.paused = false;
    game.notifyListeners();
    if (currentExp >= expToNextLevel) {
      levelUp();
    }
  }
}