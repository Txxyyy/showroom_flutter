import 'package:flutter_test/flutter_test.dart';
import 'package:showroom_flutter/main.dart';

void main() {
  test('adjustment mode labels match showroom copy', () {
    expect(AdjustmentMode.flat.label, 'FLAT');
    expect(AdjustmentMode.flat.status, '智能监测模式，当前无主动调节');
    expect(AdjustmentMode.left.buttonTitle, '左侧独立调节');
    expect(AdjustmentMode.right.buttonTitle, '右侧独立调节');
    expect(AdjustmentMode.deep.warningKey, 'hip');
  });

  test('heating toggles preserve independent zones', () {
    final MattressHeatingState heating = MattressHeatingState.off
        .toggle(MattressHeatControl.leftWaist)
        .toggle(MattressHeatControl.rightLeg);

    expect(heating.activeCount, 2);
    expect(heating.isEnabled(MattressHeatControl.leftWaist), isTrue);
    expect(heating.isEnabled(MattressHeatControl.leftLeg), isFalse);
    expect(heating.isEnabled(MattressHeatControl.rightLeg), isTrue);
  });
}
