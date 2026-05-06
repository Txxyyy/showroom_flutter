# Smart Mattress Showroom Flutter

`showroom_flutter` 是智能床垫展厅的 Flutter 复刻工程。项目以 Flutter 绘制 1920 x 1080 横屏展示界面，并通过 WebView 承载 Three.js 3D 床垫模型，保持与 App 层交互的 JavaScript API 控制能力。

GitHub 仓库：

```text
https://github.com/Txxyyy/showroom_flutter
```

## 项目目标

- 独立 Flutter 工程，不修改原始 iOS SwiftUI 项目。
- 支持 iOS 与 Android 横屏沉浸式运行。
- 用 Flutter `CustomPainter` 绘制展厅背景、数据面板、波形、仪表盘、底部控制区等静态与动态 UI。
- 用 WebView 加载 Three.js 场景，展示 GLB 智能床垫模型。
- 通过 `window.SmartMattress3D` 公开 API 控制调节模式、加热区域、复位、视角和动画。

## 技术栈

- Flutter 3.13.9
- Dart 3.1.5
- `webview_flutter`
- `webview_flutter_android`
- Three.js r163
- GLB 模型资源：`assets/three_adjustment/smart-mattress-replica.glb`

## 目录结构

```text
showroom_flutter/
├── android/                         Android 工程
├── ios/                             iOS 工程
├── lib/
│   └── main.dart                    Flutter 展厅 UI 和 WebView 桥接
├── assets/
│   └── three_adjustment/
│       ├── index.html               Three.js 页面入口
│       ├── scene.bundle.js          打包后的 Three.js 场景逻辑
│       ├── smart-mattress-replica.glb
│       └── vendor/three/            本地 Three.js 依赖
├── tool/
│   └── three_adjustment_scene_entry.js
├── pubspec.yaml
└── README.md
```

## 3D 模型加载方式

当前实现使用 GLB：

- WebView 加载 `assets/three_adjustment/index.html`
- 页面加载 `scene.bundle.js`
- Three.js 使用 `GLTFLoader` 加载同目录下的 `smart-mattress-replica.glb`
- Flutter 通过 JavaScript 调用 `window.SmartMattress3D` 控制模型状态

Android 端使用 `WebViewAssetLoader` 将 Flutter asset 暴露为：

```text
https://appassets.androidplatform.net/flutter_assets/assets/three_adjustment/index.html
```

iOS 端使用本地 HTTP asset server 加载同一套 Three.js 资源。

## 安装依赖

```bash
flutter pub get
```

## 本地运行

iOS 模拟器：

```bash
flutter run -d <ios-simulator-id>
```

Android 模拟器或设备：

```bash
flutter run -d <android-device-id>
```

应用启动后会锁定横屏，并进入沉浸式全屏显示。

## 构建 APK

普通 release APK：

```bash
flutter build apk --release
```

产物位置：

```text
build/app/outputs/flutter-apk/app-release.apk
```

按 CPU 架构拆包，适合真实设备分发：

```bash
flutter build apk --release --split-per-abi
```

产物位置：

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

小米电视等真实设备通常优先安装 `arm64-v8a` 或 `armeabi-v7a` 包。`x86_64` 主要用于模拟器。

## 构建 iOS

模拟器运行：

```bash
flutter run -d <ios-simulator-id>
```

编译 iOS release：

```bash
flutter build ios --release
```

如果需要真机签名，请在 Xcode 中配置 Team、Bundle Identifier 和 Provisioning Profile。

## 验证命令

```bash
flutter analyze
flutter test
flutter build apk --release
```

说明：部分本地环境中 `flutter test` 可能受 Flutter 测试 harness WebSocket 连接影响失败，需要结合当前 Flutter SDK 与本机测试环境排查。

## WebView 和电视端注意事项

Android 手机、模拟器和 Android TV 的 WebView 能力不完全一致。小米电视上如果出现 3D 模型不显示，优先检查：

- 电视系统内置 Android System WebView 或 Chrome 版本是否过旧。
- WebView 是否支持 WebGL。
- `smart-mattress-replica.glb` 是否被 WebView 成功请求。
- 是否出现 WebGL context lost、GPU 内存不足或 GLB 解析失败。

建议通过 ADB 抓日志：

```bash
adb logcat | grep -i -E "SmartMattress|WebView|GLTF|WebGL|chromium|GL_OUT_OF_MEMORY|context"
```

如果日志显示资源请求失败，问题多半在 WebView asset 加载路径。如果日志显示 WebGL/GPU 错误，问题多半在电视 WebView 或 GPU 能力。

## JavaScript API

App 侧优先使用细粒度 API：

- `window.SmartMattress3D.startReveal(...)`
- `window.SmartMattress3D.startBladder(...)`
- `window.SmartMattress3D.stopBladder(...)`
- `window.SmartMattress3D.moveCameraToSide(...)`
- `window.SmartMattress3D.moveCameraToOverview(...)`
- `window.SmartMattress3D.setHeating(...)`
- `window.SmartMattress3D.resetView({ duration: 3000 })`

兼容 API：

- `window.SmartMattress3D.setMode(...)`

## 资源说明

`assets/three_adjustment/smart-mattress-replica.glb` 是当前 3D 床垫模型资源，已注册到 Flutter assets 中，release APK 会将其打包进去。

根目录调试截图、构建产物、Pods、Gradle 缓存和 Flutter 缓存均已通过 `.gitignore` 排除，不会提交到仓库。
