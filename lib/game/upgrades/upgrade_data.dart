
// 업그레이드 타입을 정의 (무기 획득/강화, 패시브 등)
import '../my_game.dart';

enum UpgradeType { weapon, passive }

// 모든 업그레이드 항목의 데이터 구조
class UpgradeData {
  final String id; // 업그레이드 고유 ID
  final String name; // UI에 표시될 이름
  final String description; // UI에 표시될 설명
  final UpgradeType type;
  final Function(MyGame) apply; // 업그레이드 효과를 적용하는 함수

  UpgradeData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.apply,
  });
}