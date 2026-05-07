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

## 移动端开发工作流

本仓库使用技能编排式移动端开发工作流。流程按轻量、标准、严格三级执行，目标是用最少交付物换取清晰需求、可验证实现和可恢复上下文：

- `brainstorming`：需求收敛、方案比较、设计确认。
- `writing-plans`：把确认后的设计拆成可执行的 TDD 任务计划。
- `using-git-worktrees`：按功能点创建独立 worktree，支持多会话并行；文档和单点小修可按风险跳过。
- `test-driven-development`：按 RED / GREEN / REFACTOR 实现行为变更。
- `verification-before-completion` 和 `requesting-code-review`：完成前验证和评审。
- `finishing-a-development-branch`：决定本地合并、创建 PR、保留或丢弃。

详细流程见：

```text
docs/mobile-development-workflow.md
```

项目状态更新见：

```text
docs/project-status.md
```

创建独立任务工作区：

```bash
git worktree add .worktrees/<task-name> -b codex/feature-<task-name> main
cd .worktrees/<task-name>
flutter pub get
flutter analyze
flutter test
```

## 本地运行

iOS 模拟器：

```bash
flutter run -d <ios-simulator-id> --flavor dev --dart-define=APP_ENV=dev
```

Android 模拟器或设备：

```bash
flutter run -d <android-device-id> --flavor dev --dart-define=APP_ENV=dev
```

应用启动后会锁定横屏，并进入沉浸式全屏显示。

## Flavor 命令

```bash
flutter run --flavor dev --dart-define=APP_ENV=dev
flutter run --flavor staging --dart-define=APP_ENV=staging
flutter run --flavor prod --dart-define=APP_ENV=prod
```

## 仪表盘数据与 Mock 展示

展厅仪表盘数据已从绘制逻辑中抽离为 `MattressDashboardData` 和 `MattressDashboardController`。心率、呼吸、趋势指标、压力折线图、各模式分区压力值和 3D 床垫气囊目标值，都可以通过外部传值更新；Flutter UI 与 WebView Three.js 场景会跟随同一份数据刷新。

dev 环境默认启用 2 秒一次的 mock 数据流，用于在模拟器上观察运行时变化：

```bash
flutter run -d <ios-simulator-id> --flavor dev --dart-define=APP_ENV=dev --dart-define=SHOWROOM_MOCK_STREAM=true
```

关闭 mock 数据流：

```bash
flutter run -d <ios-simulator-id> --flavor dev --dart-define=APP_ENV=dev --dart-define=SHOWROOM_MOCK_STREAM=false
```

接入真实数据源时，推荐把 HTTP polling、WebSocket、蓝牙、平台通道或本地 fixture replay 适配成 `Stream<Map<String, Object?>>`，再传入应用：

```dart
SmartMattressShowroomApp(
  config: AppEnvironmentConfig.current,
  dashboardPayloadStream: someStreamOfMapPayloads,
);
```

如果业务侧需要主动推送局部更新，也可以持有 controller：

```dart
final MattressDashboardController controller = MattressDashboardController();

SmartMattressShowroomApp(
  config: AppEnvironmentConfig.current,
  dashboardController: controller,
);

controller.applyPayload(payload);
```

`applyPayload` 支持增量更新，未传字段会保留当前值。示例 payload：

```dart
controller.applyPayload(<String, Object?>{
  'realtime': <String, Object?>{
    'heartRate': 91,
    'breathRate': 20,
  },
  'trend': <String, Object?>{
    'lumbarSupportIndex': 93,
    'lumbarSupportStatus': '稳定',
    'ergonomicIndex': 86,
    'ergonomicStatus': '良好',
  },
  'pressureChart': <String, Object?>{
    'currentValues': <double>[7010, 7450, 8020, 7680, 7220],
    'recommendedValues': <double>[6800, 7600, 7400, 8100, 6900],
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
```

压力分区 key 固定为 `shoulder`、`back`、`waist`、`hip`、`leg`；模式 key 使用 `auto`、`zero`、`left`、`right`、`deep`、`flat`。`values` 范围会限制在 `0..100`，`targets.pressure` 和 `targets.glow` 范围会限制在 `0..1`。

## 构建 APK

普通 release APK：

```bash
flutter build apk --release --flavor prod --dart-define=APP_ENV=prod
```

产物位置：

```text
build/app/outputs/flutter-apk/app-release.apk
```

按 CPU 架构拆包，适合真实设备分发：

```bash
flutter build apk --release --flavor prod --dart-define=APP_ENV=prod --split-per-abi
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
flutter build ios --release --flavor prod --dart-define=APP_ENV=prod
```

如果需要真机签名，请在 Xcode 中配置 Team、Bundle Identifier 和 Provisioning Profile。

## 验证命令

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --debug --flavor dev --dart-define=APP_ENV=dev
flutter build ios --simulator --debug --flavor dev --dart-define=APP_ENV=dev
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
