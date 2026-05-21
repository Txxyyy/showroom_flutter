import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'showroom_scene_embed_types.dart';

const MethodChannel _androidAssetLoaderChannel = MethodChannel(
  'smart_mattress_asset_loader',
);

SmartMattressSceneEmbedController createSmartMattressSceneEmbedController({
  required SmartMattressSceneReadyCallback onReady,
  required SmartMattressSceneLoadingCallback onLoading,
  required SmartMattressSceneErrorCallback onError,
}) {
  return _MobileSmartMattressSceneEmbedController(
    onReady: onReady,
    onLoading: onLoading,
    onError: onError,
  );
}

class _MobileSmartMattressSceneEmbedController
    implements SmartMattressSceneEmbedController {
  _MobileSmartMattressSceneEmbedController({
    required this.onReady,
    required this.onLoading,
    required this.onError,
  }) : _webViewController =
            _buildWebViewController(onReady, onLoading, onError);

  final SmartMattressSceneReadyCallback onReady;
  final SmartMattressSceneLoadingCallback onLoading;
  final SmartMattressSceneErrorCallback onError;
  final WebViewController _webViewController;

  io.HttpServer? _assetServer;
  bool _disposed = false;

  @override
  Widget buildWidget() {
    return WebViewWidget(controller: _webViewController);
  }

  @override
  Future<void> load() async {
    onLoading(true);
    try {
      if (io.Platform.isAndroid) {
        await _loadAndroidAssetLoaderScene();
      } else if (io.Platform.isIOS) {
        await _loadIosAssetServerScene();
      } else {
        await _webViewController.loadFlutterAsset(smartMattressThreeSceneAsset);
      }
    } catch (error) {
      if (_disposed) {
        return;
      }
      onLoading(false);
      onError('$error');
    }
  }

  @override
  Future<void> applyUpdate(SmartMattressSceneUpdate update) async {
    if (update.isEmpty) {
      return;
    }

    final String script = _buildSceneUpdateScript(update);
    await _webViewController.runJavaScript(script);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _assetServer?.close(force: true);
  }

  Future<void> _loadAndroidAssetLoaderScene() async {
    final Object platformController = _webViewController.platform;
    if (platformController is! AndroidWebViewController) {
      throw StateError('Android WebView controller is unavailable.');
    }

    final Uri uri = _threeAssetUri(
      scheme: 'https',
      host: 'appassets.androidplatform.net',
      pathPrefix: '/flutter_assets/',
    );
    await _androidAssetLoaderChannel.invokeMethod<void>(
      'attach',
      <String, Object>{
        'webViewIdentifier': platformController.webViewIdentifier,
      },
    );
    await _webViewController.loadRequest(uri);
  }

  Future<void> _loadIosAssetServerScene() async {
    _assetServer ??= await _createFlutterAssetServer();
    await _webViewController.loadRequest(
      _threeAssetUri(
        scheme: 'http',
        host: io.InternetAddress.loopbackIPv4.address,
        port: _assetServer!.port,
        pathPrefix: '/',
      ),
    );
  }

  Future<io.HttpServer> _createFlutterAssetServer() async {
    final io.HttpServer server = await io.HttpServer.bind(
      io.InternetAddress.loopbackIPv4,
      0,
      shared: true,
    );
    server.listen(
      _handleFlutterAssetRequest,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('SmartMattress asset server error: $error');
      },
    );
    return server;
  }

  Future<void> _handleFlutterAssetRequest(io.HttpRequest request) async {
    final String normalizedPath = request.uri.path.replaceFirst(
      RegExp(r'^/+'),
      '',
    );
    final String assetKey = normalizedPath.startsWith('assets/')
        ? normalizedPath
        : 'assets/$normalizedPath';
    if (!assetKey.startsWith('assets/three_adjustment/')) {
      request.response.statusCode = io.HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      final ByteData data = await rootBundle.load(assetKey);
      request.response.headers.contentType = _assetContentType(assetKey);
      request.response.contentLength = data.lengthInBytes;
      request.response.add(data.buffer.asUint8List());
    } catch (_) {
      request.response.statusCode = io.HttpStatus.notFound;
    } finally {
      await request.response.close();
    }
  }
}

WebViewController _buildWebViewController(
  SmartMattressSceneReadyCallback onReady,
  SmartMattressSceneLoadingCallback onLoading,
  SmartMattressSceneErrorCallback onError,
) {
  late final WebViewController controller;
  controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.transparent)
    ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
      debugPrint(
        'SmartMattress WebView [${message.level.name}]: ${message.message}',
      );
    })
    ..addJavaScriptChannel(
      'smartMattress',
      onMessageReceived: (JavaScriptMessage message) {
        _handleSmartMattressMessage(message, onReady, onLoading, onError);
      },
    )
    ..addJavaScriptChannel(
      'SmartMattressBridge',
      onMessageReceived: (JavaScriptMessage message) {
        _handleSmartMattressMessage(message, onReady, onLoading, onError);
      },
    )
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) async {
          try {
            await controller.runJavaScript(_smartMattressBridgeScript);
            onError(null);
          } catch (error) {
            onLoading(false);
            onError('$error');
          }
        },
        onWebResourceError: (WebResourceError error) {
          if (error.isForMainFrame != true) {
            return;
          }
          onLoading(false);
          onError(error.description);
        },
      ),
    );
  return controller;
}

void _handleSmartMattressMessage(
  JavaScriptMessage message,
  SmartMattressSceneReadyCallback onReady,
  SmartMattressSceneLoadingCallback onLoading,
  SmartMattressSceneErrorCallback onError,
) {
  try {
    final Object? payload = jsonDecode(message.message);
    if (payload is! Map<String, Object?>) {
      return;
    }
    final Object? type = payload['type'];
    if (type == 'ready') {
      onError(null);
      onLoading(false);
      onReady();
    }
  } catch (_) {
    // The native iOS bridge can deliver non-JSON messages. They are not
    // needed for Flutter state sync.
  }
}

String _buildSceneUpdateScript(SmartMattressSceneUpdate update) {
  final String mode = jsonEncode(update.mode);
  final String heating = jsonEncode(update.heating);
  final String dashboardData = jsonEncode(update.dashboardData);
  final String sensorFlow = jsonEncode(update.sensorFlow);
  final String rippleEffect = jsonEncode(update.rippleEffect);

  return '''
  (function retrySmartMattressState() {
    if (window.SmartMattress3D && window.__smartMattressSetMode && window.__smartMattressSetHeating) {
      if ($dashboardData && window.__smartMattressSetDashboardData) {
        window.__smartMattressSetDashboardData($dashboardData);
      }
      if ($sensorFlow && window.__smartMattressSetSensorFlow) {
        window.__smartMattressSetSensorFlow($sensorFlow);
      }
      if ($rippleEffect && window.__smartMattressSetRippleEffect) {
        window.__smartMattressSetRippleEffect($rippleEffect);
      }
      if ($mode) {
        window.__smartMattressSetMode($mode);
      }
      if ($heating) {
        window.__smartMattressSetHeating($heating);
      }
      if (${update.reset ? 'true' : 'false'} && window.__smartMattressResetView) {
        window.__smartMattressResetView();
      }
      return true;
    }
    setTimeout(retrySmartMattressState, 120);
    return false;
  })();
  ''';
}

Uri _threeAssetUri({
  required String scheme,
  required String host,
  required String pathPrefix,
  int? port,
}) {
  return Uri(
    scheme: scheme,
    host: host,
    port: port,
    path: '$pathPrefix$smartMattressThreeSceneAsset',
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

io.ContentType _assetContentType(String path) {
  if (path.endsWith('.html')) {
    return io.ContentType.html;
  }
  if (path.endsWith('.js')) {
    return io.ContentType('text', 'javascript', charset: 'utf-8');
  }
  if (path.endsWith('.json')) {
    return io.ContentType.json;
  }
  if (path.endsWith('.css')) {
    return io.ContentType('text', 'css', charset: 'utf-8');
  }
  if (path.endsWith('.glb')) {
    return io.ContentType('model', 'gltf-binary');
  }
  if (path.endsWith('.gltf')) {
    return io.ContentType('model', 'gltf+json', charset: 'utf-8');
  }
  if (path.endsWith('.wasm')) {
    return io.ContentType('application', 'wasm');
  }
  if (path.endsWith('.png')) {
    return io.ContentType('image', 'png');
  }
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
    return io.ContentType('image', 'jpeg');
  }
  if (path.endsWith('.webp')) {
    return io.ContentType('image', 'webp');
  }
  if (path.endsWith('.svg')) {
    return io.ContentType('image', 'svg+xml', charset: 'utf-8');
  }
  return io.ContentType.binary;
}

const String _smartMattressBridgeScript = r'''
(function() {
  if (window.__smartMattressFlutterBridgeInstalled) return true;
  window.__smartMattressFlutterBridgeInstalled = true;

  if (window.SmartMattress3D && window.SmartMattress3D.getState && window.SmartMattress3D.getState().ready === true) {
    window.SmartMattressBridge.postMessage(JSON.stringify({ type: "ready" }));
  }

  const adjustmentZones = ["shoulder", "back", "waist", "hip", "leg"];
  const adjustmentModes = new Set(["auto", "zero", "left", "right", "deep"]);
  const zoneDuration = 5000;
  const adjustmentRunToken = { left: 0, right: 0 };
  const adjustmentRunning = { left: false, right: false };

  function callSmartMattress(method, ...args) {
    const api = window.SmartMattress3D;
    if (!api || typeof api[method] !== "function") return false;
    api[method](...args);
    return true;
  }

  function clearSideAdjustment(side) {
    adjustmentRunToken[side] += 1;
    adjustmentRunning[side] = false;
    adjustmentZones.forEach((zone) => callSmartMattress("stopBladder", side, zone));
    callSmartMattress("stopReveal", side);
  }

  function clearAllAdjustments() {
    clearSideAdjustment("left");
    clearSideAdjustment("right");
  }

  function runFineGrainedSideAdjustment(side, mode, token) {
    if (token !== adjustmentRunToken[side]) return;
    const shouldOrbitFromCurrentView = adjustmentRunning.left || adjustmentRunning.right;
    adjustmentRunning[side] = true;
    callSmartMattress("moveCameraToSide", side, { duration: 1800, path: shouldOrbitFromCurrentView ? "orbit" : "direct" });
    callSmartMattress("startReveal", side, { duration: 2600 });

    adjustmentZones.forEach((zone, index) => {
      window.setTimeout(() => {
        if (token !== adjustmentRunToken[side]) return;
        callSmartMattress("startBladder", side, zone, { mode });
      }, 2600 + index * zoneDuration);
      window.setTimeout(() => {
        if (token !== adjustmentRunToken[side]) return;
        callSmartMattress("stopBladder", side, zone);
      }, 2600 + (index + 1) * zoneDuration);
    });

    window.setTimeout(() => {
      if (token !== adjustmentRunToken[side]) return;
      adjustmentRunning[side] = false;
      callSmartMattress("stopReveal", side);
      if (!adjustmentRunning.left && !adjustmentRunning.right) {
        callSmartMattress("moveCameraToOverview", { duration: 3000 });
      }
    }, 2600 + adjustmentZones.length * zoneDuration + 250);
  }

  window.__smartMattressSetMode = function(mode) {
    if (window.SmartMattress3D && adjustmentModes.has(mode)) {
      const sides = mode === "left" ? ["left"] : mode === "right" ? ["right"] : ["left", "right"];
      if (sides.length > 1) {
        clearAllAdjustments();
        window.SmartMattress3D.setMode("flat");
      }
      sides.forEach((side, index) => {
        clearSideAdjustment(side);
        const token = adjustmentRunToken[side];
        window.setTimeout(() => runFineGrainedSideAdjustment(side, mode, token), index * 120);
      });
      return true;
    }
    clearAllAdjustments();
    if (window.SmartMattress3D && window.SmartMattress3D.setMode) {
      window.SmartMattress3D.setMode(mode);
      return true;
    }
    if (window.setMattressMode) {
      window.setMattressMode(mode);
      return true;
    }
    const button = document.querySelector('button[data-mode="' + mode + '"]');
    if (!button) return false;
    button.click();
    return true;
  };

  window.__smartMattressSetDashboardData = function(dashboardData) {
    if (window.SmartMattress3D && window.SmartMattress3D.setDashboardData) {
      window.SmartMattress3D.setDashboardData(dashboardData);
      return true;
    }
    return false;
  };

  window.__smartMattressSetHeating = function(heating) {
    if (window.SmartMattress3D && window.SmartMattress3D.setHeating) {
      window.SmartMattress3D.setHeating(heating);
      return true;
    }
    return false;
  };

  window.__smartMattressSetSensorFlow = function(sensorFlow) {
    if (window.SmartMattress3D && window.SmartMattress3D.setSensorFlow) {
      window.SmartMattress3D.setSensorFlow(sensorFlow);
      return true;
    }
    return false;
  };

  window.__smartMattressSetRippleEffect = function(rippleEffect) {
    if (window.SmartMattress3D && window.SmartMattress3D.setRippleEffect) {
      window.SmartMattress3D.setRippleEffect(rippleEffect);
      return true;
    }
    return false;
  };

  window.__smartMattressResetView = function() {
    clearAllAdjustments();
    if (window.SmartMattress3D && window.SmartMattress3D.resetView) {
      window.SmartMattress3D.resetView({ duration: 3000 });
      return true;
    }
    return false;
  };
  return true;
})();
''';
