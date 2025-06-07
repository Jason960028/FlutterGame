import 'package:flame/components.dart';

class PassiveManagerComponent extends Component {
  // 패시브 효과를 저장할 변수들
  double projectileSizeMultiplier = 1.0;
  // TODO: 나중에 이동 속도, 체력 등 다른 패시브 효과 변수 추가

  // 각 패시브의 현재 레벨을 저장
  Map<String, int> passiveLevels = {};
}