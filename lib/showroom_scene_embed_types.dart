import 'package:flutter/widgets.dart';

const String smartMattressThreeSceneAsset =
    'assets/three_adjustment/index.html';

class SmartMattressSceneUpdate {
  const SmartMattressSceneUpdate({
    this.mode,
    this.heating,
    this.dashboardData,
    this.sensorFlow,
    this.rippleEffect,
    this.reset = false,
  });

  final String? mode;
  final Map<String, Object?>? heating;
  final Map<String, Object?>? dashboardData;
  final Map<String, Object?>? sensorFlow;
  final Map<String, Object?>? rippleEffect;
  final bool reset;

  bool get isEmpty {
    return mode == null &&
        heating == null &&
        dashboardData == null &&
        sensorFlow == null &&
        rippleEffect == null &&
        !reset;
  }
}

typedef SmartMattressSceneReadyCallback = void Function();
typedef SmartMattressSceneLoadingCallback = void Function(bool loading);
typedef SmartMattressSceneErrorCallback = void Function(String? error);

abstract class SmartMattressSceneEmbedController {
  Widget buildWidget();

  Future<void> load();

  Future<void> applyUpdate(SmartMattressSceneUpdate update);

  Future<void> dispose();
}
