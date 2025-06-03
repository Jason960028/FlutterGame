import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class GameOverOverlay extends StatelessWidget {
  final int finalLevel;
  final String elapsedTime;

  const GameOverOverlay({
    super.key,
    required this.finalLevel,
    required this.elapsedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 64.0,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(5.0, 5.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40.0),
            Text(
              'Level: $finalLevel',
              style: const TextStyle(
                fontSize: 28.0,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              'Time: $elapsedTime',
              style: const TextStyle(
                fontSize: 24.0,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 60.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[600],
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Back to Menu',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}