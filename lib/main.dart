import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_environment.dart';
import 'showroom_scene_embed.dart';

const bool _enableMockDashboardStream = bool.fromEnvironment(
  'SHOWROOM_MOCK_STREAM',
  defaultValue: true,
);

enum ShowroomDashboardProfile {
  smart,
  light;

  bool get isLight => this == ShowroomDashboardProfile.light;

  String get headerTitle {
    switch (this) {
      case ShowroomDashboardProfile.smart:
        return '智能床垫实时监测';
      case ShowroomDashboardProfile.light:
        return '智能床垫实时监测';
    }
  }

  String statusFor(AdjustmentMode mode) {
    switch (this) {
      case ShowroomDashboardProfile.smart:
        return mode.status;
      case ShowroomDashboardProfile.light:
        return '生命体征实时监测中，心率与呼吸率持续追踪';
    }
  }
}

enum _LightCenterPanelView {
  controls,
  intro;

  String get title {
    switch (this) {
      case _LightCenterPanelView.controls:
        return '演示控制';
      case _LightCenterPanelView.intro:
        return '产品介绍';
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final AppEnvironmentConfig config = AppEnvironmentConfig.current;
  final Stream<Map<String, Object?>>? dashboardPayloadStream =
      config.environment == AppEnvironment.dev && _enableMockDashboardStream
          ? buildMockDashboardPayloadStream()
          : null;
  runApp(
    SmartMattressShowroomApp(
      config: config,
      dashboardPayloadStream: dashboardPayloadStream,
    ),
  );
}

enum AdjustmentMode {
  auto,
  zero,
  left,
  right,
  deep,
  flat;

  String get rawValue => name;

  String get label {
    switch (this) {
      case AdjustmentMode.auto:
        return 'AUTO';
      case AdjustmentMode.zero:
        return 'ZERO';
      case AdjustmentMode.left:
        return 'LEFT';
      case AdjustmentMode.right:
        return 'RIGHT';
      case AdjustmentMode.deep:
        return 'DEEP';
      case AdjustmentMode.flat:
        return 'FLAT';
    }
  }

  String get buttonTitle {
    switch (this) {
      case AdjustmentMode.auto:
        return '左右智能调节';
      case AdjustmentMode.zero:
        return '气囊释压按摩';
      case AdjustmentMode.left:
        return '左侧独立调节';
      case AdjustmentMode.right:
        return '右侧独立调节';
      case AdjustmentMode.deep:
        return '深睡承托';
      case AdjustmentMode.flat:
        return '恢复平躺';
    }
  }

  String get subtitle {
    switch (this) {
      case AdjustmentMode.auto:
        return '左右气囊联动微调，床垫表面保持稳定承托';
      case AdjustmentMode.zero:
        return '气囊按波浪节奏充放气，形成柔和释压按摩';
      case AdjustmentMode.left:
        return '左侧独立调节，右侧保持稳定承托';
      case AdjustmentMode.right:
        return '右侧独立调节，左侧保持稳定承托';
      case AdjustmentMode.deep:
        return '腰臀区域增强承托，呼吸与心率保持低波动';
      case AdjustmentMode.flat:
        return '床垫恢复平躺，系统持续监测体压变化';
    }
  }

  String get status {
    switch (this) {
      case AdjustmentMode.auto:
        return '检测到人体存在，分区智能调节中';
      case AdjustmentMode.zero:
        return '气囊释压按摩运行中，压力波从肩部流向腿部';
      case AdjustmentMode.left:
        return '左侧智能调节中，右侧进入低扰动保护';
      case AdjustmentMode.right:
        return '右侧智能调节中，左侧进入低扰动保护';
      case AdjustmentMode.deep:
        return '深睡承托模式运行中，腰臀分区缓慢释压';
      case AdjustmentMode.flat:
        return '智能监测模式，当前无主动调节';
    }
  }

  bool get reveal => this != AdjustmentMode.flat;

  String? get side {
    switch (this) {
      case AdjustmentMode.left:
        return 'left';
      case AdjustmentMode.right:
        return 'right';
      case AdjustmentMode.auto:
      case AdjustmentMode.zero:
      case AdjustmentMode.deep:
      case AdjustmentMode.flat:
        return null;
    }
  }

  String? get warningKey => this == AdjustmentMode.deep ? 'hip' : null;

  static AdjustmentMode? tryParse(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'auto':
        return AdjustmentMode.auto;
      case 'zero':
        return AdjustmentMode.zero;
      case 'left':
        return AdjustmentMode.left;
      case 'right':
        return AdjustmentMode.right;
      case 'deep':
        return AdjustmentMode.deep;
      case 'flat':
        return AdjustmentMode.flat;
      default:
        return null;
    }
  }
}

const List<String> _pressureZoneKeys = <String>[
  'shoulder',
  'back',
  'waist',
  'hip',
  'leg',
];

enum MattressHeatControl {
  leftWaist,
  leftLeg,
  rightWaist,
  rightLeg;

  String get title {
    switch (this) {
      case MattressHeatControl.leftWaist:
        return '左腰加热';
      case MattressHeatControl.leftLeg:
        return '左腿加热';
      case MattressHeatControl.rightWaist:
        return '右腰加热';
      case MattressHeatControl.rightLeg:
        return '右腿加热';
    }
  }
}

enum MattressSensorFlowSide {
  left,
  right;

  String get title {
    switch (this) {
      case MattressSensorFlowSide.left:
        return '左侧压电';
      case MattressSensorFlowSide.right:
        return '右侧压电';
    }
  }
}

enum MattressRippleSide {
  left,
  right;

  String get title {
    switch (this) {
      case MattressRippleSide.left:
        return '左侧波点';
      case MattressRippleSide.right:
        return '右侧波点';
    }
  }
}

@immutable
class MattressHeatingState {
  const MattressHeatingState({
    this.leftWaist = false,
    this.leftLeg = false,
    this.rightWaist = false,
    this.rightLeg = false,
  });

  static const MattressHeatingState off = MattressHeatingState();

  final bool leftWaist;
  final bool leftLeg;
  final bool rightWaist;
  final bool rightLeg;

  int get activeCount {
    return <bool>[leftWaist, leftLeg, rightWaist, rightLeg]
        .where((bool enabled) => enabled)
        .length;
  }

  MattressHeatingState toggle(MattressHeatControl control) {
    switch (control) {
      case MattressHeatControl.leftWaist:
        return copyWith(leftWaist: !leftWaist);
      case MattressHeatControl.leftLeg:
        return copyWith(leftLeg: !leftLeg);
      case MattressHeatControl.rightWaist:
        return copyWith(rightWaist: !rightWaist);
      case MattressHeatControl.rightLeg:
        return copyWith(rightLeg: !rightLeg);
    }
  }

  bool isEnabled(MattressHeatControl control) {
    switch (control) {
      case MattressHeatControl.leftWaist:
        return leftWaist;
      case MattressHeatControl.leftLeg:
        return leftLeg;
      case MattressHeatControl.rightWaist:
        return rightWaist;
      case MattressHeatControl.rightLeg:
        return rightLeg;
    }
  }

  MattressHeatingState copyWith({
    bool? leftWaist,
    bool? leftLeg,
    bool? rightWaist,
    bool? rightLeg,
  }) {
    return MattressHeatingState(
      leftWaist: leftWaist ?? this.leftWaist,
      leftLeg: leftLeg ?? this.leftLeg,
      rightWaist: rightWaist ?? this.rightWaist,
      rightLeg: rightLeg ?? this.rightLeg,
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'left': <String, bool>{
        'waist': leftWaist,
        'leg': leftLeg,
      },
      'right': <String, bool>{
        'waist': rightWaist,
        'leg': rightLeg,
      },
    };
  }

  @override
  bool operator ==(Object other) {
    return other is MattressHeatingState &&
        other.leftWaist == leftWaist &&
        other.leftLeg == leftLeg &&
        other.rightWaist == rightWaist &&
        other.rightLeg == rightLeg;
  }

  @override
  int get hashCode {
    return Object.hash(leftWaist, leftLeg, rightWaist, rightLeg);
  }
}

@immutable
class MattressRealtimeMetrics {
  const MattressRealtimeMetrics({
    required this.heartRate,
    required this.breathRate,
  });

  final int heartRate;
  final int breathRate;

  MattressRealtimeMetrics copyWith({
    int? heartRate,
    int? breathRate,
  }) {
    return MattressRealtimeMetrics(
      heartRate: heartRate ?? this.heartRate,
      breathRate: breathRate ?? this.breathRate,
    );
  }
}

@immutable
class MattressSensorFlowState {
  const MattressSensorFlowState({
    this.enabled = false,
    this.leftEnabled = false,
    this.rightEnabled = false,
    this.intensity = 0.78,
    this.dataRate = 0.68,
  });

  static const MattressSensorFlowState defaults = MattressSensorFlowState();

  final bool enabled;
  final bool leftEnabled;
  final bool rightEnabled;
  final double intensity;
  final double dataRate;

  int get activeSideCount {
    if (!enabled) {
      return 0;
    }
    return <bool>[leftEnabled, rightEnabled]
        .where((bool sideEnabled) => sideEnabled)
        .length;
  }

  bool isSideEnabled(MattressSensorFlowSide side) {
    if (!enabled) {
      return false;
    }
    switch (side) {
      case MattressSensorFlowSide.left:
        return leftEnabled;
      case MattressSensorFlowSide.right:
        return rightEnabled;
    }
  }

  MattressSensorFlowState toggleSide(MattressSensorFlowSide side) {
    final bool currentLeft = isSideEnabled(MattressSensorFlowSide.left);
    final bool currentRight = isSideEnabled(MattressSensorFlowSide.right);
    final bool nextLeft =
        side == MattressSensorFlowSide.left ? !currentLeft : currentLeft;
    final bool nextRight =
        side == MattressSensorFlowSide.right ? !currentRight : currentRight;
    return copyWith(
      enabled: nextLeft || nextRight,
      leftEnabled: nextLeft,
      rightEnabled: nextRight,
    );
  }

  MattressSensorFlowState copyWith({
    bool? enabled,
    bool? leftEnabled,
    bool? rightEnabled,
    double? intensity,
    double? dataRate,
  }) {
    return MattressSensorFlowState(
      enabled: enabled ?? this.enabled,
      leftEnabled: leftEnabled ?? this.leftEnabled,
      rightEnabled: rightEnabled ?? this.rightEnabled,
      intensity: intensity ?? this.intensity,
      dataRate: dataRate ?? this.dataRate,
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'enabled': enabled,
      'leftEnabled': leftEnabled,
      'rightEnabled': rightEnabled,
      'intensity': intensity,
      'dataRate': dataRate,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is MattressSensorFlowState &&
        other.enabled == enabled &&
        other.leftEnabled == leftEnabled &&
        other.rightEnabled == rightEnabled &&
        other.intensity == intensity &&
        other.dataRate == dataRate;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      leftEnabled,
      rightEnabled,
      intensity,
      dataRate,
    );
  }
}

@immutable
class MattressRippleEffectState {
  const MattressRippleEffectState({
    this.enabled = false,
    this.leftEnabled = false,
    this.rightEnabled = false,
    this.intensity = 0.86,
  });

  static const MattressRippleEffectState off = MattressRippleEffectState();

  final bool enabled;
  final bool leftEnabled;
  final bool rightEnabled;
  final double intensity;

  int get activeSideCount {
    if (!enabled) {
      return 0;
    }
    return <bool>[leftEnabled, rightEnabled]
        .where((bool sideEnabled) => sideEnabled)
        .length;
  }

  MattressRippleSide? get activeSide {
    if (activeSideCount != 1) {
      return null;
    }
    if (leftEnabled) {
      return MattressRippleSide.left;
    }
    if (rightEnabled) {
      return MattressRippleSide.right;
    }
    return null;
  }

  String get summaryLabel {
    switch (activeSideCount) {
      case 0:
        return 'OFF';
      case 2:
        return 'BOTH';
      case 1:
        return activeSide!.name.toUpperCase();
    }
    return 'OFF';
  }

  bool isSideEnabled(MattressRippleSide side) {
    if (!enabled) {
      return false;
    }
    switch (side) {
      case MattressRippleSide.left:
        return leftEnabled;
      case MattressRippleSide.right:
        return rightEnabled;
    }
  }

  MattressRippleEffectState toggleSide(MattressRippleSide side) {
    final bool currentLeft = isSideEnabled(MattressRippleSide.left);
    final bool currentRight = isSideEnabled(MattressRippleSide.right);
    final bool nextLeft =
        side == MattressRippleSide.left ? !currentLeft : currentLeft;
    final bool nextRight =
        side == MattressRippleSide.right ? !currentRight : currentRight;
    return copyWith(
      enabled: nextLeft || nextRight,
      leftEnabled: nextLeft,
      rightEnabled: nextRight,
    );
  }

  MattressRippleEffectState copyWith({
    bool? enabled,
    bool? leftEnabled,
    bool? rightEnabled,
    double? intensity,
  }) {
    return MattressRippleEffectState(
      enabled: enabled ?? this.enabled,
      leftEnabled: leftEnabled ?? this.leftEnabled,
      rightEnabled: rightEnabled ?? this.rightEnabled,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'enabled': enabled,
      'leftEnabled': leftEnabled,
      'rightEnabled': rightEnabled,
      'intensity': intensity,
      'side': activeSide?.name,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is MattressRippleEffectState &&
        other.enabled == enabled &&
        other.leftEnabled == leftEnabled &&
        other.rightEnabled == rightEnabled &&
        other.intensity == intensity;
  }

  @override
  int get hashCode {
    return Object.hash(enabled, leftEnabled, rightEnabled, intensity);
  }
}

@immutable
class MattressTrendMetrics {
  const MattressTrendMetrics({
    required this.lumbarSupportIndex,
    required this.lumbarSupportStatus,
    required this.ergonomicIndex,
    required this.ergonomicStatus,
  });

  final double lumbarSupportIndex;
  final String lumbarSupportStatus;
  final double ergonomicIndex;
  final String ergonomicStatus;

  MattressTrendMetrics copyWith({
    double? lumbarSupportIndex,
    String? lumbarSupportStatus,
    double? ergonomicIndex,
    String? ergonomicStatus,
  }) {
    return MattressTrendMetrics(
      lumbarSupportIndex: lumbarSupportIndex ?? this.lumbarSupportIndex,
      lumbarSupportStatus: lumbarSupportStatus ?? this.lumbarSupportStatus,
      ergonomicIndex: ergonomicIndex ?? this.ergonomicIndex,
      ergonomicStatus: ergonomicStatus ?? this.ergonomicStatus,
    );
  }
}

@immutable
class MattressPressureChartData {
  const MattressPressureChartData({
    required this.currentValues,
    required this.recommendedValues,
    required this.markerIndex,
    this.markerValue,
    this.minValue = 5000,
    this.maxValue = 10000,
    this.labels = const <String>['肩部', '背部', '腰部', '臀部', '腿部'],
  });

  final List<double> currentValues;
  final List<double> recommendedValues;
  final int markerIndex;
  final double? markerValue;
  final double minValue;
  final double maxValue;
  final List<String> labels;

  double get visibleMarkerValue {
    if (markerValue != null) {
      return markerValue!;
    }
    if (currentValues.isEmpty) {
      return 0;
    }
    final int index = markerIndex.clamp(0, currentValues.length - 1);
    return currentValues[index];
  }

  MattressPressureChartData copyWith({
    List<double>? currentValues,
    List<double>? recommendedValues,
    int? markerIndex,
    double? markerValue,
    double? minValue,
    double? maxValue,
    List<String>? labels,
  }) {
    return MattressPressureChartData(
      currentValues: currentValues ?? this.currentValues,
      recommendedValues: recommendedValues ?? this.recommendedValues,
      markerIndex: markerIndex ?? this.markerIndex,
      markerValue: markerValue ?? this.markerValue,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      labels: labels ?? this.labels,
    );
  }
}

@immutable
class MattressZoneTarget {
  const MattressZoneTarget({
    required this.pressure,
    required this.glow,
  });

  final double pressure;
  final double glow;

  Map<String, Object> toJson() {
    return <String, Object>{
      'pressure': pressure,
      'glow': glow,
    };
  }
}

@immutable
class MattressModeMetrics {
  const MattressModeMetrics({
    required this.pressureValues,
    required this.targets,
    this.warningKey,
  });

  final Map<String, int> pressureValues;
  final Map<String, MattressZoneTarget> targets;
  final String? warningKey;

  MattressModeMetrics copyWith({
    Map<String, int>? pressureValues,
    Map<String, MattressZoneTarget>? targets,
    String? warningKey,
  }) {
    return MattressModeMetrics(
      pressureValues: pressureValues ?? this.pressureValues,
      targets: targets ?? this.targets,
      warningKey: warningKey ?? this.warningKey,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'values': pressureValues,
      'targets': <String, Object>{
        for (final MapEntry<String, MattressZoneTarget> entry
            in targets.entries)
          entry.key: entry.value.toJson(),
      },
      if (warningKey != null) 'warning': warningKey,
    };
  }
}

@immutable
class MattressDashboardData {
  const MattressDashboardData({
    required this.realtime,
    required this.sensorFlow,
    required this.rippleEffect,
    required this.trend,
    required this.pressureChart,
    required this.modeMetrics,
  });

  static const MattressDashboardData defaults = MattressDashboardData(
    realtime: MattressRealtimeMetrics(
      heartRate: 70,
      breathRate: 16,
    ),
    sensorFlow: MattressSensorFlowState.defaults,
    rippleEffect: MattressRippleEffectState.off,
    trend: MattressTrendMetrics(
      lumbarSupportIndex: 84,
      lumbarSupportStatus: '优秀',
      ergonomicIndex: 80,
      ergonomicStatus: '良好',
    ),
    pressureChart: MattressPressureChartData(
      currentValues: <double>[7200, 8650, 7850, 9100, 7050],
      recommendedValues: <double>[6800, 7600, 7400, 8100, 6900],
      markerIndex: 4,
      markerValue: 7056,
    ),
    modeMetrics: <AdjustmentMode, MattressModeMetrics>{
      AdjustmentMode.auto: MattressModeMetrics(
        pressureValues: <String, int>{
          'shoulder': 48,
          'back': 64,
          'waist': 82,
          'hip': 58,
          'leg': 42,
        },
        targets: <String, MattressZoneTarget>{
          'shoulder': MattressZoneTarget(pressure: 0.38, glow: 0.35),
          'back': MattressZoneTarget(pressure: 0.58, glow: 0.62),
          'waist': MattressZoneTarget(pressure: 0.86, glow: 1),
          'hip': MattressZoneTarget(pressure: 0.52, glow: 0.48),
          'leg': MattressZoneTarget(pressure: 0.32, glow: 0.35),
        },
      ),
      AdjustmentMode.zero: MattressModeMetrics(
        pressureValues: <String, int>{
          'shoulder': 78,
          'back': 88,
          'waist': 62,
          'hip': 68,
          'leg': 86,
        },
        targets: <String, MattressZoneTarget>{
          'shoulder': MattressZoneTarget(pressure: 0.78, glow: 0.9),
          'back': MattressZoneTarget(pressure: 0.88, glow: 0.78),
          'waist': MattressZoneTarget(pressure: 0.56, glow: 0.45),
          'hip': MattressZoneTarget(pressure: 0.64, glow: 0.52),
          'leg': MattressZoneTarget(pressure: 0.82, glow: 0.92),
        },
      ),
      AdjustmentMode.left: MattressModeMetrics(
        pressureValues: <String, int>{
          'shoulder': 56,
          'back': 84,
          'waist': 92,
          'hip': 64,
          'leg': 46,
        },
        targets: <String, MattressZoneTarget>{
          'shoulder': MattressZoneTarget(pressure: 0.46, glow: 0.42),
          'back': MattressZoneTarget(pressure: 0.82, glow: 0.86),
          'waist': MattressZoneTarget(pressure: 0.96, glow: 1),
          'hip': MattressZoneTarget(pressure: 0.6, glow: 0.62),
          'leg': MattressZoneTarget(pressure: 0.34, glow: 0.35),
        },
      ),
      AdjustmentMode.right: MattressModeMetrics(
        pressureValues: <String, int>{
          'shoulder': 54,
          'back': 82,
          'waist': 90,
          'hip': 66,
          'leg': 48,
        },
        targets: <String, MattressZoneTarget>{
          'shoulder': MattressZoneTarget(pressure: 0.44, glow: 0.42),
          'back': MattressZoneTarget(pressure: 0.8, glow: 0.86),
          'waist': MattressZoneTarget(pressure: 0.94, glow: 1),
          'hip': MattressZoneTarget(pressure: 0.62, glow: 0.62),
          'leg': MattressZoneTarget(pressure: 0.36, glow: 0.35),
        },
      ),
      AdjustmentMode.deep: MattressModeMetrics(
        pressureValues: <String, int>{
          'shoulder': 38,
          'back': 58,
          'waist': 88,
          'hip': 82,
          'leg': 44,
        },
        warningKey: 'hip',
        targets: <String, MattressZoneTarget>{
          'shoulder': MattressZoneTarget(pressure: 0.22, glow: 0.18),
          'back': MattressZoneTarget(pressure: 0.5, glow: 0.44),
          'waist': MattressZoneTarget(pressure: 0.9, glow: 0.96),
          'hip': MattressZoneTarget(pressure: 0.84, glow: 0.86),
          'leg': MattressZoneTarget(pressure: 0.3, glow: 0.28),
        },
      ),
      AdjustmentMode.flat: MattressModeMetrics(
        pressureValues: <String, int>{
          'shoulder': 32,
          'back': 34,
          'waist': 36,
          'hip': 34,
          'leg': 31,
        },
        targets: <String, MattressZoneTarget>{
          'shoulder': MattressZoneTarget(pressure: 0.16, glow: 0.12),
          'back': MattressZoneTarget(pressure: 0.18, glow: 0.12),
          'waist': MattressZoneTarget(pressure: 0.2, glow: 0.12),
          'hip': MattressZoneTarget(pressure: 0.18, glow: 0.12),
          'leg': MattressZoneTarget(pressure: 0.16, glow: 0.12),
        },
      ),
    },
  );

  final MattressRealtimeMetrics realtime;
  final MattressSensorFlowState sensorFlow;
  final MattressRippleEffectState rippleEffect;
  final MattressTrendMetrics trend;
  final MattressPressureChartData pressureChart;
  final Map<AdjustmentMode, MattressModeMetrics> modeMetrics;

  MattressModeMetrics metricsFor(AdjustmentMode mode) {
    return modeMetrics[mode] ??
        defaults.modeMetrics[mode] ??
        defaults.modeMetrics[AdjustmentMode.flat]!;
  }

  MattressDashboardData copyWith({
    MattressRealtimeMetrics? realtime,
    MattressSensorFlowState? sensorFlow,
    MattressRippleEffectState? rippleEffect,
    MattressTrendMetrics? trend,
    MattressPressureChartData? pressureChart,
    Map<AdjustmentMode, MattressModeMetrics>? modeMetrics,
  }) {
    return MattressDashboardData(
      realtime: realtime ?? this.realtime,
      sensorFlow: sensorFlow ?? this.sensorFlow,
      rippleEffect: rippleEffect ?? this.rippleEffect,
      trend: trend ?? this.trend,
      pressureChart: pressureChart ?? this.pressureChart,
      modeMetrics: modeMetrics ?? this.modeMetrics,
    );
  }

  MattressDashboardData copyWithModeMetrics(
    AdjustmentMode mode,
    MattressModeMetrics metrics,
  ) {
    return copyWith(
      modeMetrics: <AdjustmentMode, MattressModeMetrics>{
        ...modeMetrics,
        mode: metrics,
      },
    );
  }

  Map<String, Object?> toWebViewPayload() {
    return <String, Object?>{
      'sensorFlow': sensorFlow.toJson(),
      'modes': <String, Object?>{
        for (final MapEntry<AdjustmentMode, MattressModeMetrics> entry
            in modeMetrics.entries)
          entry.key.rawValue: entry.value.toJson(),
      },
    };
  }
}

class MattressDashboardController extends ValueNotifier<MattressDashboardData> {
  MattressDashboardController({
    MattressDashboardData initialData = MattressDashboardData.defaults,
  }) : super(initialData);

  MattressDashboardData get data => value;

  void replace(MattressDashboardData nextData) {
    value = nextData;
  }

  void update(
    MattressDashboardData Function(MattressDashboardData current) transform,
  ) {
    value = transform(value);
  }

  void updateRealtime({
    int? heartRate,
    int? breathRate,
  }) {
    update((MattressDashboardData current) {
      return current.copyWith(
        realtime: current.realtime.copyWith(
          heartRate: heartRate,
          breathRate: breathRate,
        ),
      );
    });
  }

  void updateSensorFlow({
    bool? enabled,
    bool? leftEnabled,
    bool? rightEnabled,
    double? intensity,
    double? dataRate,
  }) {
    update((MattressDashboardData current) {
      return current.copyWith(
        sensorFlow: current.sensorFlow.copyWith(
          enabled: enabled,
          leftEnabled: leftEnabled,
          rightEnabled: rightEnabled,
          intensity: _clampUnit(intensity),
          dataRate: _clampUnit(dataRate),
        ),
      );
    });
  }

  void updateRippleEffect({
    bool? enabled,
    bool? leftEnabled,
    bool? rightEnabled,
    double? intensity,
  }) {
    update((MattressDashboardData current) {
      return current.copyWith(
        rippleEffect: current.rippleEffect.copyWith(
          enabled: enabled,
          leftEnabled: leftEnabled,
          rightEnabled: rightEnabled,
          intensity: _clampUnit(intensity),
        ),
      );
    });
  }

  void updateTrend({
    double? lumbarSupportIndex,
    String? lumbarSupportStatus,
    double? ergonomicIndex,
    String? ergonomicStatus,
  }) {
    update((MattressDashboardData current) {
      return current.copyWith(
        trend: current.trend.copyWith(
          lumbarSupportIndex: lumbarSupportIndex,
          lumbarSupportStatus: lumbarSupportStatus,
          ergonomicIndex: ergonomicIndex,
          ergonomicStatus: ergonomicStatus,
        ),
      );
    });
  }

  void updatePressureChart(MattressPressureChartData pressureChart) {
    update((MattressDashboardData current) {
      return current.copyWith(pressureChart: pressureChart);
    });
  }

  void updateModeMetrics(
    AdjustmentMode mode,
    MattressModeMetrics metrics,
  ) {
    update((MattressDashboardData current) {
      return current.copyWithModeMetrics(mode, metrics);
    });
  }

  void applyPayload(Map<String, Object?> payload) {
    update((MattressDashboardData current) {
      MattressDashboardData next = current;

      final Map<String, Object?>? realtime = _asObjectMap(payload['realtime']);
      if (realtime != null) {
        next = next.copyWith(
          realtime: next.realtime.copyWith(
            heartRate: _asInt(realtime['heartRate']),
            breathRate: _asInt(realtime['breathRate']),
          ),
        );
      }

      final Map<String, Object?>? sensorFlow =
          _asObjectMap(payload['sensorFlow']);
      if (sensorFlow != null) {
        next = next.copyWith(
          sensorFlow: next.sensorFlow.copyWith(
            enabled: _asBool(sensorFlow['enabled']),
            leftEnabled: _asBool(sensorFlow['leftEnabled']),
            rightEnabled: _asBool(sensorFlow['rightEnabled']),
            intensity: _clampUnit(_asDouble(sensorFlow['intensity'])),
            dataRate: _clampUnit(_asDouble(sensorFlow['dataRate'])),
          ),
        );
      }

      final Map<String, Object?>? rippleEffect =
          _asObjectMap(payload['rippleEffect']);
      if (rippleEffect != null) {
        next = next.copyWith(
          rippleEffect: next.rippleEffect.copyWith(
            enabled: _asBool(rippleEffect['enabled']),
            leftEnabled: _asBool(rippleEffect['leftEnabled']),
            rightEnabled: _asBool(rippleEffect['rightEnabled']),
            intensity: _clampUnit(_asDouble(rippleEffect['intensity'])),
          ),
        );
      }

      final Map<String, Object?>? trend = _asObjectMap(payload['trend']);
      if (trend != null) {
        next = next.copyWith(
          trend: next.trend.copyWith(
            lumbarSupportIndex: _asDouble(trend['lumbarSupportIndex']),
            lumbarSupportStatus: _asString(trend['lumbarSupportStatus']),
            ergonomicIndex: _asDouble(trend['ergonomicIndex']),
            ergonomicStatus: _asString(trend['ergonomicStatus']),
          ),
        );
      }

      final Map<String, Object?>? pressureChart =
          _asObjectMap(payload['pressureChart']);
      if (pressureChart != null) {
        next = next.copyWith(
          pressureChart: next.pressureChart.copyWith(
            currentValues: _asDoubleList(pressureChart['currentValues']),
            recommendedValues:
                _asDoubleList(pressureChart['recommendedValues']),
            markerIndex: _asInt(pressureChart['markerIndex']),
            markerValue: _asDouble(pressureChart['markerValue']),
            minValue: _asDouble(pressureChart['minValue']),
            maxValue: _asDouble(pressureChart['maxValue']),
            labels: _asStringList(pressureChart['labels']),
          ),
        );
      }

      final Map<String, Object?>? modes = _asObjectMap(payload['modes']);
      if (modes != null) {
        for (final MapEntry<String, Object?> entry in modes.entries) {
          final AdjustmentMode? mode = AdjustmentMode.tryParse(entry.key);
          final Map<String, Object?>? modePayload = _asObjectMap(entry.value);
          if (mode == null || modePayload == null) {
            continue;
          }

          final MattressModeMetrics currentMetrics = next.metricsFor(mode);
          final Map<String, int> pressureValues = <String, int>{
            ...currentMetrics.pressureValues
          };
          final Map<String, MattressZoneTarget> targets =
              <String, MattressZoneTarget>{...currentMetrics.targets};

          final Map<String, Object?>? values =
              _asObjectMap(modePayload['values']);
          if (values != null) {
            for (final String key in _pressureZoneKeys) {
              final int? value = _asInt(values[key]);
              if (value != null) {
                pressureValues[key] = math.max(0, math.min(100, value));
              }
            }
          }

          final Map<String, Object?>? targetPayloads =
              _asObjectMap(modePayload['targets']);
          if (targetPayloads != null) {
            for (final String key in _pressureZoneKeys) {
              final Map<String, Object?>? targetPayload =
                  _asObjectMap(targetPayloads[key]);
              if (targetPayload == null) {
                continue;
              }
              final MattressZoneTarget baseTarget = targets[key] ??
                  const MattressZoneTarget(pressure: 0, glow: 0);
              final double pressure =
                  _asDouble(targetPayload['pressure']) ?? baseTarget.pressure;
              final double glow =
                  _asDouble(targetPayload['glow']) ?? baseTarget.glow;
              targets[key] = MattressZoneTarget(
                pressure: math.max(0, math.min(1, pressure)),
                glow: math.max(0, math.min(1, glow)),
              );
            }
          }

          final String? warningKey = modePayload.containsKey('warning')
              ? _asString(modePayload['warning'])
              : currentMetrics.warningKey;

          next = next.copyWithModeMetrics(
            mode,
            currentMetrics.copyWith(
              pressureValues: pressureValues,
              targets: targets,
              warningKey: warningKey,
            ),
          );
        }
      }

      return next;
    });
  }
}

Map<String, Object?>? _asObjectMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return <String, Object?>{
    for (final MapEntry<Object?, Object?> entry in value.entries)
      entry.key.toString(): entry.value,
  };
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

bool? _asBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final String normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}

double? _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

double? _clampUnit(double? value) {
  if (value == null) {
    return null;
  }
  return math.max(0, math.min(1, value));
}

String? _asString(Object? value) {
  return value is String ? value : null;
}

List<double>? _asDoubleList(Object? value) {
  if (value is! List) {
    return null;
  }
  return value.map(_asDouble).whereType<double>().toList(growable: false);
}

List<String>? _asStringList(Object? value) {
  if (value is! List) {
    return null;
  }
  return value.map(_asString).whereType<String>().toList(growable: false);
}

Stream<Map<String, Object?>> buildMockDashboardPayloadStream({
  Duration interval = const Duration(seconds: 2),
}) {
  return Stream<Map<String, Object?>>.periodic(
    interval,
    (int tick) => _mockDashboardPayload(tick),
  ).asBroadcastStream();
}

Map<String, Object?> _mockDashboardPayload(int tick) {
  final double phase = tick / 4;
  final int heartRate = 72 + (math.sin(phase) * 8).round();
  final int breathRate = 16 + (math.cos(phase * 0.85) * 2).round();
  final double lumbarSupportIndex = 84 + math.sin(phase * 0.7) * 7;
  final double ergonomicIndex = 80 + math.cos(phase * 0.6) * 6;

  double wave(int index, double offset, double amplitude) {
    return 7200 +
        math.sin(phase + offset + index * 0.62) * amplitude +
        index * 180;
  }

  Map<String, Object?> modePayload(
    AdjustmentMode mode, {
    required double offset,
    String? warning,
  }) {
    final MattressModeMetrics base =
        MattressDashboardData.defaults.metricsFor(mode);
    final Map<String, int> values = <String, int>{};
    for (int index = 0; index < _pressureZoneKeys.length; index += 1) {
      final String key = _pressureZoneKeys[index];
      final int baseValue = base.pressureValues[key] ?? 40;
      final int drift = (math.sin(phase + offset + index * 0.8) * 7).round();
      values[key] = math.max(0, math.min(100, baseValue + drift));
    }
    return <String, Object?>{
      'values': values,
      'targets': <String, Object?>{
        for (final String key in _pressureZoneKeys)
          key: <String, Object?>{
            'pressure': math.max(
              0,
              math.min(
                1,
                (base.targets[key]?.pressure ?? 0.3) +
                    math.sin(phase + offset) * 0.05,
              ),
            ),
            'glow': math.max(
              0,
              math.min(
                1,
                (base.targets[key]?.glow ?? 0.3) +
                    math.cos(phase + offset) * 0.05,
              ),
            ),
          },
      },
      'warning': warning,
    };
  }

  return <String, Object?>{
    'realtime': <String, Object?>{
      'heartRate': heartRate,
      'breathRate': breathRate,
    },
    'trend': <String, Object?>{
      'lumbarSupportIndex': lumbarSupportIndex,
      'lumbarSupportStatus': lumbarSupportIndex >= 88 ? '优秀' : '稳定',
      'ergonomicIndex': ergonomicIndex,
      'ergonomicStatus': ergonomicIndex >= 82 ? '良好' : '波动',
    },
    'pressureChart': <String, Object?>{
      'currentValues': <double>[
        wave(0, 0.2, 540),
        wave(1, 0.4, 690),
        wave(2, 0.6, 730),
        wave(3, 0.9, 680),
        wave(4, 1.1, 520),
      ],
      'recommendedValues': const <double>[6800, 7600, 7400, 8100, 6900],
      'markerIndex': tick % _pressureZoneKeys.length,
      'markerValue': wave(tick % _pressureZoneKeys.length, 0.45, 660),
    },
    'modes': <String, Object?>{
      AdjustmentMode.flat.rawValue: modePayload(
        AdjustmentMode.flat,
        offset: 0.2,
      ),
      AdjustmentMode.auto.rawValue: modePayload(
        AdjustmentMode.auto,
        offset: 0.45,
      ),
      AdjustmentMode.left.rawValue: modePayload(
        AdjustmentMode.left,
        offset: 0.75,
      ),
      AdjustmentMode.right.rawValue: modePayload(
        AdjustmentMode.right,
        offset: 1.05,
      ),
      AdjustmentMode.zero.rawValue: modePayload(
        AdjustmentMode.zero,
        offset: 1.35,
      ),
      AdjustmentMode.deep.rawValue: modePayload(
        AdjustmentMode.deep,
        offset: 1.65,
        warning: 'hip',
      ),
    },
  };
}

class SmartMattressShowroomApp extends StatelessWidget {
  const SmartMattressShowroomApp({
    required this.config,
    this.dashboardData = MattressDashboardData.defaults,
    this.dashboardController,
    this.dashboardPayloadStream,
    super.key,
  });

  final AppEnvironmentConfig config;
  final MattressDashboardData dashboardData;
  final MattressDashboardController? dashboardController;
  final Stream<Map<String, Object?>>? dashboardPayloadStream;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appTitle,
      color: Colors.black,
      home: Builder(
        builder: (BuildContext context) {
          return ShowroomHomePage(
            onEnterSmartMattress: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return ShowroomDashboardPage(
                      dashboardData: dashboardData,
                      dashboardController: dashboardController,
                      dashboardPayloadStream: dashboardPayloadStream,
                    );
                  },
                ),
              );
            },
            onEnterLightSmartMattress: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return ShowroomDashboardPage(
                      profile: ShowroomDashboardProfile.light,
                      dashboardData: dashboardData,
                      dashboardController: dashboardController,
                      dashboardPayloadStream: dashboardPayloadStream,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ShowroomHomePage extends StatelessWidget {
  const ShowroomHomePage({
    required this.onEnterSmartMattress,
    required this.onEnterLightSmartMattress,
    super.key,
  });

  final VoidCallback onEnterSmartMattress;
  final VoidCallback onEnterLightSmartMattress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const RepaintBoundary(
            child: CustomPaint(
              painter: _HomeBackgroundPainter(),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compactLandscape = constraints.maxHeight < 520 &&
                    constraints.maxWidth > constraints.maxHeight;
                final bool stacked =
                    constraints.maxWidth < 720 && !compactLandscape;
                final EdgeInsets padding = compactLandscape
                    ? const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      )
                    : EdgeInsets.symmetric(
                        horizontal: stacked ? 24 : 76,
                        vertical: stacked ? 22 : 42,
                      );

                return Padding(
                  padding: padding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _HomeHeader(compact: compactLandscape),
                          SizedBox(
                              height: compactLandscape
                                  ? 14
                                  : stacked
                                      ? 18
                                      : 42),
                          Expanded(
                            child: stacked
                                ? Column(
                                    children: <Widget>[
                                      Expanded(
                                        child: _HomeEntryCard(
                                          title: '智能床垫大屏入口',
                                          eyebrow: 'SMART MATTRESS',
                                          status: '在线',
                                          summary: '实时监测、分区调节、3D床垫联动展示',
                                          metrics: const <String>[
                                            '心率',
                                            '呼吸',
                                            '气压',
                                          ],
                                          icon: Icons.king_bed_outlined,
                                          accent: _rgb(57, 215, 255),
                                          onTap: onEnterSmartMattress,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: _HomeEntryCard(
                                          title: '轻智能床垫大屏入口',
                                          eyebrow: 'LIGHT SMART',
                                          status: '在线',
                                          summary: '心率呼吸强化监测、轻量睡眠态势展示',
                                          metrics: const <String>[
                                            '心率',
                                            '呼吸率',
                                            '趋势',
                                          ],
                                          icon: Icons.bedtime_outlined,
                                          accent: _rgb(71, 216, 147),
                                          onTap: onEnterLightSmartMattress,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Expanded(
                                        child: _HomeEntryCard(
                                          title: '智能床垫大屏入口',
                                          eyebrow: 'SMART MATTRESS',
                                          status: '在线',
                                          summary: '实时监测、分区调节、3D床垫联动展示',
                                          metrics: const <String>[
                                            '心率',
                                            '呼吸',
                                            '气压',
                                          ],
                                          icon: Icons.king_bed_outlined,
                                          accent: _rgb(57, 215, 255),
                                          onTap: onEnterSmartMattress,
                                        ),
                                      ),
                                      const SizedBox(width: 28),
                                      Expanded(
                                        child: _HomeEntryCard(
                                          title: '轻智能床垫大屏入口',
                                          eyebrow: 'LIGHT SMART',
                                          status: '在线',
                                          summary: '心率呼吸强化监测、轻量睡眠态势展示',
                                          metrics: const <String>[
                                            '心率',
                                            '呼吸率',
                                            '趋势',
                                          ],
                                          icon: Icons.bedtime_outlined,
                                          accent: _rgb(71, 216, 147),
                                          onTap: onEnterLightSmartMattress,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          if (!compactLandscape) ...<Widget>[
                            SizedBox(height: stacked ? 16 : 28),
                            const _HomeStatusStrip(),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'SMART SLEEP SHOWROOM',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _rgb(57, 215, 255, 0.74),
                  fontSize: compact ? 11 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: compact ? 1.4 : 2.4,
                ),
              ),
              SizedBox(height: compact ? 5 : 10),
              Text(
                '智能睡眠展厅',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _rgb(244, 248, 255),
                  fontSize: compact ? 28 : 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  shadows: <Shadow>[
                    Shadow(
                      color: _rgb(36, 150, 255, 0.38),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        const _HomeSignalBadge(),
      ],
    );
  }
}

class _HomeSignalBadge extends StatelessWidget {
  const _HomeSignalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: _rgb(26, 111, 210, 0.16),
        shape: StadiumBorder(
          side: BorderSide(color: _rgb(86, 184, 255, 0.30)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _rgb(71, 216, 147),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _rgb(71, 216, 147, 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'READY',
            style: TextStyle(
              color: _rgb(198, 224, 255),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeEntryCard extends StatelessWidget {
  const _HomeEntryCard({
    required this.title,
    required this.eyebrow,
    required this.status,
    required this.summary,
    required this.metrics,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String eyebrow;
  final String status;
  final String summary;
  final List<String> metrics;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                _rgb(10, 30, 53, 0.90),
                _rgb(5, 18, 34, 0.88),
              ],
            ),
            border: Border.all(color: accent.withOpacity(0.28)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 36,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact =
                  constraints.maxHeight < 360 || constraints.maxWidth < 360;
              final bool short = constraints.maxHeight < 280;
              final bool veryShort = constraints.maxHeight < 260;
              final bool showMetrics = constraints.maxHeight >= 300;
              final double padding = short
                  ? 14
                  : compact
                      ? 18
                      : 28;
              final double iconSize = short
                  ? 34
                  : compact
                      ? 42
                      : 54;
              final double iconGlyphSize = short
                  ? 20
                  : compact
                      ? 24
                      : 30;
              final double titleSize = short
                  ? 20
                  : compact
                      ? 24
                      : 31;

              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      right: -54,
                      top: -58,
                      child: Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              accent.withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.white.withOpacity(0.035),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: accent.withOpacity(0.14),
                                  border: Border.all(
                                    color: accent.withOpacity(0.34),
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: accent,
                                  size: iconGlyphSize,
                                ),
                              ),
                              const Spacer(),
                              _HomeStatusPill(label: status, accent: accent),
                            ],
                          ),
                          if (short)
                            SizedBox(height: veryShort ? 8 : 12)
                          else
                            const Spacer(),
                          Text(
                            eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent.withOpacity(0.82),
                              fontSize: compact ? 11 : 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: compact ? 1.2 : 1.8,
                            ),
                          ),
                          SizedBox(
                              height: short
                                  ? 4
                                  : compact
                                      ? 6
                                      : 12),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _rgb(244, 248, 255),
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              shadows: <Shadow>[
                                Shadow(
                                  color: accent.withOpacity(0.30),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          if (!veryShort) ...<Widget>[
                            SizedBox(
                                height: short
                                    ? 5
                                    : compact
                                        ? 8
                                        : 14),
                            Text(
                              summary,
                              maxLines: compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _rgb(220, 232, 250, 0.70),
                                fontSize: short
                                    ? 12
                                    : compact
                                        ? 13
                                        : 16,
                                height: compact ? 1.25 : 1.45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (showMetrics) ...<Widget>[
                              SizedBox(height: compact ? 12 : 22),
                              Wrap(
                                spacing: compact ? 7 : 10,
                                runSpacing: compact ? 7 : 10,
                                children: metrics
                                    .map(
                                      (String metric) => _HomeMetricChip(
                                        label: metric,
                                        accent: accent,
                                        compact: compact,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                          if (short)
                            SizedBox(height: veryShort ? 8 : 12)
                          else
                            const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _HomeEnterButton(
                              accent: accent,
                              compact: compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeStatusPill extends StatelessWidget {
  const _HomeStatusPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        color: accent.withOpacity(0.12),
        shape: StadiumBorder(
          side: BorderSide(color: accent.withOpacity(0.30)),
        ),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _HomeMetricChip extends StatelessWidget {
  const _HomeMetricChip({
    required this.label,
    required this.accent,
    required this.compact,
  });

  final String label;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 24 : 28,
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _rgb(9, 35, 66, 0.70),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: _rgb(235, 247, 255, 0.82),
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _HomeEnterButton extends StatelessWidget {
  const _HomeEnterButton({required this.accent, required this.compact});

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 36 : 42,
      padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: <Color>[
            accent.withOpacity(0.74),
            _rgb(18, 85, 178, 0.58),
          ],
        ),
        border: Border.all(color: _rgb(147, 224, 255, 0.60)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withOpacity(0.28),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '进入大屏',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: compact ? 16 : 18,
          ),
        ],
      ),
    );
  }
}

class _HomeStatusStrip extends StatelessWidget {
  const _HomeStatusStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _rgb(5, 18, 34, 0.66),
        border: Border.all(color: _rgb(73, 156, 255, 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.sensors_rounded,
            size: 18,
            color: _rgb(57, 215, 255, 0.80),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SHOWROOM ROUTER  |  APP ENVIRONMENT READY  |  DISPLAY MODE LANDSCAPE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _rgb(225, 235, 250, 0.58),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBackgroundPainter extends CustomPainter {
  const _HomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const Size designSize = Size(_designWidth, _designHeight);
    final double scale = math.max(
      size.width / designSize.width,
      size.height / designSize.height,
    );
    final Offset offset = Offset(
      (size.width - designSize.width * scale) * 0.5,
      (size.height - designSize.height * scale) * 0.5,
    );

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    _paintDesign(canvas);
    canvas.restore();
  }

  void _paintDesign(Canvas canvas) {
    const Rect full = Rect.fromLTWH(0, 0, _designWidth, _designHeight);
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xff010812),
            Color(0xff020d1c),
            Color(0xff010712),
          ],
        ).createShader(full),
    );
    _fillRadial(
      canvas,
      const Offset(960, 540),
      700,
      _rgb(36, 150, 255, 0.20),
    );
    _fillRadial(
      canvas,
      const Offset(320, 190),
      460,
      _rgb(57, 215, 255, 0.11),
    );
    _fillRadial(
      canvas,
      const Offset(1580, 230),
      460,
      _rgb(71, 216, 147, 0.09),
    );

    final Path grid = Path();
    for (double x = 0; x <= _designWidth; x += 48) {
      grid
        ..moveTo(x, 0)
        ..lineTo(x, _designHeight);
    }
    for (double y = 0; y <= _designHeight; y += 48) {
      grid
        ..moveTo(0, y)
        ..lineTo(_designWidth, y);
    }
    canvas.drawPath(
      grid,
      Paint()
        ..color = _rgb(52, 153, 255, 0.042)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final Paint linePaint = Paint()
      ..color = _rgb(57, 151, 255, 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(
      Path()
        ..moveTo(310, 174)
        ..lineTo(760, 174)
        ..moveTo(1160, 174)
        ..lineTo(1610, 174)
        ..moveTo(350, 900)
        ..lineTo(1570, 900),
      linePaint,
    );

    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.transparent,
            Colors.black.withOpacity(0.50),
          ],
          stops: const <double>[0.58, 1],
        ).createShader(
          Rect.fromCircle(center: const Offset(960, 540), radius: 1080),
        ),
    );
  }

  void _fillRadial(Canvas canvas, Offset center, double radius, Color color) {
    final Rect bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawOval(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[color, Colors.transparent],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant _HomeBackgroundPainter oldDelegate) => false;
}

class ShowroomDashboardPage extends StatefulWidget {
  const ShowroomDashboardPage({
    this.profile = ShowroomDashboardProfile.smart,
    this.dashboardData = MattressDashboardData.defaults,
    this.dashboardController,
    this.dashboardPayloadStream,
    super.key,
  });

  final ShowroomDashboardProfile profile;
  final MattressDashboardData dashboardData;
  final MattressDashboardController? dashboardController;
  final Stream<Map<String, Object?>>? dashboardPayloadStream;

  @override
  State<ShowroomDashboardPage> createState() => _ShowroomDashboardPageState();
}

class _ShowroomDashboardPageState extends State<ShowroomDashboardPage> {
  static const Duration _dashboardFrameInterval = Duration(milliseconds: 33);

  late final ValueNotifier<int> _repaint;
  late final SmartMattressSceneEmbedController _sceneController;
  Timer? _repaintTimer;
  StreamSubscription<Map<String, Object?>>? _dashboardPayloadSubscription;

  AdjustmentMode _selectedMode = AdjustmentMode.flat;
  MattressHeatingState _heating = MattressHeatingState.off;
  int _modeRestartToken = 0;
  int _resetToken = 0;

  bool _webViewReady = false;
  bool _webViewLoading = true;
  String? _webViewError;
  _LightCenterPanelView _lightCenterPanelView = _LightCenterPanelView.controls;

  AdjustmentMode? _lastMode;
  MattressHeatingState? _lastHeating;
  MattressDashboardData? _lastDashboardData;
  MattressRippleEffectState? _lastRippleEffect;
  int? _lastModeRestartToken;
  int? _lastResetToken;
  late MattressDashboardController _dashboardController;
  bool _ownsDashboardController = false;

  @override
  void initState() {
    super.initState();
    _attachDashboardController(widget.dashboardController);
    _attachDashboardPayloadStream(widget.dashboardPayloadStream);
    _repaint = ValueNotifier<int>(0);
    _repaintTimer = Timer.periodic(_dashboardFrameInterval, (_) {
      if (mounted) {
        _repaint.value += 1;
      }
    });
    _sceneController = createSmartMattressSceneEmbedController(
      onReady: _handleSceneReady,
      onLoading: _handleSceneLoading,
      onError: _handleSceneError,
    );
    unawaited(_sceneController.load());
  }

  @override
  void dispose() {
    _repaintTimer?.cancel();
    unawaited(_sceneController.dispose());
    unawaited(_dashboardPayloadSubscription?.cancel());
    _detachDashboardController();
    _repaint.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ShowroomDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dashboardController != widget.dashboardController) {
      final MattressDashboardData currentData = _dashboardData;
      _detachDashboardController();
      _attachDashboardController(
        widget.dashboardController,
        seedData: currentData,
      );
      unawaited(_applySmartMattressState());
      return;
    }
    if (oldWidget.dashboardPayloadStream != widget.dashboardPayloadStream) {
      unawaited(_dashboardPayloadSubscription?.cancel());
      _attachDashboardPayloadStream(widget.dashboardPayloadStream);
    }
    if (_ownsDashboardController &&
        oldWidget.dashboardData != widget.dashboardData) {
      _dashboardController.replace(widget.dashboardData);
    }
  }

  MattressDashboardData get _dashboardData => _dashboardController.data;

  void _attachDashboardController(
    MattressDashboardController? controller, {
    MattressDashboardData? seedData,
  }) {
    _ownsDashboardController = controller == null;
    _dashboardController = controller ??
        MattressDashboardController(
          initialData: seedData ?? widget.dashboardData,
        );
    _dashboardController.addListener(_handleDashboardDataChanged);
  }

  void _detachDashboardController() {
    _dashboardController.removeListener(_handleDashboardDataChanged);
    if (_ownsDashboardController) {
      _dashboardController.dispose();
    }
  }

  void _attachDashboardPayloadStream(Stream<Map<String, Object?>>? stream) {
    if (stream == null) {
      _dashboardPayloadSubscription = null;
      return;
    }
    _dashboardPayloadSubscription = stream.listen(
      (Map<String, Object?> payload) {
        _dashboardController.applyPayload(payload);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('SmartMattress dashboard payload stream error: $error');
      },
    );
  }

  void _handleDashboardDataChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    unawaited(_applySmartMattressState());
  }

  void _handleSceneReady() {
    if (!mounted) {
      return;
    }
    setState(() {
      _webViewReady = true;
      _webViewLoading = false;
      _webViewError = null;
    });
    unawaited(_applySmartMattressState());
  }

  void _handleSceneLoading(bool loading) {
    if (!mounted) {
      return;
    }
    setState(() {
      _webViewLoading = loading;
      if (loading) {
        _webViewError = null;
      }
    });
  }

  void _handleSceneError(String? error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _webViewLoading = false;
      _webViewError = error;
      if (error != null) {
        _webViewReady = false;
      }
    });
  }

  Future<void> _applySmartMattressState() async {
    if (!_webViewReady) {
      return;
    }

    final bool shouldApplyMode = _lastMode != _selectedMode ||
        _lastModeRestartToken != _modeRestartToken;
    final bool shouldApplyHeating = _lastHeating != _heating;
    final bool shouldApplyDashboardData = _lastDashboardData != _dashboardData;
    final bool shouldApplyRippleEffect =
        _lastRippleEffect != _dashboardData.rippleEffect;
    final bool shouldApplyReset = _lastResetToken != _resetToken;
    if (!shouldApplyMode &&
        !shouldApplyHeating &&
        !shouldApplyDashboardData &&
        !shouldApplyRippleEffect &&
        !shouldApplyReset) {
      return;
    }

    try {
      await _sceneController.applyUpdate(
        SmartMattressSceneUpdate(
          mode: shouldApplyMode ? _selectedMode.rawValue : null,
          heating: shouldApplyHeating ? _heating.toJson() : null,
          dashboardData: shouldApplyDashboardData
              ? _dashboardData.toWebViewPayload()
              : null,
          sensorFlow: shouldApplyDashboardData
              ? _dashboardData.sensorFlow.toJson()
              : null,
          rippleEffect: shouldApplyRippleEffect
              ? _dashboardData.rippleEffect.toJson()
              : null,
          reset: shouldApplyReset,
        ),
      );
      _lastMode = _selectedMode;
      _lastModeRestartToken = _modeRestartToken;
      _lastHeating = _heating;
      _lastDashboardData = _dashboardData;
      _lastRippleEffect = _dashboardData.rippleEffect;
      _lastResetToken = _resetToken;
    } catch (_) {
      // Keep the pending state. The next successful page finish or user action
      // will apply the latest values again.
    }
  }

  void _selectMode(AdjustmentMode mode) {
    setState(() {
      _selectedMode = mode;
      _modeRestartToken += 1;
    });
    unawaited(_applySmartMattressState());
  }

  void _toggleHeat(MattressHeatControl control) {
    setState(() {
      _heating = _heating.toggle(control);
    });
    unawaited(_applySmartMattressState());
  }

  void _toggleSensorFlow(MattressSensorFlowSide side) {
    _dashboardController.update((MattressDashboardData current) {
      return current.copyWith(sensorFlow: current.sensorFlow.toggleSide(side));
    });
  }

  void _toggleRippleEffect(MattressRippleSide side) {
    _dashboardController.update((MattressDashboardData current) {
      return current.copyWith(
        rippleEffect: current.rippleEffect.toggleSide(side),
      );
    });
  }

  void _setLightCenterPanelView(_LightCenterPanelView view) {
    if (_lightCenterPanelView == view) {
      return;
    }
    setState(() {
      _lightCenterPanelView = view;
    });
  }

  void _reset() {
    setState(() {
      _selectedMode = AdjustmentMode.flat;
      _heating = MattressHeatingState.off;
      _modeRestartToken += 1;
      _resetToken += 1;
    });
    _dashboardController.updateSensorFlow(
      enabled: false,
      leftEnabled: false,
      rightEnabled: false,
    );
    _dashboardController.updateRippleEffect(
      enabled: false,
      leftEnabled: false,
      rightEnabled: false,
    );
    unawaited(_applySmartMattressState());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = constraints.biggest;
          final _ShowroomLayout layout = _ShowroomLayout(
            size,
            profile: widget.profile,
          );

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              RepaintBoundary(
                child: CustomPaint(
                  painter: _ShowroomPainter(
                    mode: _selectedMode,
                    data: _dashboardData,
                    profile: widget.profile,
                    layer: _ShowroomPaintLayer.static,
                  ),
                  size: Size.infinite,
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  painter: _ShowroomPainter(
                    mode: _selectedMode,
                    data: _dashboardData,
                    profile: widget.profile,
                    layer: _ShowroomPaintLayer.dynamic,
                    repaint: _repaint,
                  ),
                  size: Size.infinite,
                ),
              ),
              Positioned.fromRect(
                rect: layout.bedFrame,
                child: ClipRect(
                  child: _sceneController.buildWidget(),
                ),
              ),
              Positioned.fromRect(
                rect: layout.modePanelFrame,
                child: _AdjustmentModePanel(
                  profile: widget.profile,
                  selectedMode: _selectedMode,
                  heating: _heating,
                  sensorFlow: _dashboardData.sensorFlow,
                  rippleEffect: _dashboardData.rippleEffect,
                  lightPanelView: _lightCenterPanelView,
                  scale: layout.scale,
                  onSelect: _selectMode,
                  onToggleHeat: _toggleHeat,
                  onToggleSensorFlow: _toggleSensorFlow,
                  onToggleRippleEffect: _toggleRippleEffect,
                  onLightPanelViewChanged: _setLightCenterPanelView,
                  onReset: _reset,
                ),
              ),
              if (_webViewLoading)
                Positioned.fromRect(
                  rect: layout.bedFrame,
                  child: const Center(
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xff39d7ff),
                      ),
                    ),
                  ),
                ),
              if (_webViewError != null)
                Positioned.fromRect(
                  rect: layout.bedFrame,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _rgb(2, 11, 22, 0.82),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Three.js 页面加载失败\n$_webViewError',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xfff4f8ff),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdjustmentModePanel extends StatelessWidget {
  const _AdjustmentModePanel({
    required this.profile,
    required this.selectedMode,
    required this.heating,
    required this.sensorFlow,
    required this.rippleEffect,
    required this.lightPanelView,
    required this.scale,
    required this.onSelect,
    required this.onToggleHeat,
    required this.onToggleSensorFlow,
    required this.onToggleRippleEffect,
    required this.onLightPanelViewChanged,
    required this.onReset,
  });

  final ShowroomDashboardProfile profile;
  final AdjustmentMode selectedMode;
  final MattressHeatingState heating;
  final MattressSensorFlowState sensorFlow;
  final MattressRippleEffectState rippleEffect;
  final _LightCenterPanelView lightPanelView;
  final double scale;
  final ValueChanged<AdjustmentMode> onSelect;
  final ValueChanged<MattressHeatControl> onToggleHeat;
  final ValueChanged<MattressSensorFlowSide> onToggleSensorFlow;
  final ValueChanged<MattressRippleSide> onToggleRippleEffect;
  final ValueChanged<_LightCenterPanelView> onLightPanelViewChanged;
  final VoidCallback onReset;

  static const List<AdjustmentMode> _primaryModes = <AdjustmentMode>[
    AdjustmentMode.left,
    AdjustmentMode.right,
  ];

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[]),
      builder: (BuildContext context, Widget? child) {
        return Container(
          padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 10 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8 * s),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                _rgb(10, 30, 53, 0.90),
                _rgb(5, 18, 34, 0.88),
              ],
            ),
            border: Border.all(
              color: _rgb(73, 156, 255, 0.30),
              width: math.max(0.5, s),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.26),
                blurRadius: 42 * s,
                offset: Offset(0, 18 * s),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (profile.isLight)
                Expanded(child: _buildLightCenterPanel(s))
              else
                ..._buildSmartMattressControls(s),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLightCenterPanel(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              lightPanelView == _LightCenterPanelView.controls
                  ? '演示控制区'
                  : '产品功能介绍',
              style: TextStyle(
                color: _rgb(244, 248, 255),
                fontSize: math.max(6.0, 16 * s),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.04 * math.max(6.0, 16 * s),
                shadows: <Shadow>[
                  Shadow(
                    color: _rgb(36, 150, 255, 0.34),
                    blurRadius: 5 * s,
                  ),
                ],
              ),
            ),
            const Spacer(),
            _LightPanelViewToggle(
              activeView: lightPanelView,
              scale: s,
              onChanged: onLightPanelViewChanged,
            ),
          ],
        ),
        SizedBox(height: 10 * s),
        Expanded(
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final Animation<Offset> offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<_LightCenterPanelView>(lightPanelView),
                child: lightPanelView == _LightCenterPanelView.controls
                    ? _buildLightSensorControls(s)
                    : _buildLightProductIntroduction(s),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLightSensorControls(double s) {
    return SizedBox.expand(
      child: Column(
        children: <Widget>[
          Container(
            height: 58 * s,
            padding: EdgeInsets.symmetric(horizontal: 13 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8 * s),
              color: _rgb(8, 31, 58, 0.70),
              border: Border.all(
                color: _rgb(73, 156, 255, 0.22),
                width: math.max(0.5, s),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.memory_rounded,
                  color: _rgb(57, 215, 255, 0.88),
                  size: 22 * s,
                ),
                SizedBox(width: 10 * s),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '肩背部传感区域',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _rgb(244, 248, 255, 0.92),
                          fontSize: math.max(5.4, 12.5 * s),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        '心率 ${sensorFlow.intensity.toStringAsFixed(2)}  呼吸 ${sensorFlow.dataRate.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _rgb(198, 224, 255, 0.64),
                          fontSize: math.max(4.8, 10.5 * s),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12 * s),
                _ModePill(
                  label: sensorFlow.activeSideCount == 0
                      ? 'OFF'
                      : '${sensorFlow.activeSideCount} SIDE',
                  scale: s,
                ),
              ],
            ),
          ),
          SizedBox(height: 10 * s),
          Row(
            children: <Widget>[
              _SensorFlowButton(
                side: MattressSensorFlowSide.left,
                active: sensorFlow.isSideEnabled(MattressSensorFlowSide.left),
                scale: s,
                prominent: true,
                onTap: onToggleSensorFlow,
              ),
              SizedBox(width: 9 * s),
              _SensorFlowButton(
                side: MattressSensorFlowSide.right,
                active: sensorFlow.isSideEnabled(MattressSensorFlowSide.right),
                scale: s,
                prominent: true,
                onTap: onToggleSensorFlow,
              ),
            ],
          ),
          SizedBox(height: 10 * s),
          Row(
            children: <Widget>[
              Text(
                '波点涟漪',
                style: TextStyle(
                  color: _rgb(244, 248, 255, 0.84),
                  fontSize: math.max(5.2, 12 * s),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                rippleEffect.summaryLabel,
                style: TextStyle(
                  color: rippleEffect.activeSideCount == 0
                      ? _rgb(198, 224, 255, 0.62)
                      : _rgb(122, 255, 217),
                  fontSize: math.max(5.0, 10.5 * s),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * s),
          Row(
            children: <Widget>[
              _RippleEffectButton(
                side: MattressRippleSide.left,
                active: rippleEffect.isSideEnabled(MattressRippleSide.left),
                scale: s,
                onTap: onToggleRippleEffect,
              ),
              SizedBox(width: 7 * s),
              _RippleEffectButton(
                side: MattressRippleSide.right,
                active: rippleEffect.isSideEnabled(MattressRippleSide.right),
                scale: s,
                onTap: onToggleRippleEffect,
              ),
            ],
          ),
          const Spacer(),
          _ResetButton(scale: s, label: '关闭采集 / 复位', onTap: onReset),
        ],
      ),
    );
  }

  Widget _buildLightProductIntroduction(double s) {
    return SizedBox.expand(
      child: Column(
        children: <Widget>[
          Container(
            height: 68 * s,
            padding: EdgeInsets.symmetric(horizontal: 14 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8 * s),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  _rgb(13, 50, 86, 0.84),
                  _rgb(8, 28, 52, 0.78),
                ],
              ),
              border: Border.all(
                color: _rgb(73, 156, 255, 0.24),
                width: math.max(0.5, s),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40 * s,
                  height: 40 * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10 * s),
                    color: _rgb(57, 215, 255, 0.12),
                    border: Border.all(
                      color: _rgb(93, 227, 255, 0.34),
                      width: math.max(0.5, s),
                    ),
                  ),
                  child: Icon(
                    Icons.sensors_rounded,
                    color: _rgb(93, 227, 255),
                    size: 20 * s,
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '压电生命体征感知',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _rgb(244, 248, 255, 0.96),
                          fontSize: math.max(5.8, 14 * s),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        '嵌入式压电陶瓷可在睡眠过程中持续采集微弱生命体征信号，适合演示从感知到报告的完整链路。',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _rgb(208, 228, 250, 0.72),
                          fontSize: math.max(4.8, 10.8 * s),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12 * s),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    _CapabilityBadge(
                      label: '无感采集',
                      accent: _rgb(93, 227, 255),
                      scale: s,
                    ),
                    SizedBox(height: 6 * s),
                    _CapabilityBadge(
                      label: '整夜追踪',
                      accent: _rgb(122, 255, 217),
                      scale: s,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10 * s),
          Expanded(
            child: Row(
              children: <Widget>[
                _FeatureCard(
                  icon: Icons.favorite_outline_rounded,
                  accent: _rgb(255, 92, 138),
                  title: '心率监测',
                  description: '持续跟踪夜间心率变化，便于观察节律波动与恢复情况。',
                  footer: '连续趋势',
                  scale: s,
                ),
                SizedBox(width: 10 * s),
                _FeatureCard(
                  icon: Icons.air_rounded,
                  accent: _rgb(118, 255, 187),
                  title: '呼吸率监测',
                  description: '捕捉呼吸频率与起伏节奏，为睡眠过程监测提供稳定输入。',
                  footer: '节律识别',
                  scale: s,
                ),
                SizedBox(width: 10 * s),
                _FeatureCard(
                  icon: Icons.description_outlined,
                  accent: _rgb(88, 182, 255),
                  title: '睡眠报告输出',
                  description: '汇总核心体征与夜间趋势，支持生成更直观的睡眠摘要展示。',
                  footer: '报告生成',
                  scale: s,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSmartMattressControls(double s) {
    return <Widget>[
      Row(
        children: <Widget>[
          Text(
            '调节模式',
            style: TextStyle(
              color: _rgb(244, 248, 255),
              fontSize: math.max(6.0, 15 * s),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.04 * math.max(6.0, 15 * s),
              shadows: <Shadow>[
                Shadow(
                  color: _rgb(36, 150, 255, 0.34),
                  blurRadius: 5 * s,
                ),
              ],
            ),
          ),
          const Spacer(),
          _ModePill(label: selectedMode.label, scale: s),
        ],
      ),
      SizedBox(height: 9 * s),
      Row(
        children: _primaryModes
            .map(
              (AdjustmentMode mode) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: mode == _primaryModes.first ? 8 * s : 0,
                  ),
                  child: _ModeButton(
                    title: mode.buttonTitle,
                    active: mode == selectedMode,
                    scale: s,
                    onTap: () => onSelect(mode),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      SizedBox(height: 9 * s),
      Row(
        children: <Widget>[
          Text(
            '压电采集',
            style: TextStyle(
              color: _rgb(244, 248, 255, 0.84),
              fontSize: math.max(5.2, 12 * s),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            sensorFlow.activeSideCount == 0
                ? 'OFF'
                : '${sensorFlow.activeSideCount} SIDE',
            style: TextStyle(
              color: sensorFlow.activeSideCount == 0
                  ? _rgb(198, 224, 255, 0.62)
                  : _rgb(57, 215, 255),
              fontSize: math.max(5.0, 10.5 * s),
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      SizedBox(height: 4 * s),
      Row(
        children: <Widget>[
          _SensorFlowButton(
            side: MattressSensorFlowSide.left,
            active: sensorFlow.isSideEnabled(MattressSensorFlowSide.left),
            scale: s,
            onTap: onToggleSensorFlow,
          ),
          SizedBox(width: 7 * s),
          _SensorFlowButton(
            side: MattressSensorFlowSide.right,
            active: sensorFlow.isSideEnabled(MattressSensorFlowSide.right),
            scale: s,
            onTap: onToggleSensorFlow,
          ),
        ],
      ),
      SizedBox(height: 8 * s),
      Row(
        children: <Widget>[
          Text(
            '波点涟漪',
            style: TextStyle(
              color: _rgb(244, 248, 255, 0.84),
              fontSize: math.max(5.2, 12 * s),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            rippleEffect.summaryLabel,
            style: TextStyle(
              color: rippleEffect.activeSideCount == 0
                  ? _rgb(198, 224, 255, 0.62)
                  : _rgb(122, 255, 217),
              fontSize: math.max(5.0, 10.5 * s),
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      SizedBox(height: 4 * s),
      Row(
        children: <Widget>[
          _RippleEffectButton(
            side: MattressRippleSide.left,
            active: rippleEffect.isSideEnabled(MattressRippleSide.left),
            scale: s,
            onTap: onToggleRippleEffect,
          ),
          SizedBox(width: 7 * s),
          _RippleEffectButton(
            side: MattressRippleSide.right,
            active: rippleEffect.isSideEnabled(MattressRippleSide.right),
            scale: s,
            onTap: onToggleRippleEffect,
          ),
        ],
      ),
      SizedBox(height: 8 * s),
      Row(
        children: <Widget>[
          Text(
            '独立加热',
            style: TextStyle(
              color: _rgb(244, 248, 255, 0.84),
              fontSize: math.max(5.2, 12 * s),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            heating.activeCount == 0 ? 'OFF' : '${heating.activeCount} ZONES',
            style: TextStyle(
              color: heating.activeCount == 0
                  ? _rgb(198, 224, 255, 0.62)
                  : _rgb(255, 176, 78),
              fontSize: math.max(5.0, 10.5 * s),
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      SizedBox(height: 4 * s),
      Row(
        children: <Widget>[
          _HeatButton(
            control: MattressHeatControl.leftWaist,
            active: heating.isEnabled(MattressHeatControl.leftWaist),
            scale: s,
            onTap: onToggleHeat,
          ),
          SizedBox(width: 7 * s),
          _HeatButton(
            control: MattressHeatControl.leftLeg,
            active: heating.isEnabled(MattressHeatControl.leftLeg),
            scale: s,
            onTap: onToggleHeat,
          ),
        ],
      ),
      SizedBox(height: 4 * s),
      Row(
        children: <Widget>[
          _HeatButton(
            control: MattressHeatControl.rightWaist,
            active: heating.isEnabled(MattressHeatControl.rightWaist),
            scale: s,
            onTap: onToggleHeat,
          ),
          SizedBox(width: 7 * s),
          _HeatButton(
            control: MattressHeatControl.rightLeg,
            active: heating.isEnabled(MattressHeatControl.rightLeg),
            scale: s,
            onTap: onToggleHeat,
          ),
        ],
      ),
      SizedBox(height: 6 * s),
      _ResetButton(scale: s, onTap: onReset),
    ];
  }
}

class _LightPanelViewToggle extends StatelessWidget {
  const _LightPanelViewToggle({
    required this.activeView,
    required this.scale,
    required this.onChanged,
  });

  final _LightCenterPanelView activeView;
  final double scale;
  final ValueChanged<_LightCenterPanelView> onChanged;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return Container(
      width: 166 * s,
      height: 30 * s,
      padding: EdgeInsets.all(2 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999 * s),
        color: _rgb(8, 28, 52, 0.86),
        border: Border.all(
          color: _rgb(73, 156, 255, 0.24),
          width: math.max(0.5, s),
        ),
      ),
      child: Row(
        children: _LightCenterPanelView.values
            .map(
              (_LightCenterPanelView view) => Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999 * s),
                    onTap: () => onChanged(view),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999 * s),
                        gradient: activeView == view
                            ? LinearGradient(
                                colors: <Color>[
                                  _rgb(43, 162, 255, 0.84),
                                  _rgb(15, 103, 198, 0.74),
                                ],
                              )
                            : null,
                        color: activeView == view ? null : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          view.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: activeView == view
                                ? Colors.white
                                : _rgb(208, 228, 250, 0.72),
                            fontSize: math.max(4.8, 10.8 * s),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CapabilityBadge extends StatelessWidget {
  const _CapabilityBadge({
    required this.label,
    required this.accent,
    required this.scale,
  });

  final String label;
  final Color accent;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return Container(
      height: 22 * s,
      padding: EdgeInsets.symmetric(horizontal: 8 * s),
      decoration: ShapeDecoration(
        color: accent.withOpacity(0.10),
        shape: StadiumBorder(
          side: BorderSide(
            color: accent.withOpacity(0.28),
            width: math.max(0.5, s),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5 * s,
            height: 5 * s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
            ),
          ),
          SizedBox(width: 5 * s),
          Text(
            label,
            style: TextStyle(
              color: _rgb(231, 243, 255, 0.88),
              fontSize: math.max(4.5, 9.8 * s),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.footer,
    required this.scale,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final String footer;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return Expanded(
      child: Container(
        padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 12 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8 * s),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              accent.withOpacity(0.14),
              _rgb(7, 23, 44, 0.88),
            ],
          ),
          border: Border.all(
            color: accent.withOpacity(0.26),
            width: math.max(0.5, s),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 30 * s,
                  height: 30 * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8 * s),
                    color: accent.withOpacity(0.12),
                    border: Border.all(
                      color: accent.withOpacity(0.24),
                      width: math.max(0.5, s),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 16 * s,
                  ),
                ),
                const Spacer(),
                _CapabilityBadge(
                  label: footer,
                  accent: accent,
                  scale: s,
                ),
              ],
            ),
            SizedBox(height: 12 * s),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _rgb(244, 248, 255),
                fontSize: math.max(5.5, 13 * s),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8 * s),
            Expanded(
              child: Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _rgb(208, 228, 250, 0.70),
                  fontSize: math.max(4.8, 10.6 * s),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return Container(
      height: 26 * s,
      padding: EdgeInsets.symmetric(horizontal: 10 * s),
      decoration: ShapeDecoration(
        color: _rgb(26, 111, 210, 0.16),
        shape: StadiumBorder(
          side: BorderSide(
            color: _rgb(86, 184, 255, 0.30),
            width: math.max(0.5, s),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7 * s,
            height: 7 * s,
            decoration: BoxDecoration(
              color: _rgb(71, 216, 147),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _rgb(71, 216, 147, 0.9),
                  blurRadius: 9 * s,
                ),
              ],
            ),
          ),
          SizedBox(width: 7 * s),
          Text(
            label,
            style: TextStyle(
              color: _rgb(198, 224, 255),
              fontSize: math.max(5.5, 12 * s),
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.active,
    required this.scale,
    required this.onTap,
  });

  final String title;
  final bool active;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return SizedBox(
      height: 35 * s,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6 * s),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6 * s),
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        _rgb(42, 154, 255, 0.72),
                        _rgb(18, 85, 178, 0.58),
                      ],
                    )
                  : null,
              color: active ? null : _rgb(12, 43, 78, 0.62),
              border: Border.all(
                color: active
                    ? _rgb(147, 224, 255, 0.86)
                    : _rgb(73, 156, 255, 0.24),
                width: math.max(0.5, s),
              ),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: _rgb(31, 132, 255, 0.42),
                        blurRadius: 20 * s,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : _rgb(235, 247, 255, 0.78),
                  fontSize: math.max(5.4, 13 * s),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SensorFlowButton extends StatelessWidget {
  const _SensorFlowButton({
    required this.side,
    required this.active,
    required this.scale,
    required this.onTap,
    this.prominent = false,
  });

  final MattressSensorFlowSide side;
  final bool active;
  final double scale;
  final ValueChanged<MattressSensorFlowSide> onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return Expanded(
      child: SizedBox(
        height: (prominent ? 42 : 25) * s,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6 * s),
            onTap: () => onTap(side),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6 * s),
                gradient: active
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          _rgb(36, 196, 255, 0.72),
                          _rgb(13, 93, 190, 0.62),
                        ],
                      )
                    : null,
                color: active ? null : _rgb(10, 43, 76, 0.58),
                border: Border.all(
                  color: active
                      ? _rgb(139, 232, 255, 0.84)
                      : _rgb(73, 156, 255, 0.24),
                  width: math.max(0.5, s),
                ),
                boxShadow: active
                    ? <BoxShadow>[
                        BoxShadow(
                          color: _rgb(32, 185, 255, 0.34),
                          blurRadius: 14 * s,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.sensors_outlined,
                    color: active ? Colors.white : _rgb(220, 242, 255, 0.72),
                    size: (prominent ? 16 : 13) * s,
                  ),
                  SizedBox(width: (prominent ? 7 : 5) * s),
                  Flexible(
                    child: Text(
                      side.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            active ? Colors.white : _rgb(235, 247, 255, 0.76),
                        fontSize: math.max(5.0, (prominent ? 12.5 : 11.5) * s),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RippleEffectButton extends StatelessWidget {
  const _RippleEffectButton({
    required this.side,
    required this.active,
    required this.scale,
    required this.onTap,
  });

  final MattressRippleSide side;
  final bool active;
  final double scale;
  final ValueChanged<MattressRippleSide> onTap;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return Expanded(
      child: SizedBox(
        height: 25 * s,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6 * s),
            onTap: () => onTap(side),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6 * s),
                gradient: active
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          _rgb(52, 220, 194, 0.72),
                          _rgb(18, 102, 178, 0.62),
                        ],
                      )
                    : null,
                color: active ? null : _rgb(10, 54, 58, 0.58),
                border: Border.all(
                  color: active
                      ? _rgb(150, 255, 226, 0.86)
                      : _rgb(122, 255, 217, 0.24),
                  width: math.max(0.5, s),
                ),
                boxShadow: active
                    ? <BoxShadow>[
                        BoxShadow(
                          color: _rgb(122, 255, 217, 0.30),
                          blurRadius: 14 * s,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.blur_circular_rounded,
                    color: active ? Colors.white : _rgb(220, 255, 246, 0.72),
                    size: 13 * s,
                  ),
                  SizedBox(width: 5 * s),
                  Flexible(
                    child: Text(
                      side.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            active ? Colors.white : _rgb(235, 255, 248, 0.76),
                        fontSize: math.max(5.0, 11.5 * s),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatButton extends StatelessWidget {
  const _HeatButton({
    required this.control,
    required this.active,
    required this.scale,
    required this.onTap,
  });

  final MattressHeatControl control;
  final bool active;
  final double scale;
  final ValueChanged<MattressHeatControl> onTap;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return Expanded(
      child: SizedBox(
        height: 25 * s,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6 * s),
            onTap: () => onTap(control),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6 * s),
                gradient: active
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          _rgb(255, 139, 40, 0.72),
                          _rgb(151, 63, 16, 0.62),
                        ],
                      )
                    : null,
                color: active ? null : _rgb(55, 32, 19, 0.58),
                border: Border.all(
                  color: active
                      ? _rgb(255, 183, 88, 0.82)
                      : _rgb(255, 148, 64, 0.24),
                  width: math.max(0.5, s),
                ),
                boxShadow: active
                    ? <BoxShadow>[
                        BoxShadow(
                          color: _rgb(255, 124, 34, 0.35),
                          blurRadius: 14 * s,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  control.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : _rgb(246, 239, 226, 0.74),
                    fontSize: math.max(5.0, 11.5 * s),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({
    required this.scale,
    required this.onTap,
    this.label = '恢复初始状态',
  });

  final double scale;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return SizedBox(
      height: 27 * s,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6 * s),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: _rgb(9, 35, 66, 0.74),
              borderRadius: BorderRadius.circular(6 * s),
              border: Border.all(
                color: _rgb(73, 156, 255, 0.28),
                width: math.max(0.5, s),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: _rgb(235, 247, 255, 0.88),
                  fontSize: math.max(5.4, 12.5 * s),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowroomLayout {
  _ShowroomLayout(
    Size size, {
    required this.profile,
  })  : scale =
            math.min(size.width / _designWidth, size.height / _designHeight),
        offsetX = (size.width -
                _designWidth *
                    math.min(
                      size.width / _designWidth,
                      size.height / _designHeight,
                    )) *
            0.5,
        offsetY = (size.height -
                _designHeight *
                    math.min(
                      size.width / _designWidth,
                      size.height / _designHeight,
                    )) *
            0.5 {
    bedFrame = _scaleRect(_bedDesignFrame);
    modePanelFrame = _scaleRect(
      profile.isLight ? _lightModePanelDesignFrame : _modePanelDesignFrame,
    );
  }

  final ShowroomDashboardProfile profile;
  final double scale;
  final double offsetX;
  final double offsetY;
  late final Rect bedFrame;
  late final Rect modePanelFrame;

  static const Rect _bedDesignFrame = Rect.fromLTWH(601, 138, 718, 700);
  static const Rect _modePanelDesignFrame = Rect.fromLTWH(620, 764, 380, 270);
  static const Rect _lightModePanelDesignFrame =
      Rect.fromLTWH(620, 764, 699, 270);

  Rect _scaleRect(Rect rect) {
    return Rect.fromLTWH(
      offsetX + rect.left * scale,
      offsetY + rect.top * scale,
      rect.width * scale,
      rect.height * scale,
    );
  }
}

class _ShowroomPainter extends CustomPainter {
  _ShowroomPainter({
    required this.mode,
    required this.data,
    required this.profile,
    required this.layer,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final AdjustmentMode mode;
  final MattressDashboardData data;
  final ShowroomDashboardProfile profile;
  final _ShowroomPaintLayer layer;
  late Canvas _canvas;
  late DateTime _now;

  static const double designWidth = _designWidth;
  static const double designHeight = _designHeight;

  final Color blue = _rgb(36, 150, 255);
  final Color cyan = _rgb(57, 215, 255);
  final Color green = _rgb(71, 216, 147);
  final Color pink = _rgb(255, 77, 121);
  final Color text = _rgb(244, 248, 255);
  final Color muted = _rgb(220, 232, 250, 0.68);
  final Color dim = _rgb(220, 232, 250, 0.42);

  @override
  void paint(Canvas canvas, Size size) {
    _canvas = canvas;
    _now = DateTime.now();

    if (layer == _ShowroomPaintLayer.static) {
      final double coverScale =
          math.max(size.width / designWidth, size.height / designHeight);
      final Offset coverOffset = Offset(
        (size.width - designWidth * coverScale) * 0.5,
        (size.height - designHeight * coverScale) * 0.5,
      );
      canvas.save();
      canvas.translate(coverOffset.dx, coverOffset.dy);
      canvas.scale(coverScale);
      _drawBackground();
      canvas.restore();
    }

    final double scale =
        math.min(size.width / designWidth, size.height / designHeight);
    final Offset offset = Offset(
      (size.width - designWidth * scale) * 0.5,
      (size.height - designHeight * scale) * 0.5,
    );
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    switch (layer) {
      case _ShowroomPaintLayer.static:
        _drawBase();
      case _ShowroomPaintLayer.dynamic:
        _drawDynamicOverlay();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShowroomPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.data != data ||
        oldDelegate.profile != profile ||
        oldDelegate.layer != layer;
  }

  void _drawBase() {
    _canvas.drawRect(
      const Rect.fromLTWH(0, 0, designWidth, designHeight),
      Paint()..color = Colors.black,
    );
    _drawBackground();
    _drawHeader();
    _drawSide(44, 138, true);
    _drawSide(1351, 138, false);
    _drawCenter(601, 138);
    _drawBottomPulseLine(includeTrack: true, includeSweep: false);
  }

  void _drawDynamicOverlay() {
    _drawHeaderTime();
    if (profile.isLight) {
      _drawVitalFocusDynamics(44, 138);
      _drawVitalFocusDynamics(1351, 138);
    } else {
      _drawMetricDynamics(44, 138);
      _drawMetricDynamics(1351, 138);
      _drawChartDynamic(44 + 22, 138 + 624 + 104, 481, 170, data.pressureChart);
      _drawChartDynamic(
          1351 + 22, 138 + 624 + 104, 481, 170, data.pressureChart);
    }
    _drawBottomPulseLine(includeTrack: false, includeSweep: true);
    if (!profile.isLight) {
      _drawFooter();
    }
  }

  void _drawBackground() {
    const Rect full = Rect.fromLTWH(0, 0, designWidth, designHeight);
    _canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xff010812),
            Color(0xff020d1c),
            Color(0xff010712),
          ],
        ).createShader(full),
    );

    _fillRadial(const Offset(960, 605), 650, blue.withOpacity(0.22));
    _fillRadial(const Offset(269, 216), 500, blue.withOpacity(0.14));
    _fillRadial(const Offset(1651, 194), 500, cyan.withOpacity(0.11));
    _fillRadial(const Offset(960, 86), 720, _rgb(78, 184, 255, 0.075));

    final Path grid = Path();
    for (double x = 0; x <= designWidth; x += 48) {
      grid
        ..moveTo(x, 0)
        ..lineTo(x, designHeight);
    }
    for (double y = 0; y <= designHeight; y += 48) {
      grid
        ..moveTo(0, y)
        ..lineTo(designWidth, y);
    }
    _canvas.drawPath(
      grid,
      Paint()
        ..color = _rgb(52, 153, 255, 0.042)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Colors.black.withOpacity(0.46),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.46),
          ],
          stops: const <double>[0, 0.18, 0.82, 1],
        ).createShader(full),
    );
    _canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.transparent,
            Colors.black.withOpacity(0.46),
          ],
          stops: const <double>[0.56, 1],
        ).createShader(
            Rect.fromCircle(center: const Offset(960, 540), radius: 1080)),
    );
  }

  void _drawHeader() {
    _drawHeaderLine(369, 62, 350);
    _drawHeaderLine(1201, 62, 350);
    _drawText(
      profile.headerTitle,
      x: 960,
      y: 68,
      size: 43,
      color: text,
      align: _CanvasTextAlign.center,
      weight: FontWeight.w900,
      tracking: 4.1,
      glow: blue.withOpacity(0.42),
    );
    _drawText(
      profile.statusFor(mode),
      x: 960,
      y: 112,
      size: 17,
      color: muted,
      align: _CanvasTextAlign.center,
      weight: FontWeight.w400,
      tracking: 2.8,
    );
    _drawWifi(1826, 56);
    _drawCornerLine();
  }

  void _drawHeaderTime() {
    _drawText(
      _timeString(),
      x: 1765,
      y: 68,
      size: 19,
      color: muted,
      align: _CanvasTextAlign.right,
      weight: FontWeight.w400,
      tracking: 0.4,
    );
  }

  void _drawHeaderLine(double x, double y, double width) {
    final Rect rect = Rect.fromLTWH(x, y, width, 2);
    _drawRectGlow(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Colors.transparent,
            blue.withOpacity(0.9),
            Colors.transparent,
          ],
        ).createShader(rect),
      blue.withOpacity(0.8),
      6,
    );
  }

  void _drawCornerLine() {
    final Path path = Path()
      ..moveTo(522, 200)
      ..lineTo(1398, 200)
      ..moveTo(402, 200)
      ..lineTo(522, 154)
      ..moveTo(1518, 200)
      ..lineTo(1398, 154);
    _canvas.drawPath(
      path,
      Paint()
        ..color = _rgb(57, 151, 255, 0.48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawSide(double x, double y, bool isLeft) {
    final String side = isLeft ? '左侧' : '右侧';
    final String pill = isLeft ? '调节阈值-Pa' : '温感舱-Pa';
    if (profile.isLight) {
      _drawVitalFocusPanel(x, y, side);
      return;
    }
    _drawRealtimePanel(x, y, side);
    _drawTrendPanel(x, y + 262);
    _drawPressurePanel(x, y + 624, pill);
  }

  void _drawRealtimePanel(double x, double y, String side) {
    _drawPanel(Rect.fromLTWH(x, y, 525, 244), 18);
    _drawPanelHeader(x, y, '$side实时数据', '$side睡眠报告');
    _drawMetricCard(
      x + 22,
      y + 54,
      240,
      168,
      '实时心率',
      data.realtime.heartRate.toString(),
      '次/分',
      pink,
      true,
    );
    _drawMetricCard(
      x + 274,
      y + 54,
      229,
      168,
      '实时呼吸率',
      data.realtime.breathRate.toString(),
      '次/分',
      blue,
      false,
    );
  }

  void _drawPanelHeader(double x, double y, String title, String report) {
    _drawText(
      title,
      x: x + 22,
      y: y + 35,
      size: 20,
      color: _rgb(115, 195, 255),
      align: _CanvasTextAlign.left,
      weight: FontWeight.w700,
      tracking: 0.8,
      glow: blue.withOpacity(0.28),
    );
    _drawReportButton(x + 271, y + 13, report);
    _drawOvalGlow(
      Rect.fromLTWH(x + 414, y + 24.5, 9, 9),
      green,
      green.withOpacity(0.9),
      10,
    );
    _drawText(
      '检测到人体',
      x: x + 432,
      y: y + 34,
      size: 14,
      color: muted,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w400,
    );
  }

  void _drawReportButton(double x, double y, String label) {
    final Rect rect = Rect.fromLTWH(x, y, 128, 30);
    final RRect rrect = _rrect(rect, 15);
    _canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            blue.withOpacity(0.25),
            _rgb(8, 28, 50, 0.78),
            cyan.withOpacity(0.13),
          ],
        ).createShader(rect),
    );
    _strokeRRect(rrect, _rgb(104, 187, 255, 0.34), 1);

    final Rect iconRect = Rect.fromLTWH(x + 12, y + 8, 13, 13);
    _drawRRectGlow(
      _rrect(iconRect, 3),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _rgb(91, 203, 255),
            _rgb(36, 120, 255, 0.62),
          ],
        ).createShader(iconRect),
      cyan.withOpacity(0.6),
      8,
    );
    _canvas.drawRect(Rect.fromLTWH(x + 15, y + 12, 7, 1),
        Paint()..color = Colors.white.withOpacity(0.72));
    _canvas.drawRect(Rect.fromLTWH(x + 15, y + 16, 5, 1),
        Paint()..color = Colors.white.withOpacity(0.46));
    _drawText(
      label,
      x: x + 34,
      y: y + 21,
      size: 12,
      color: text.withOpacity(0.9),
      align: _CanvasTextAlign.left,
      weight: FontWeight.w600,
      tracking: 0.6,
    );
  }

  void _drawMetricCard(
    double x,
    double y,
    double width,
    double height,
    String title,
    String value,
    String unit,
    Color accent,
    bool isHeart,
  ) {
    final double phase = _phase(isHeart ? 1.4 : 2.8);
    final double pulseValue = isHeart
        ? _pulse(phase, 0.12, 0.22) + _pulse(phase, 0.30, 0.12)
        : 0.5 + 0.5 * math.sin(phase * math.pi * 2);
    final Rect rect = Rect.fromLTWH(x, y, width, height);
    final RRect rrect = _rrect(rect, 14);
    _canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _rgb(15, 44, 75, 0.90),
            _rgb(6, 22, 40, 0.95),
          ],
        ).createShader(rect),
    );
    _withClipRRect(rrect, () {
      _fillRadial(
        Offset(x + width * 0.18, y + height * 0.32),
        104,
        accent.withOpacity(0.14),
      );
    });
    _strokeRRect(rrect, _rgb(100, 174, 244, 0.08), 1);
    _fillRadial(
      Offset(x + 46, y + 74),
      58,
      accent.withOpacity(0.18 + pulseValue * 0.05),
    );

    if (isHeart) {
      _drawHeartIcon(Offset(x + 44, y + 59), accent, 1 + pulseValue * 0.06);
    } else {
      _drawLungIcon(Offset(x + 44, y + 59), accent, 0.98 + pulseValue * 0.05);
    }

    _drawText(
      title,
      x: x + 72,
      y: y + 39,
      size: 16,
      color: text.withOpacity(0.88),
      align: _CanvasTextAlign.left,
      weight: FontWeight.w600,
    );
    _drawText(
      value,
      x: x + 72,
      y: y + 91,
      size: 44,
      color: text,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w700,
      tracking: -1.6,
    );
    _drawText(
      unit,
      x: x + 130,
      y: y + 90,
      size: 15,
      color: muted,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w400,
    );
    _drawVitalMiniWave(
      Rect.fromLTWH(x + 20, y + 119, width - 40, 34),
      isHeart,
      accent,
      null,
    );
  }

  void _drawMetricDynamics(double x, double y) {
    _drawMetricCardDynamic(
      x + 22,
      y + 54,
      240,
      168,
      pink,
      true,
    );
    _drawMetricCardDynamic(
      x + 274,
      y + 54,
      229,
      168,
      blue,
      false,
    );
  }

  void _drawMetricCardDynamic(
    double x,
    double y,
    double width,
    double height,
    Color accent,
    bool isHeart,
  ) {
    final double phase = _phase(isHeart ? 1.4 : 2.8);
    _drawVitalMiniWave(
      Rect.fromLTWH(x + 20, y + 119, width - 40, 34),
      isHeart,
      accent,
      phase,
      includeBase: false,
    );
  }

  void _drawVitalFocusPanel(double x, double y, String side) {
    const double cardTop = 108;
    const double cardGap = 34;
    const double cardHeight = 368;
    _drawPanel(Rect.fromLTWH(x, y, 525, 920), 18);
    _drawText(
      '$side生命体征强化监测',
      x: x + 22,
      y: y + 38,
      size: 21,
      color: text,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w700,
      tracking: 0.7,
    );
    _drawText(
      '生命体征核心态势',
      x: x + 22,
      y: y + 68,
      size: 14,
      color: muted,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w400,
      tracking: 0.4,
    );
    final Rect liveRect = Rect.fromLTWH(x + 406, y + 22, 97, 34);
    _canvas.drawRRect(
      _rrect(liveRect, 10),
      Paint()..color = cyan.withOpacity(0.12),
    );
    _strokeRRect(_rrect(liveRect, 10), cyan.withOpacity(0.24), 1);
    _drawOvalGlow(
      Rect.fromCircle(
          center: Offset(liveRect.left + 18, liveRect.center.dy), radius: 4),
      green,
      green.withOpacity(0.78),
      8,
    );
    _drawText(
      'LIVE',
      x: liveRect.left + 32,
      y: y + 44,
      size: 12,
      color: text.withOpacity(0.86),
      align: _CanvasTextAlign.left,
      weight: FontWeight.w700,
      tracking: 1,
    );
    _drawVitalHeroCard(
      x + 22,
      y + cardTop,
      481,
      cardHeight,
      '心率',
      data.realtime.heartRate.toString(),
      '次/分',
      '低波动实时追踪',
      pink,
      true,
    );
    _drawVitalHeroCard(
      x + 22,
      y + cardTop + cardHeight + cardGap,
      481,
      cardHeight,
      '呼吸率',
      data.realtime.breathRate.toString(),
      '次/分',
      '平稳节律实时追踪',
      green,
      false,
    );
  }

  void _drawVitalHeroCard(
    double x,
    double y,
    double width,
    double height,
    String title,
    String value,
    String unit,
    String subtitle,
    Color accent,
    bool isHeart,
  ) {
    final double phase = _phase(isHeart ? 1.4 : 2.8);
    final double pulseValue = isHeart
        ? _pulse(phase, 0.12, 0.22) + _pulse(phase, 0.30, 0.12)
        : 0.5 + 0.5 * math.sin(phase * math.pi * 2);
    final Rect rect = Rect.fromLTWH(x, y, width, height);
    final RRect rrect = _rrect(rect, 14);
    _canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withOpacity(0.18),
            _rgb(8, 28, 50, 0.92),
            _rgb(3, 16, 30, 0.94),
          ],
        ).createShader(rect),
    );
    _withClipRRect(rrect, () {
      _fillRadial(
        Offset(x + width * 0.18, y + height * 0.42),
        150,
        accent.withOpacity(0.18 + pulseValue * 0.04),
      );
      _fillRadial(
        Offset(x + width * 0.82, y + height * 0.78),
        180,
        cyan.withOpacity(0.08),
      );
    });
    _strokeRRect(rrect, accent.withOpacity(0.18), 1);

    final Offset iconCenter = Offset(x + 76, y + 84);
    _fillRadial(iconCenter, 88, accent.withOpacity(0.18 + pulseValue * 0.06));
    if (isHeart) {
      _drawHeartIcon(iconCenter, accent, 1.34 + pulseValue * 0.12);
    } else {
      _drawLungIcon(iconCenter, accent, 1.28 + pulseValue * 0.10);
    }

    _drawText(
      title,
      x: x + 148,
      y: y + 58,
      size: 20,
      color: text.withOpacity(0.9),
      align: _CanvasTextAlign.left,
      weight: FontWeight.w700,
      tracking: 0.6,
    );
    _drawText(
      subtitle,
      x: x + 148,
      y: y + 91,
      size: 14,
      color: muted,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w500,
    );
    _drawText(
      value,
      x: x + 148,
      y: y + 178,
      size: 78,
      color: text,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w900,
      glow: accent.withOpacity(0.20),
    );
    _drawText(
      unit,
      x: x + 272,
      y: y + 162,
      size: 17,
      color: muted,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w500,
    );
    _drawVitalMiniWave(
      Rect.fromLTWH(x + 28, y + height - 100, width - 56, 64),
      isHeart,
      accent,
      null,
    );
  }

  void _drawVitalFocusDynamics(double x, double y) {
    const double cardTop = 108;
    const double cardGap = 34;
    const double cardHeight = 368;
    _drawVitalHeroCardDynamic(x + 22, y + cardTop, 481, cardHeight, pink, true);
    _drawVitalHeroCardDynamic(
      x + 22,
      y + cardTop + cardHeight + cardGap,
      481,
      cardHeight,
      green,
      false,
    );
  }

  void _drawVitalHeroCardDynamic(
    double x,
    double y,
    double width,
    double height,
    Color accent,
    bool isHeart,
  ) {
    final double phase = _phase(isHeart ? 1.4 : 2.8);
    final Rect rect = Rect.fromLTWH(x, y, width, height);
    final RRect rrect = _rrect(rect, 14);
    _withClipRRect(rrect, () {
      const double sweepWidth = 92;
      final double sweepX = x - sweepWidth + (width + sweepWidth * 2) * phase;
      final Rect sweep = Rect.fromLTWH(sweepX, y, sweepWidth, height);
      _canvas.drawRect(
        sweep,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              Colors.transparent,
              accent.withOpacity(0.025),
              Colors.transparent,
            ],
          ).createShader(sweep),
      );
    });
    _drawVitalMiniWave(
      Rect.fromLTWH(x + 28, y + height - 100, width - 56, 64),
      isHeart,
      accent,
      phase,
      includeBase: false,
      intensity: 0.62,
      drawDotGlow: false,
    );
  }

  void _drawTrendPanel(double x, double y) {
    _drawPanel(Rect.fromLTWH(x, y, 525, 344), 18);
    _drawText(
      '指数变化趋势',
      x: x + 22,
      y: y + 36,
      size: 21,
      color: text,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w700,
      tracking: 0.7,
    );
    _drawGaugeCard(
      x + 22,
      y + 70,
      240,
      218,
      '腰部支撑指数',
      data.trend.lumbarSupportIndex,
      data.trend.lumbarSupportStatus,
      green,
    );
    _drawGaugeCard(
      x + 276,
      y + 70,
      227,
      218,
      '人体工程学指数',
      data.trend.ergonomicIndex,
      data.trend.ergonomicStatus,
      blue,
    );
    _drawLegend(x + 175, y + 326, green, '当前指数');
    _drawLegend(x + 306, y + 326, _rgb(83, 145, 210, 0.46), '推荐指数');
  }

  void _drawGaugeCard(
    double x,
    double y,
    double width,
    double height,
    String title,
    double value,
    String status,
    Color accent,
  ) {
    final Rect rect = Rect.fromLTWH(x, y, width, height);
    final RRect rrect = _rrect(rect, 14);
    _canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _rgb(8, 28, 50, 0.74),
            _rgb(4, 17, 32, 0.82),
          ],
        ).createShader(rect),
    );
    _withClipRRect(rrect, () {
      _fillRadial(
          Offset(x + width / 2, y + 150), 115, accent.withOpacity(0.07));
    });
    _strokeRRect(rrect, _rgb(100, 174, 244, 0.055), 1);
    _drawText(
      title,
      x: x + width / 2,
      y: y + 38,
      size: 17,
      color: text.withOpacity(0.9),
      align: _CanvasTextAlign.center,
      weight: FontWeight.w600,
    );

    final Offset center = Offset(x + width / 2, y + 124);
    _drawGaugeRing(center, 58, value, accent);
    _drawText(
      value.toInt().toString(),
      x: center.dx,
      y: center.dy + 10,
      size: 35,
      color: text,
      align: _CanvasTextAlign.center,
      weight: FontWeight.w900,
      tracking: -1.2,
      glow: accent.withOpacity(0.22),
    );
    _drawText(
      status,
      x: center.dx,
      y: center.dy + 35,
      size: 15,
      color: accent,
      align: _CanvasTextAlign.center,
      weight: FontWeight.w700,
      glow: accent.withOpacity(0.36),
    );
    _drawText('0',
        x: center.dx - 64,
        y: y + 195,
        size: 10,
        color: dim,
        align: _CanvasTextAlign.center,
        weight: FontWeight.w400);
    _drawText('100',
        x: center.dx + 64,
        y: y + 195,
        size: 10,
        color: dim,
        align: _CanvasTextAlign.center,
        weight: FontWeight.w400);
  }

  void _drawGaugeRing(
      Offset center, double radius, double value, Color accent) {
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint track = Paint()
      ..color = _rgb(46, 104, 169, 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    _canvas.drawArc(rect, _deg(118), _deg(304), false, track);

    final Paint glow = Paint()
      ..color = accent.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    final Paint ring = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    _canvas.drawArc(rect, _deg(118), _deg(304 * value / 100), false, glow);
    _canvas.drawArc(rect, _deg(118), _deg(304 * value / 100), false, ring);

    final Rect inner = Rect.fromCircle(center: center, radius: 44);
    _canvas.drawOval(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _rgb(7, 27, 49, 0.98),
            _rgb(3, 15, 29, 0.98),
          ],
        ).createShader(inner),
    );
  }

  void _drawPressurePanel(double x, double y, String pill) {
    _drawPanel(Rect.fromLTWH(x, y, 525, 296), 18);
    _drawText(
      '各部位实时气压',
      x: x + 22,
      y: y + 36,
      size: 21,
      color: text,
      align: _CanvasTextAlign.left,
      weight: FontWeight.w700,
      tracking: 0.7,
    );
    final Rect pillRect = Rect.fromLTWH(x + 400, y + 13, 103, 34);
    _canvas.drawRRect(
        _rrect(pillRect, 10), Paint()..color = blue.withOpacity(0.16));
    _strokeRRect(_rrect(pillRect, 10), blue.withOpacity(0.24), 1);
    _drawText(pill,
        x: pillRect.center.dx,
        y: y + 35,
        size: 13,
        color: muted,
        align: _CanvasTextAlign.center,
        weight: FontWeight.w600);
    _drawText('单位：Pa',
        x: x + 22,
        y: y + 83,
        size: 13,
        color: muted,
        align: _CanvasTextAlign.left,
        weight: FontWeight.w400);
    _drawLegend(x + 342, y + 84, blue, '当前气压');
    _drawLegend(x + 430, y + 84, blue.withOpacity(0.5), '推荐气压');
    _drawChart(x + 22, y + 104, 481, 170, data.pressureChart);
  }

  void _drawChart(
    double x,
    double y,
    double width,
    double height,
    MattressPressureChartData chart,
  ) {
    final Rect rect = Rect.fromLTWH(x, y, width, height);
    _canvas.drawRRect(
      _rrect(rect, 12),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _rgb(21, 59, 94, 0.18),
            _rgb(3, 16, 30, 0.02),
          ],
        ).createShader(rect),
    );

    final Path grid = Path();
    for (int index = 0; index < 3; index += 1) {
      final double yy = y + 28 + index * 66;
      grid
        ..moveTo(x + 50, yy)
        ..lineTo(x + width - 14, yy);
    }
    _canvas.drawPath(
      grid,
      Paint()
        ..color = _rgb(126, 169, 220, 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final Path line = _pressurePath(
      x + 50,
      y + 28,
      width - 64,
      132,
      chart.currentValues,
      chart,
      0,
    );
    final Path recommend = _pressurePath(
      x + 50,
      y + 28,
      width - 64,
      132,
      chart.recommendedValues,
      chart,
      18,
    );
    final Path fill = Path.from(line)
      ..lineTo(x + width - 14, y + 160)
      ..lineTo(x + 50, y + 160)
      ..close();
    _canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            cyan.withOpacity(0.34),
            blue.withOpacity(0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(x, y + 20, width, 140)),
    );
    _canvas.drawPath(
      recommend,
      Paint()
        ..color = blue.withOpacity(0.52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round,
    );
    _canvas.drawPath(
      line,
      Paint()
        ..color = blue.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final int markerIndex =
        chart.markerIndex.clamp(0, math.max(0, chart.currentValues.length - 1));
    final double markerProgress = chart.currentValues.length <= 1
        ? 0
        : markerIndex / (chart.currentValues.length - 1);
    final double markerX = x + 50 + (width - 64) * markerProgress;
    _canvas.drawLine(
      Offset(markerX, y + 90),
      Offset(markerX, y + 160),
      Paint()
        ..color = blue.withOpacity(0.48)
        ..strokeWidth = 1.4,
    );
    final Rect tag = Rect.fromLTWH(x + 236, y + 52, 74, 38);
    _drawRRectGlow(
      _rrect(tag, 7),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _rgb(46, 138, 245),
            _rgb(18, 97, 189),
          ],
        ).createShader(tag),
      blue.withOpacity(0.45),
      14,
    );
    _drawText('${chart.visibleMarkerValue.round()} Pa',
        x: tag.center.dx,
        y: y + 77,
        size: 15,
        color: Colors.white,
        align: _CanvasTextAlign.center,
        weight: FontWeight.w700);
    _drawText(chart.maxValue.round().toString(),
        x: x,
        y: y + 30,
        size: 12,
        color: dim,
        align: _CanvasTextAlign.left,
        weight: FontWeight.w400);
    _drawText(((chart.maxValue + chart.minValue) / 2).round().toString(),
        x: x,
        y: y + 96,
        size: 12,
        color: dim,
        align: _CanvasTextAlign.left,
        weight: FontWeight.w400);
    _drawText(chart.minValue.round().toString(),
        x: x,
        y: y + 162,
        size: 12,
        color: dim,
        align: _CanvasTextAlign.left,
        weight: FontWeight.w400);
    for (int i = 0; i < chart.labels.length; i += 1) {
      final double progress =
          chart.labels.length <= 1 ? 0 : i / (chart.labels.length - 1);
      _drawText(chart.labels[i],
          x: x + 50 + (width - 64) * progress,
          y: y + 190,
          size: 14,
          color: muted,
          align: _CanvasTextAlign.center,
          weight: FontWeight.w400);
    }
  }

  void _drawChartDynamic(
    double x,
    double y,
    double width,
    double height,
    MattressPressureChartData chart,
  ) {
    final double phase = _phase(3.6);
    final Path line = _pressurePath(
      x + 50,
      y + 28,
      width - 64,
      132,
      chart.currentValues,
      chart,
      0,
    );
    final Path trimmed = _trimPath(line, 0, math.max(0.02, phase));
    _canvas.drawPath(
      trimmed,
      Paint()
        ..color = blue.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    _canvas.drawPath(
      trimmed,
      Paint()
        ..color = blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawCenter(double x, double y) {
    _drawBedArea(x, y);
    if (!profile.isLight) {
      _drawCompactShowroomCard(1018, 812);
    }
  }

  void _drawBedArea(double x, double y) {
    const double breathe = 0.5;
    _fillRadial(
      Offset(x + 359, y + 318),
      420 + breathe * 20,
      blue.withOpacity(0.22 + breathe * 0.08),
    );
    _fillRadial(
      Offset(x + 359, y + 580),
      250 + breathe * 12,
      cyan.withOpacity(0.08 + breathe * 0.04),
    );
  }

  void _drawBottomPulseLine({
    required bool includeTrack,
    required bool includeSweep,
  }) {
    const Rect rect = Rect.fromLTWH(620, 792, 699, 10);
    if (includeTrack) {
      _canvas.drawRRect(
        _rrect(rect, 5),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              blue.withOpacity(0.18),
              _rgb(7, 24, 42, 0.46),
              cyan.withOpacity(0.26),
              _rgb(7, 24, 42, 0.46),
              blue.withOpacity(0.18),
            ],
          ).createShader(rect),
      );
    }
    if (!includeSweep) {
      return;
    }
    final double p = _phase(2.8);
    final double sweepX = rect.left - 90 + (rect.width + 180) * p;
    final Rect sweep = Rect.fromLTWH(sweepX, rect.center.dy - 1.2, 160, 2.4);
    _drawRRectGlow(
      _rrect(sweep, 1.2),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Colors.transparent,
            cyan.withOpacity(0.9),
            Colors.transparent,
          ],
        ).createShader(sweep),
      cyan.withOpacity(0.9),
      10,
    );
  }

  void _drawCompactShowroomCard(double x, double y) {
    final MattressModeMetrics metrics = data.metricsFor(mode);
    final Rect rect = Rect.fromLTWH(x, y, 301, 222);
    _drawPanel(rect, 8);
    _withClipRRect(_rrect(rect, 8), () {
      _fillRadial(
          Offset(rect.right - 26, rect.top + 24), 130, cyan.withOpacity(0.11));
    });
    _drawText('SHOWROOM MODE',
        x: x + 18,
        y: y + 32,
        size: 12,
        color: cyan.withOpacity(0.78),
        align: _CanvasTextAlign.left,
        weight: FontWeight.w400,
        tracking: 2.1);
    _drawText(mode.buttonTitle,
        x: x + 18,
        y: y + 64,
        size: 21,
        color: text,
        align: _CanvasTextAlign.left,
        weight: FontWeight.w700,
        tracking: 0.6,
        glow: blue.withOpacity(0.22));
    _drawText(mode.subtitle,
        x: x + 18,
        y: y + 91,
        size: 11.5,
        color: muted.withOpacity(0.95),
        align: _CanvasTextAlign.left,
        weight: FontWeight.w400,
        tracking: 0.2);
    _drawCompactStatusChip(
        x + 18, y + 108, 124, 'LEFT', mode.side != 'right' && mode.reveal);
    _drawCompactStatusChip(
        x + 156, y + 108, 124, 'RIGHT', mode.side != 'left' && mode.reveal);

    const List<(String, String)> items = <(String, String)>[
      ('肩', 'shoulder'),
      ('背', 'back'),
      ('腰', 'waist'),
      ('臀', 'hip'),
      ('腿', 'leg'),
    ];
    for (int i = 0; i < items.length; i += 1) {
      final (String label, String key) = items[i];
      _drawCompactPressureBar(
        x + 20 + i * 53,
        y + 151,
        label,
        (metrics.pressureValues[key] ?? 0).toDouble(),
        (metrics.warningKey ?? mode.warningKey) == key,
      );
    }
  }

  void _drawCompactStatusChip(
      double x, double y, double width, String label, bool active) {
    final Rect rect = Rect.fromLTWH(x, y, width, 28);
    final Color accent = active ? green : blue;
    _canvas.drawRRect(
      _rrect(rect, 14),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            accent.withOpacity(active ? 0.22 : 0.11),
            _rgb(6, 24, 44, 0.60),
          ],
        ).createShader(rect),
    );
    _strokeRRect(_rrect(rect, 14), accent.withOpacity(active ? 0.44 : 0.20), 1);
    _drawOvalGlow(
      Rect.fromLTWH(x + 14, y + 10, 8, 8),
      accent.withOpacity(active ? 1 : 0.45),
      accent.withOpacity(active ? 0.9 : 0.35),
      active ? 8 : 4,
    );
    _drawText(label,
        x: x + 32,
        y: y + 20,
        size: 12,
        color: text.withOpacity(active ? 0.94 : 0.55),
        align: _CanvasTextAlign.left,
        weight: FontWeight.w700,
        tracking: 1.0);
  }

  void _drawCompactPressureBar(
      double x, double y, String label, double value, bool warning) {
    final Color accent = warning ? pink : cyan;
    final Rect track = Rect.fromLTWH(x, y, 34, 46);
    _canvas.drawRRect(_rrect(track, 6), Paint()..color = _rgb(4, 16, 31, 0.50));
    final double fillHeight = math.max(5, track.height * value / 100);
    final Rect fillRect = Rect.fromLTWH(track.left + 5,
        track.bottom - 5 - fillHeight, track.width - 10, fillHeight);
    _drawRRectGlow(
      _rrect(fillRect, 4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[
            blue.withOpacity(0.40),
            accent.withOpacity(0.95),
          ],
        ).createShader(fillRect),
      accent.withOpacity(0.65),
      warning ? 8 : 5,
    );
    _drawText(label,
        x: track.center.dx,
        y: y + 66,
        size: 11,
        color: muted,
        align: _CanvasTextAlign.center,
        weight: FontWeight.w400);
    _drawText(value.toInt().toString(),
        x: track.center.dx,
        y: y + 14,
        size: 10,
        color: text.withOpacity(0.82),
        align: _CanvasTextAlign.center,
        weight: FontWeight.w700);
  }

  void _drawPanel(Rect rect, double radius) {
    final RRect rrect = _rrect(rect, radius);
    _canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _rgb(10, 30, 53, 0.88),
            _rgb(5, 18, 34, 0.86),
          ],
        ).createShader(rect),
    );
    _canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.center,
          colors: <Color>[
            Colors.white.withOpacity(0.035),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    _strokeRRect(rrect, _rgb(73, 156, 255, 0.24), 1);
  }

  void _drawLegend(double x, double y, Color color, String label) {
    final Rect rect = Rect.fromLTWH(x, y - 6, 18, 4);
    _drawRRectGlow(_rrect(rect, 2), Paint()..color = color, color, 7);
    _drawText(label,
        x: x + 25,
        y: y,
        size: 13,
        color: muted,
        align: _CanvasTextAlign.left,
        weight: FontWeight.w400);
  }

  void _drawFooter() {
    final String time = _timeString();
    _drawText(
      '数据更新时间：  $time     |     当前模式：  ${mode.buttonTitle}     |     AI算法运行中',
      x: 960,
      y: 1054,
      size: 16,
      color: _rgb(225, 235, 250, 0.58),
      align: _CanvasTextAlign.center,
      weight: FontWeight.w400,
      tracking: 0.4,
    );
  }

  void _drawHeartIcon(Offset center, Color accent, double scale) {
    Offset pt(double x, double y) {
      return Offset(center.dx + (x - 24) * scale, center.dy + (y - 24) * scale);
    }

    final Path path = Path()
      ..moveTo(pt(24, 40).dx, pt(24, 40).dy)
      ..cubicTo(pt(13.7, 31.5).dx, pt(13.7, 31.5).dy, pt(8, 26).dx,
          pt(8, 26).dy, pt(8, 18.8).dx, pt(8, 18.8).dy)
      ..cubicTo(pt(8, 13.8).dx, pt(8, 13.8).dy, pt(11.7, 10).dx,
          pt(11.7, 10).dy, pt(16.7, 10).dx, pt(16.7, 10).dy)
      ..cubicTo(pt(20.3, 10).dx, pt(20.3, 10).dy, pt(22.8, 11.9).dx,
          pt(22.8, 11.9).dy, pt(24, 14.7).dx, pt(24, 14.7).dy)
      ..cubicTo(pt(25.2, 11.9).dx, pt(25.2, 11.9).dy, pt(27.7, 10).dx,
          pt(27.7, 10).dy, pt(31.3, 10).dx, pt(31.3, 10).dy)
      ..cubicTo(pt(36.3, 10).dx, pt(36.3, 10).dy, pt(40, 13.8).dx,
          pt(40, 13.8).dy, pt(40, 18.8).dx, pt(40, 18.8).dy)
      ..cubicTo(pt(40, 26).dx, pt(40, 26).dy, pt(34.3, 31.5).dx,
          pt(34.3, 31.5).dy, pt(24, 40).dx, pt(24, 40).dy);
    _canvas.drawPath(
        path,
        Paint()
          ..color = accent.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.1 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    _canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.1 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    final Path ecg = Path()
      ..moveTo(pt(13, 28).dx, pt(13, 28).dy)
      ..lineTo(pt(20, 28).dx, pt(20, 28).dy)
      ..lineTo(pt(23, 23).dx, pt(23, 23).dy)
      ..lineTo(pt(27, 31).dx, pt(27, 31).dy)
      ..lineTo(pt(30, 26).dx, pt(30, 26).dy)
      ..lineTo(pt(36, 26).dx, pt(36, 26).dy);
    _canvas.drawPath(
        ecg,
        Paint()
          ..color = _rgb(255, 205, 220, 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.15 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  void _drawLungIcon(Offset center, Color accent, double scale) {
    Offset pt(double x, double y) {
      return Offset(center.dx + (x - 24) * scale, center.dy + (y - 24) * scale);
    }

    final Path path = Path()
      ..moveTo(pt(22, 17.2).dx, pt(22, 17.2).dy)
      ..cubicTo(pt(15.8, 18.7).dx, pt(15.8, 18.7).dy, pt(11.9, 24.7).dx,
          pt(11.9, 24.7).dy, pt(11.9, 32).dx, pt(11.9, 32).dy)
      ..cubicTo(pt(11.9, 35).dx, pt(11.9, 35).dy, pt(13.4, 36.9).dx,
          pt(13.4, 36.9).dy, pt(15.9, 36.9).dx, pt(15.9, 36.9).dy)
      ..cubicTo(pt(19.3, 36.9).dx, pt(19.3, 36.9).dy, pt(22, 33.9).dx,
          pt(22, 33.9).dy, pt(22, 29.7).dx, pt(22, 29.7).dy)
      ..lineTo(pt(22, 17.2).dx, pt(22, 17.2).dy)
      ..moveTo(pt(26, 17.2).dx, pt(26, 17.2).dy)
      ..lineTo(pt(26, 29.7).dx, pt(26, 29.7).dy)
      ..cubicTo(pt(26, 33.9).dx, pt(26, 33.9).dy, pt(28.7, 36.9).dx,
          pt(28.7, 36.9).dy, pt(32.1, 36.9).dx, pt(32.1, 36.9).dy)
      ..cubicTo(pt(34.6, 36.9).dx, pt(34.6, 36.9).dy, pt(36.1, 35).dx,
          pt(36.1, 35).dy, pt(36.1, 32).dx, pt(36.1, 32).dy)
      ..cubicTo(pt(36.1, 24.7).dx, pt(36.1, 24.7).dy, pt(32.2, 18.7).dx,
          pt(32.2, 18.7).dy, pt(26, 17.2).dx, pt(26, 17.2).dy);
    _canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.1 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    final Path branch = Path()
      ..moveTo(pt(24, 7).dx, pt(24, 7).dy)
      ..lineTo(pt(24, 22).dx, pt(24, 22).dy)
      ..moveTo(pt(24, 22).dx, pt(24, 22).dy)
      ..cubicTo(pt(21.5, 23.4).dx, pt(21.5, 23.4).dy, pt(19.6, 25.2).dx,
          pt(19.6, 25.2).dy, pt(18.2, 27.3).dx, pt(18.2, 27.3).dy)
      ..moveTo(pt(24, 22).dx, pt(24, 22).dy)
      ..cubicTo(pt(26.5, 23.4).dx, pt(26.5, 23.4).dy, pt(28.4, 25.2).dx,
          pt(28.4, 25.2).dy, pt(29.8, 27.3).dx, pt(29.8, 27.3).dy);
    _canvas.drawPath(
        branch,
        Paint()
          ..color = _rgb(205, 232, 255, 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.15 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  void _drawVitalMiniWave(
    Rect rect,
    bool isHeart,
    Color accent,
    double? phase, {
    bool includeBase = true,
    double intensity = 1,
    bool drawDotGlow = true,
  }) {
    if (includeBase) {
      _canvas.drawRRect(
        _rrect(rect, 10),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              accent.withOpacity(0.10),
              Colors.transparent,
              accent.withOpacity(0.08),
            ],
          ).createShader(rect),
      );
    }
    final List<_VitalWaveSegment> segments = _waveSegments(rect, isHeart);
    final Path path = _wavePath(segments);
    if (includeBase) {
      _canvas.drawPath(
          path,
          Paint()
            ..color = accent.withOpacity(0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);
    }
    if (phase == null) {
      return;
    }
    final Path trimmed = _trimPath(path, 0, math.max(0.03, phase));
    _canvas.drawPath(
        trimmed,
        Paint()
          ..color = accent.withOpacity(0.55 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * intensity
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * intensity));
    _canvas.drawPath(
        trimmed,
        Paint()
          ..color = accent.withOpacity(0.68 + 0.32 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * intensity
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    final Offset dot = _pointOnWave(segments, phase);
    if (drawDotGlow) {
      _drawOvalGlow(
        Rect.fromCircle(center: dot, radius: 3.2),
        accent.withOpacity(0.9),
        accent.withOpacity(0.8),
        7,
      );
    } else {
      _canvas.drawOval(
        Rect.fromCircle(center: dot, radius: 2.3),
        Paint()..color = accent.withOpacity(0.78),
      );
    }
  }

  List<_VitalWaveSegment> _waveSegments(Rect rect, bool isHeart) {
    Offset pt(double xFactor, double yFactor) {
      return Offset(
        rect.left + rect.width * xFactor / 180,
        rect.top + rect.height * yFactor / 44,
      );
    }

    final Offset start = pt(0, 31);
    if (isHeart) {
      return <_VitalWaveSegment>[
        _VitalWaveSegment(start, pt(18, 31), pt(16, 31), pt(30, 31)),
        _VitalWaveSegment(pt(30, 31), pt(44, 31), pt(48, 30), pt(58, 20)),
        _VitalWaveSegment(pt(58, 20), pt(68, 10), pt(72, 42), pt(87, 31)),
        _VitalWaveSegment(pt(87, 31), pt(102, 20), pt(104, 31), pt(113, 18)),
        _VitalWaveSegment(pt(113, 18), pt(122, 5), pt(130, 34), pt(144, 31)),
        _VitalWaveSegment(pt(144, 31), pt(158, 28), pt(160, 31), pt(180, 31)),
      ];
    }
    return <_VitalWaveSegment>[
      _VitalWaveSegment(start, pt(21, 31), pt(24, 18), pt(42, 20)),
      _VitalWaveSegment(pt(42, 20), pt(60, 22), pt(68, 45), pt(80, 29)),
      _VitalWaveSegment(pt(80, 29), pt(92, 13), pt(94, 8), pt(110, 29)),
      _VitalWaveSegment(pt(110, 29), pt(126, 50), pt(129, 31), pt(140, 28)),
      _VitalWaveSegment(pt(140, 28), pt(151, 25), pt(154, 33), pt(180, 31)),
    ];
  }

  Path _wavePath(List<_VitalWaveSegment> segments) {
    final Path wave = Path();
    if (segments.isEmpty) {
      return wave;
    }
    wave.moveTo(segments.first.start.dx, segments.first.start.dy);
    for (final _VitalWaveSegment segment in segments) {
      wave.cubicTo(
        segment.control1.dx,
        segment.control1.dy,
        segment.control2.dx,
        segment.control2.dy,
        segment.end.dx,
        segment.end.dy,
      );
    }
    return wave;
  }

  Offset _pointOnWave(List<_VitalWaveSegment> segments, double progress) {
    const int samplesPerSegment = 12;
    final List<({Offset point, double length})> samples =
        <({Offset point, double length})>[];
    double totalLength = 0;
    for (final _VitalWaveSegment segment in segments) {
      Offset previous = segment.start;
      if (samples.isEmpty) {
        samples.add((point: previous, length: 0));
      }
      for (int index = 1; index <= samplesPerSegment; index += 1) {
        final Offset point = segment.point(index / samplesPerSegment);
        totalLength += (point - previous).distance;
        samples.add((point: point, length: totalLength));
        previous = point;
      }
    }
    if (totalLength <= 0) {
      return segments.isEmpty ? Offset.zero : segments.first.start;
    }
    final double target = progress.clamp(0, 1) * totalLength;
    final int laterIndex = samples.indexWhere(
        (({double length, Offset point}) sample) => sample.length >= target);
    if (laterIndex <= 0) {
      return samples.first.point;
    }
    final ({double length, Offset point}) earlier = samples[laterIndex - 1];
    final ({double length, Offset point}) later = samples[laterIndex];
    final double span = math.max(later.length - earlier.length, 0.0001);
    return Offset.lerp(
            earlier.point, later.point, (target - earlier.length) / span) ??
        later.point;
  }

  Path _pressurePath(
    double x,
    double y,
    double width,
    double height,
    List<double> values,
    MattressPressureChartData chart,
    double offset,
  ) {
    if (values.isEmpty) {
      return Path();
    }

    double valueY(double value) {
      final double range = math.max(1, chart.maxValue - chart.minValue);
      final double normalized = ((value - chart.minValue) / range).clamp(0, 1);
      return y + height - height * normalized + offset;
    }

    final Path path = Path()..moveTo(x, valueY(values.first));
    if (values.length == 1) {
      return path..lineTo(x + width, valueY(values.first));
    }

    final double step = width / (values.length - 1);
    for (int index = 1; index < values.length; index += 1) {
      final double previousX = x + step * (index - 1);
      final double currentX = x + step * index;
      final double previousY = valueY(values[index - 1]);
      final double currentY = valueY(values[index]);
      final double controlX = previousX + step * 0.5;
      path.cubicTo(
        controlX,
        previousY,
        controlX,
        currentY,
        currentX,
        currentY,
      );
    }
    return path;
  }

  void _drawWifi(double x, double y) {
    for (final double radius in <double>[13, 9, 4]) {
      _canvas.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: radius),
        _deg(225),
        _deg(90),
        false,
        Paint()
          ..color = blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawText(
    String value, {
    required double x,
    required double y,
    required double size,
    required Color color,
    required _CanvasTextAlign align,
    required FontWeight weight,
    double tracking = 0,
    Color? glow,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: tracking,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 1200);
    double originX = x;
    switch (align) {
      case _CanvasTextAlign.left:
        originX = x;
      case _CanvasTextAlign.center:
        originX = x - painter.width / 2;
      case _CanvasTextAlign.right:
        originX = x - painter.width;
    }
    final Offset origin = Offset(originX, y - painter.height * 0.82);
    if (glow != null) {
      final TextPainter glowPainter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: glow,
            fontSize: size,
            fontWeight: weight,
            letterSpacing: tracking,
            shadows: <Shadow>[Shadow(color: glow, blurRadius: 10)],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 1200);
      glowPainter.paint(_canvas, origin);
    }
    painter.paint(_canvas, origin);
  }

  void _fillRadial(Offset center, double radius, Color color) {
    final Rect bounds = Rect.fromCircle(center: center, radius: radius);
    _canvas.drawOval(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[color, Colors.transparent],
        ).createShader(bounds),
    );
  }

  void _withClipRRect(RRect rrect, VoidCallback draw) {
    _canvas.save();
    _canvas.clipRRect(rrect);
    draw();
    _canvas.restore();
  }

  RRect _rrect(Rect rect, double radius) {
    return RRect.fromRectAndRadius(rect, Radius.circular(radius));
  }

  void _strokeRRect(RRect rrect, Color color, double width) {
    _canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void _drawRRectGlow(RRect rrect, Paint paint, Color glow, double radius) {
    _canvas.drawRRect(
      rrect,
      Paint()
        ..color = glow.withOpacity(glow.opacity * 0.65)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius),
    );
    _canvas.drawRRect(rrect, paint);
  }

  void _drawRectGlow(Rect rect, Paint paint, Color glow, double radius) {
    _canvas.drawRect(
      rect,
      Paint()
        ..color = glow.withOpacity(glow.opacity * 0.65)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius),
    );
    _canvas.drawRect(rect, paint);
  }

  void _drawOvalGlow(Rect rect, Color color, Color glow, double radius) {
    _canvas.drawOval(
      rect,
      Paint()
        ..color = glow.withOpacity(glow.opacity * 0.65)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius),
    );
    _canvas.drawOval(rect, Paint()..color = color);
  }

  Path _trimPath(Path path, double start, double end) {
    final Path result = Path();
    for (final ui.PathMetric metric in path.computeMetrics()) {
      final double startDistance = metric.length * start.clamp(0, 1);
      final double endDistance = metric.length * end.clamp(0, 1);
      if (endDistance > startDistance) {
        result.addPath(
            metric.extractPath(startDistance, endDistance), Offset.zero);
      }
    }
    return result;
  }

  String _timeString() {
    return '${_pad(_now.hour)}:${_pad(_now.minute)}:${_pad(_now.second)}';
  }

  String _pad(int value) {
    return value < 10 ? '0$value' : '$value';
  }

  double _phase(double durationSeconds) {
    final int milliseconds = _now.millisecondsSinceEpoch;
    final double durationMs = durationSeconds * 1000;
    return (milliseconds % durationMs) / durationMs;
  }

  double _pulse(double phase, double center, double width) {
    final double distance =
        math.min((phase - center).abs(), 1 - (phase - center).abs());
    return math.max(0, 1 - distance / width);
  }

  double _deg(double degrees) => degrees * math.pi / 180;
}

class _VitalWaveSegment {
  const _VitalWaveSegment(this.start, this.control1, this.control2, this.end);

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  Offset point(double t) {
    final double clamped = t.clamp(0, 1);
    final double inverse = 1 - clamped;
    final double a = inverse * inverse * inverse;
    final double b = 3 * inverse * inverse * clamped;
    final double c = 3 * inverse * clamped * clamped;
    final double d = clamped * clamped * clamped;
    return Offset(
      start.dx * a + control1.dx * b + control2.dx * c + end.dx * d,
      start.dy * a + control1.dy * b + control2.dy * c + end.dy * d,
    );
  }
}

enum _CanvasTextAlign {
  left,
  center,
  right,
}

enum _ShowroomPaintLayer {
  static,
  dynamic,
}

const double _designWidth = 1920;
const double _designHeight = 1080;

Color _rgb(int red, int green, int blue, [double opacity = 1]) {
  return Color.fromRGBO(red, green, blue, opacity);
}
