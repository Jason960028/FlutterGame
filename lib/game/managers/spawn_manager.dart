import 'dart:math' as math;
import 'package:flame/components.dart';
import '../my_game.dart';
import '../components/crystal_component.dart';
import '../components/enemy_component.dart';

class SpawnManager {
  SpawnManager({required this.game});

  final MyGame game;
  final math.Random _random = math.Random();

  void spawnCrystal() {
    if (game.world.children.whereType<CrystalComponent>().length >=
        game.maxCrystalsOnField) return;
    final angle = _random.nextDouble() * 2 * math.pi;
    final radius = game.crystalSpawnMinRadiusFromPlayer +
        _random.nextDouble() *
            (game.crystalSpawnMaxRadiusFromPlayer -
                game.crystalSpawnMinRadiusFromPlayer);
    final spawnPosition = game.player.position +
        Vector2(math.cos(angle) * radius, math.sin(angle) * radius);
    final expValue = 5.0 + _random.nextInt(11);
    final crystal = CrystalComponent(position: spawnPosition, expValue: expValue);
    game.world.add(crystal);
  }

  void spawnEnemy() {
    if (game.world.children.whereType<EnemyComponent>().length >=
        game.maxEnemiesOnField) return;
    final angle = _random.nextDouble() * 2 * math.pi;
    final radius = game.enemySpawnMinRadiusFromPlayer +
        _random.nextDouble() *
            (game.enemySpawnMaxRadiusFromPlayer -
                game.enemySpawnMinRadiusFromPlayer);
    final spawnPosition = game.player.position +
        Vector2(math.cos(angle) * radius, math.sin(angle) * radius);
    final health = 1.0 + game.levelManager.currentLevel * 5;
    final damage = 0.0 + game.levelManager.currentLevel * 1;
    final expDrop = 500.0 + game.levelManager.currentLevel * 3;
    final enemy = EnemyComponent(
      position: spawnPosition,
      health: health,
      damageToPlayer: damage,
      expDropAmount: expDrop,
    );
    game.world.add(enemy);
  }
}