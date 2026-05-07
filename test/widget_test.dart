import 'package:flutter_test/flutter_test.dart';
import 'package:showroom_flutter/app_environment.dart';
import 'package:showroom_flutter/main.dart';

void main() {
  test('environment config maps supported mobile flavors', () {
    expect(
      AppEnvironmentConfig.fromName('dev').environment,
      AppEnvironment.dev,
    );
    expect(
      AppEnvironmentConfig.fromName('staging').appTitle,
      'Smart Mattress Showroom Staging',
    );
    expect(
      AppEnvironmentConfig.fromName('prod').dartDefineValue,
      'prod',
    );
  });

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

  test('showroom visualization data can be overridden and sent to WebView', () {
    final MattressDashboardData data =
        MattressDashboardData.defaults.copyWithModeMetrics(
      AdjustmentMode.left,
      MattressDashboardData.defaults.metricsFor(AdjustmentMode.left).copyWith(
        pressureValues: const <String, int>{
          'shoulder': 11,
          'back': 22,
          'waist': 33,
          'hip': 44,
          'leg': 55,
        },
        targets: const <String, MattressZoneTarget>{
          'shoulder': MattressZoneTarget(pressure: 0.11, glow: 0.21),
          'back': MattressZoneTarget(pressure: 0.22, glow: 0.32),
          'waist': MattressZoneTarget(pressure: 0.33, glow: 0.43),
          'hip': MattressZoneTarget(pressure: 0.44, glow: 0.54),
          'leg': MattressZoneTarget(pressure: 0.55, glow: 0.65),
        },
      ),
    );

    expect(data.metricsFor(AdjustmentMode.left).pressureValues['waist'], 33);
    expect(
      MattressDashboardData.defaults
          .metricsFor(AdjustmentMode.left)
          .pressureValues['waist'],
      92,
    );

    final Map<String, Object?> payload = data.toWebViewPayload();
    final Map<String, Object?> modes =
        payload['modes']! as Map<String, Object?>;
    final Map<String, Object?> left = modes['left']! as Map<String, Object?>;
    final Map<String, Object?> values = left['values']! as Map<String, Object?>;
    final Map<String, Object?> targets =
        left['targets']! as Map<String, Object?>;
    final Map<String, Object?> waist =
        targets['waist']! as Map<String, Object?>;

    expect(values['waist'], 33);
    expect(waist['pressure'], 0.33);
    expect(waist['glow'], 0.43);
  });

  test('dashboard controller publishes runtime data updates', () {
    final MattressDashboardController controller =
        MattressDashboardController();
    int notifications = 0;
    controller.addListener(() {
      notifications += 1;
    });

    controller.updateRealtime(heartRate: 88, breathRate: 19);
    controller.updateModeMetrics(
      AdjustmentMode.right,
      controller.data.metricsFor(AdjustmentMode.right).copyWith(
        pressureValues: const <String, int>{
          'shoulder': 61,
          'back': 62,
          'waist': 63,
          'hip': 64,
          'leg': 65,
        },
      ),
    );

    expect(controller.data.realtime.heartRate, 88);
    expect(controller.data.realtime.breathRate, 19);
    expect(
      controller.data.metricsFor(AdjustmentMode.right).pressureValues['waist'],
      63,
    );
    expect(notifications, 2);

    controller.dispose();
  });

  test('dashboard controller can apply external payload patches', () {
    final MattressDashboardController controller =
        MattressDashboardController();

    controller.applyPayload(<String, Object?>{
      'realtime': <String, Object?>{
        'heartRate': 91,
        'breathRate': 20,
      },
      'trend': <String, Object?>{
        'lumbarSupportIndex': 93,
        'lumbarSupportStatus': '稳定',
      },
      'pressureChart': <String, Object?>{
        'currentValues': <double>[7010, 7450, 8020, 7680, 7220],
        'markerIndex': 2,
        'markerValue': 8020,
      },
      'modes': <String, Object?>{
        'left': <String, Object?>{
          'values': <String, int>{
            'shoulder': 71,
            'back': 72,
            'waist': 73,
            'hip': 74,
            'leg': 75,
          },
          'targets': <String, Object?>{
            'waist': <String, Object?>{
              'pressure': 0.77,
              'glow': 0.88,
            },
          },
        },
      },
    });

    expect(controller.data.realtime.heartRate, 91);
    expect(controller.data.trend.lumbarSupportStatus, '稳定');
    expect(controller.data.pressureChart.currentValues[2], 8020);
    expect(controller.data.pressureChart.markerValue, 8020);
    expect(
      controller.data.metricsFor(AdjustmentMode.left).pressureValues['waist'],
      73,
    );
    expect(
      controller.data
          .metricsFor(AdjustmentMode.left)
          .targets['waist']
          ?.pressure,
      0.77,
    );
    expect(
      controller.data.metricsFor(AdjustmentMode.left).targets['waist']?.glow,
      0.88,
    );

    controller.dispose();
  });
}
