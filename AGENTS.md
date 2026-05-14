# Codex 使用说明

本文件适用于整个 `showroom_flutter` 仓库。后续 Codex 或其他 AI 代理进入本仓库时，先阅读本文件，再按任务需要阅读 `README.md`、`docs/mobile-development-workflow.md` 和相关源码。

## 工作原则

- 编码、评审、重构、调试前，先应用 Karpathy Guidelines：`/Users/tanxiaoyi/.claude/skills/pm-ai-playbook/skills/agentic-skills/karpathy-guidelines/SKILL.md`。
- 开始任何任务前，先按 Superpowers 入口判断适用子技能：`/Users/tanxiaoyi/.claude/skills/superpowers/skills/using-superpowers/SKILL.md`。
- 标准或严格任务按 `docs/mobile-development-workflow.md` 执行；不要只看本文件就跳过工作流。
- 开始实现前先说明假设和成功标准；不清楚会影响范围或验收时，先问一个关键问题。
- 优先做简单、外科手术式修改；不要重构无关代码，不要顺手改格式或命名。
- 匹配当前代码风格。Dart 代码遵循 `flutter_lints`，已有代码多使用显式类型、`const`、不可变数据对象和 `copyWith`。
- 只删除本次改动产生的孤立代码。发现既有死代码或历史问题时，在回复中说明，不要擅自删除。
- 收尾前必须做与变更匹配的本地验证；未运行的检查要写明原因。

## 项目概览

- 这是智能床垫展厅的 Flutter 复刻工程，目标是 1920 x 1080 横屏沉浸式展示。
- 主 Flutter UI 在 `lib/main.dart`，使用 `CustomPainter` 绘制背景、面板、波形、指标和底部控制区。
- 环境配置在 `lib/app_environment.dart`，支持 `dev`、`staging`、`prod` 三个 flavor。
- 3D 床垫场景由 WebView 加载 `assets/three_adjustment/index.html` 和 `assets/three_adjustment/scene.bundle.js`，模型资源是 `assets/three_adjustment/smart-mattress-replica.glb`。
- Three.js 源入口是 `tool/three_adjustment_scene_entry.js`；`scene.bundle.js` 是打包产物。仓库当前没有 `package.json` 或明确的本地打包脚本，修改 3D 场景前必须先确认打包方式。
- Android 通过 `MainActivity.kt` 中的 `WebViewAssetLoader` 暴露 Flutter assets；iOS 由 Dart 侧启动本地 HTTP asset server。
- 测试集中在 `test/widget_test.dart`，覆盖环境配置、调节模式、加热状态、仪表盘数据和 WebView payload。

## 关键文件

- `lib/main.dart`：应用入口、横屏沉浸式设置、仪表盘数据模型、控制器、主页面、WebView 桥接、CustomPainter UI。
- `lib/app_environment.dart`：`APP_ENV` 解析和 flavor title 映射。
- `android/app/build.gradle`：Android namespace、SDK、flavor、应用名和 release signing 配置。
- `android/app/src/main/kotlin/com/smartmattress/showroom_flutter/MainActivity.kt`：Android WebView asset loader 和 MIME 映射。
- `ios/Runner.xcodeproj/project.pbxproj`、`ios/Runner.xcodeproj/xcshareddata/xcschemes/*.xcscheme`：iOS flavor build configuration 和 scheme。
- `assets/three_adjustment/index.html`：Three.js 页面壳和调试 UI。
- `assets/three_adjustment/scene.bundle.js`：WebView 实际加载的 Three.js bundle。
- `docs/mobile-development-workflow.md`：移动端 AI 协作流程，是功能开发、平台改动和验证策略的主参考。
- `docs/project-status.md`：任务状态、验证记录、风险和下一步。

## 常用命令

安装依赖：

```bash
flutter pub get
```

格式检查：

```bash
dart format --output=none --set-exit-if-changed lib test
```

静态分析：

```bash
flutter analyze
```

测试：

```bash
flutter test
```

运行 dev flavor：

```bash
flutter run -d <device-id> --flavor dev --dart-define=APP_ENV=dev
```

关闭 dev mock 数据流：

```bash
flutter run -d <device-id> --flavor dev --dart-define=APP_ENV=dev --dart-define=SHOWROOM_MOCK_STREAM=false
```

Android debug 构建：

```bash
flutter build apk --debug --flavor dev --dart-define=APP_ENV=dev
```

iOS 模拟器 debug 构建：

```bash
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --simulator --debug --flavor dev --dart-define=APP_ENV=dev
```

生产 APK：

```bash
flutter build apk --release --flavor prod --dart-define=APP_ENV=prod
```

## 变更流程

- 文档、小配置、单文件无行为改动按轻量流程处理：假设、成功标准、最小修改、最小验证。
- 常规功能、bug fix、UI 状态变化或跨文件改动按标准流程处理，参考 `docs/mobile-development-workflow.md`。
- 架构、平台配置、发布、WebView/3D、flavor、构建脚本、多会话并行等高风险任务按严格流程处理。
- 需求或方案需要收敛时使用 `superpowers:brainstorming`；确认后用 `superpowers:writing-plans` 生成 `docs/plans/YYYY-MM-DD-<feature>.md`。
- 功能开发默认使用 `superpowers:using-git-worktrees` 创建 `.worktrees/<topic>` 隔离，除非只是文档或低风险单点小改。
- 行为变更默认走 `superpowers:test-driven-development`：先写最小失败测试，再实现，再重构本次改动产生的问题。
- 遇到 bug、测试失败、构建失败或运行异常时，先用 `superpowers:systematic-debugging` 查根因，不要猜修。
- 完成前用 `superpowers:verification-before-completion` 运行新鲜验证；高风险任务或合并前用 `superpowers:requesting-code-review`，收到反馈用 `superpowers:receiving-code-review`。
- 分支完成后用 `superpowers:finishing-a-development-branch` 提供合并、PR、保留或丢弃选项。
- UI、WebView、平台通道、启动流程、flavor 或平台构建配置有改动时，除了静态检查和测试，还要做至少一个目标模拟器或设备 smoke 验证；无法运行时说明缺口。

## 实现注意事项

- `lib/main.dart` 目前是大文件。除非任务明确要求拆分，优先在现有结构内做小范围修改；如需拆分，先给出边界和验证计划。
- 仪表盘外部数据入口是 `MattressDashboardController.applyPayload`。payload key 要保持 README 中约定：压力分区为 `shoulder`、`back`、`waist`、`hip`、`leg`；模式为 `auto`、`zero`、`left`、`right`、`deep`、`flat`。
- WebView 与 Three.js 的桥接依赖 `window.SmartMattress3D`、`SmartMattressBridge` 和 `_smartMattressBridgeScript`。改动其中任一侧时，要同时检查 Dart payload、JS API 和 ready 状态同步。
- Android WebView 资源路径是 `https://appassets.androidplatform.net/flutter_assets/assets/three_adjustment/index.html`；iOS 使用本地 loopback HTTP server。不要把资源加载逻辑简化成单一路径。
- 修改 `assets/three_adjustment/` 时，确认 `pubspec.yaml` 中的 assets 列表仍覆盖新增资源。
- Android 或 iOS flavor 变更必须同步检查 Dart `AppEnvironmentConfig`、Android productFlavors、iOS schemes/build configurations 和 CI 命令。
- 不要提交构建产物、`.dart_tool/`、`build/`、Pods、Gradle 缓存、根目录调试截图或 `.worktrees/`。

## 交付前检查

按变更范围选择最小但真实的检查：

- 仅文档：`git diff --check`，必要时用 `rg` 检查路径、命令和关键词。
- Dart 逻辑：`dart format --output=none --set-exit-if-changed lib test`、`flutter analyze`、相关 `flutter test`。
- Flutter UI：相关 widget test 或 smoke；必要时启动模拟器截图确认布局。
- WebView / 3D：相关 Dart 测试、目标模拟器启动、WebView 控制台或设备日志、截图/录屏。
- Android / iOS 配置：对应平台 debug build；改 flavor 时 Android 和 iOS 都要覆盖，无法覆盖时记录原因。
- 发布配置：release build、签名/证书状态和关键路径设备 smoke。

最终回复必须包含：改了什么、验证结果、未覆盖风险或未运行检查。
