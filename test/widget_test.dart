import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showroom_flutter/app_environment.dart';
import 'package:showroom_flutter/main.dart';

void main() {
  testWidgets('app starts on showroom home page', (WidgetTester tester) async {
    await tester.pumpWidget(
      SmartMattressShowroomApp(config: AppEnvironmentConfig.fromName('dev')),
    );

    expect(find.text('智能睡眠展厅'), findsOneWidget);
    expect(find.text('智能床垫大屏入口'), findsOneWidget);
    expect(find.text('轻智能床垫大屏入口'), findsOneWidget);
  });

  testWidgets('light smart mattress entry is available from home',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      SmartMattressShowroomApp(config: AppEnvironmentConfig.fromName('dev')),
    );

    expect(find.text('待接入'), findsNothing);
    expect(find.text('在线'), findsNWidgets(2));
  });

  testWidgets('home page shows mattress showroom entry options',
      (WidgetTester tester) async {
    bool enteredSmartMattress = false;
    bool enteredLightSmartMattress = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ShowroomHomePage(
          onEnterSmartMattress: () {
            enteredSmartMattress = true;
          },
          onEnterLightSmartMattress: () {
            enteredLightSmartMattress = true;
          },
        ),
      ),
    );

    expect(find.text('智能床垫大屏入口'), findsOneWidget);
    expect(find.text('轻智能床垫大屏入口'), findsOneWidget);

    await tester.tap(find.text('智能床垫大屏入口'));
    await tester.pump();

    expect(enteredSmartMattress, isTrue);

    await tester.tap(find.text('轻智能床垫大屏入口'));
    await tester.pump();

    expect(enteredLightSmartMattress, isTrue);
  });

  testWidgets('home page fits compact phone landscape',
      (WidgetTester tester) async {
    for (final Size size in <Size>[
      const Size(812, 375),
      const Size(852, 393),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ShowroomHomePage(
            onEnterSmartMattress: () {},
            onEnterLightSmartMattress: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    }
  });

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

  test('light dashboard title matches smart mattress header copy', () {
    expect(
      ShowroomDashboardProfile.light.headerTitle,
      '智能床垫实时监测',
    );
  });

  test('mock dashboard payload stream supports repeated listeners', () async {
    final Stream<Map<String, Object?>> stream = buildMockDashboardPayloadStream(
      interval: const Duration(milliseconds: 1),
    );

    final Map<String, Object?> first = await stream.first;
    final Map<String, Object?> second = await stream.first;

    expect(first['realtime'], isA<Map<String, Object?>>());
    expect(second['realtime'], isA<Map<String, Object?>>());
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
    final Map<String, Object?> sensorFlow =
        payload['sensorFlow']! as Map<String, Object?>;
    final Map<String, Object?> modes =
        payload['modes']! as Map<String, Object?>;
    final Map<String, Object?> left = modes['left']! as Map<String, Object?>;
    final Map<String, Object?> values = left['values']! as Map<String, Object?>;
    final Map<String, Object?> targets =
        left['targets']! as Map<String, Object?>;
    final Map<String, Object?> waist =
        targets['waist']! as Map<String, Object?>;

    expect(sensorFlow['enabled'], isFalse);
    expect(sensorFlow['leftEnabled'], isFalse);
    expect(sensorFlow['rightEnabled'], isFalse);
    expect(payload.containsKey('rippleEffect'), isFalse);
    expect(values['waist'], 33);
    expect(waist['pressure'], 0.33);
    expect(waist['glow'], 0.43);
  });

  test('sensor flow state toggles sides independently', () {
    final MattressSensorFlowState leftActive = MattressSensorFlowState.defaults
        .toggleSide(MattressSensorFlowSide.left);
    final MattressSensorFlowState bothActive =
        leftActive.toggleSide(MattressSensorFlowSide.right);
    final MattressSensorFlowState rightActive =
        bothActive.toggleSide(MattressSensorFlowSide.left);

    expect(MattressSensorFlowState.defaults.enabled, isFalse);
    expect(leftActive.enabled, isTrue);
    expect(leftActive.leftEnabled, isTrue);
    expect(leftActive.rightEnabled, isFalse);
    expect(bothActive.activeSideCount, 2);
    expect(rightActive.enabled, isTrue);
    expect(rightActive.leftEnabled, isFalse);
    expect(rightActive.rightEnabled, isTrue);
  });

  test('ripple effect state toggles sides independently', () {
    final MattressRippleEffectState leftActive =
        MattressRippleEffectState.off.toggleSide(MattressRippleSide.left);
    final MattressRippleEffectState bothActive =
        leftActive.toggleSide(MattressRippleSide.right);
    final MattressRippleEffectState rightOnly =
        bothActive.toggleSide(MattressRippleSide.left);
    final MattressRippleEffectState off =
        rightOnly.toggleSide(MattressRippleSide.right);

    expect(MattressRippleEffectState.off.enabled, isFalse);
    expect(leftActive.enabled, isTrue);
    expect(leftActive.leftEnabled, isTrue);
    expect(leftActive.rightEnabled, isFalse);
    expect(leftActive.activeSide, MattressRippleSide.left);
    expect(leftActive.summaryLabel, 'LEFT');
    expect(bothActive.enabled, isTrue);
    expect(bothActive.leftEnabled, isTrue);
    expect(bothActive.rightEnabled, isTrue);
    expect(bothActive.activeSideCount, 2);
    expect(bothActive.activeSide, isNull);
    expect(bothActive.summaryLabel, 'BOTH');
    expect(bothActive.toJson()['side'], isNull);
    expect(rightOnly.enabled, isTrue);
    expect(rightOnly.leftEnabled, isFalse);
    expect(rightOnly.rightEnabled, isTrue);
    expect(rightOnly.toJson()['side'], 'right');
    expect(off.enabled, isFalse);
    expect(off.leftEnabled, isFalse);
    expect(off.rightEnabled, isFalse);
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
      'sensorFlow': <String, Object?>{
        'enabled': true,
        'leftEnabled': false,
        'rightEnabled': true,
        'intensity': 1.2,
        'dataRate': 0.42,
      },
      'rippleEffect': <String, Object?>{
        'enabled': true,
        'leftEnabled': true,
        'rightEnabled': false,
        'intensity': -0.2,
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
    expect(controller.data.sensorFlow.leftEnabled, isFalse);
    expect(controller.data.sensorFlow.rightEnabled, isTrue);
    expect(controller.data.sensorFlow.intensity, 1);
    expect(controller.data.sensorFlow.dataRate, 0.42);
    expect(controller.data.rippleEffect.enabled, isTrue);
    expect(controller.data.rippleEffect.leftEnabled, isTrue);
    expect(controller.data.rippleEffect.rightEnabled, isFalse);
    expect(controller.data.rippleEffect.intensity, 0);
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
