// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'showroom_scene_embed_types.dart';

SmartMattressSceneEmbedController createSmartMattressSceneEmbedController({
  required SmartMattressSceneReadyCallback onReady,
  required SmartMattressSceneLoadingCallback onLoading,
  required SmartMattressSceneErrorCallback onError,
}) {
  return _WebSmartMattressSceneEmbedController(
    onReady: onReady,
    onLoading: onLoading,
    onError: onError,
  );
}

class _WebSmartMattressSceneEmbedController
    implements SmartMattressSceneEmbedController {
  _WebSmartMattressSceneEmbedController({
    required this.onReady,
    required this.onLoading,
    required this.onError,
  })  : _viewType = 'smart-mattress-scene-${_nextViewTypeId++}',
        _iframe = html.IFrameElement() {
    _iframe
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'transparent'
      ..style.display = 'block'
      ..style.pointerEvents = 'none'
      ..allow = 'autoplay';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );

    _messageSubscription = html.window.onMessage.listen(_handleMessageEvent);
    _errorSubscription = _iframe.onError.listen((_) {
      onLoading(false);
      onError('Three.js 页面加载失败');
    });
  }

  static int _nextViewTypeId = 0;

  final SmartMattressSceneReadyCallback onReady;
  final SmartMattressSceneLoadingCallback onLoading;
  final SmartMattressSceneErrorCallback onError;
  final String _viewType;
  final html.IFrameElement _iframe;

  StreamSubscription<html.MessageEvent>? _messageSubscription;
  StreamSubscription<html.Event>? _errorSubscription;

  @override
  Widget buildWidget() {
    return HtmlElementView(viewType: _viewType);
  }

  @override
  Future<void> load() async {
    onLoading(true);
    _iframe.src = _threeAssetUri().toString();
  }

  @override
  Future<void> applyUpdate(SmartMattressSceneUpdate update) async {
    if (update.mode != null) {
      _postCommand('setMode', update.mode);
    }
    if (update.heating != null) {
      _postCommand('setHeating', update.heating);
    }
    if (update.dashboardData != null) {
      _postCommand('setDashboardData', update.dashboardData);
    }
    if (update.sensorFlow != null) {
      _postCommand('setSensorFlow', update.sensorFlow);
    }
    if (update.rippleEffect != null) {
      _postCommand('setRippleEffect', update.rippleEffect);
    }
    if (update.reset) {
      _postCommand('resetView');
    }
  }

  @override
  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _errorSubscription?.cancel();
    _iframe.src = 'about:blank';
  }

  void _handleMessageEvent(html.MessageEvent event) {
    if (event.data is! String) {
      return;
    }

    final Object? payload = _tryDecodeJson(event.data as String);
    if (payload is! Map<String, Object?>) {
      return;
    }
    if (payload['source'] != 'smart-mattress-scene') {
      return;
    }

    final Object? scenePayload = payload['payload'];
    if (scenePayload is! Map<String, Object?>) {
      return;
    }

    if (scenePayload['type'] == 'ready') {
      onError(null);
      onLoading(false);
      onReady();
    }
  }

  void _postCommand(String command, [Object? value]) {
    final String message = jsonEncode(<String, Object?>{
      'source': 'smart-mattress-host',
      'command': command,
      if (value != null) 'value': value,
    });
    _iframe.contentWindow?.postMessage(message, '*');
  }
}

Object? _tryDecodeJson(String source) {
  try {
    return jsonDecode(source);
  } catch (_) {
    return null;
  }
}

Uri _threeAssetUri() {
  return Uri(
    path: 'assets/assets/three_adjustment/index.html',
    queryParameters: const <String, String>{
      'embedded': '1',
      'transparent': '1',
      'mode': 'flat',
      'ui': '0',
      'performance': 'balanced',
      'maxDpr': '1.25',
      'renderMode': 'onDemand',
    },
  );
}
