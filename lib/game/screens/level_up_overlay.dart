import 'package:flutter/material.dart';

import '../my_game.dart';
import '../upgrades/upgrade_data.dart';


class LevelUpOverlay extends StatelessWidget {
  final MyGame game;

  const LevelUpOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final List<UpgradeData> upgradeChoices = game.getLevelUpChoices();

    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LEVEL UP!',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent),
            ),
            const SizedBox(height: 30),
            ...upgradeChoices.map((upgrade) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    minimumSize: const Size(double.infinity, 80),
                  ),
                  onPressed: () {
                    game.selectUpgrade(upgrade);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        upgrade.name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        upgrade.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            if (upgradeChoices.isEmpty)
              const Text("더 이상 얻을 수 있는 업그레이드가 없습니다.", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}