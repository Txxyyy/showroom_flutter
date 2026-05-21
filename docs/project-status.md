# 项目状态

最后更新：2026-05-21

## 当前工作

| 项目 | 状态 |
| --- | --- |
| 仓库 | `showroom_flutter` |
| 当前分支 | `main` |
| 当前任务 | 集成 3D 场景联动、控制区切换和双侧独立波纹，并产出 release APK |
| 工作流文档 | `docs/mobile-development-workflow.md` |
| 计划目录 | `docs/plans/` |
| worktree 目录 | `.worktrees/` |

## 最近完成

- 将 Three.js 3D 床垫场景通过平台自适配嵌入层接入 Flutter：移动端走 WebView，Web 端走 iframe。
- 调整压电陶瓷高亮位置和尺寸，使其在对应侧横向居中，并与压电动画区域对齐。
- 优化波点涟漪表现：未点亮底态更暗、点径更小、扩散环更细更慢，且在涟漪到达时逐步提升邻域高亮。
- 修复左右波点按钮互斥问题，左右侧动画现在可以同时开启并异步运行。
- 在轻智能大屏中增加“演示控制区 / 产品功能介绍”切换，并补充心率、呼吸率、睡眠报告的产品介绍内容。
- 新增 Flutter Web 入口资源和本地 3D 预览脚本，方便浏览器联调。
- 完成 `prod` flavor release APK 构建，并在 Android 模拟器做安装启动验证。

## 验证记录

| 日期 | 范围 | 命令 | 结果 |
| --- | --- | --- | --- |
| 2026-05-21 | Dart 格式 | `dart format --output=none --set-exit-if-changed lib test` | PASS |
| 2026-05-21 | 静态分析 | `flutter analyze` | PASS |
| 2026-05-21 | 单元 / widget 测试 | `env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY flutter test` | PASS |
| 2026-05-21 | release APK | `env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY flutter build apk --release --flavor prod --dart-define=APP_ENV=prod` | PASS，产物 `build/app/outputs/flutter-apk/app-prod-release.apk` |
| 2026-05-21 | Android 安装启动 | `adb install -r build/app/outputs/flutter-apk/app-prod-release.apk` | PASS，应用成功启动到首页 |
| 2026-05-06 | 工作流文档 | `git diff --check` | PASS |
| 2026-05-06 | worktree ignore | `git check-ignore -v .worktrees/` | PASS，命中 `.gitignore:16` |
| 2026-05-06 | 旧入口文案 | `rg` 检查旧入口关键词 | PASS，未命中 |
| 2026-05-06 | 技能入口 | `rg -n "brainstorming\|writing-plans\|using-git-worktrees\|test-driven-development\|docs/project-status.md" README.md docs/mobile-development-workflow.md docs/project-status.md docs/templates` | PASS |
| 2026-05-06 | 流程减重 | `rg -n "轻量\\|标准\\|严格\\|节点交付物\\|流程服务于开发" docs/mobile-development-workflow.md docs/templates docs/project-status.md README.md` | PASS |
| 2026-05-06 | 文档空白 | `! rg -n "[ \\t]+$" README.md docs/mobile-development-workflow.md docs/project-status.md docs/templates` | PASS |
| 2026-05-06 | 流程长度 | `wc -l docs/mobile-development-workflow.md` | PASS，229 行 |
| 2026-05-06 | 多 agent 并行规范 | `rg -n "多 agent\\|并行执行矩阵\\|integration worktree\\|只并行实现，不并行决策" docs/mobile-development-workflow.md docs/templates/mobile-feature-plan-template.md docs/project-status.md` | 待运行 |
| 2026-05-06 | 设备化验证规范 | `rg -n "设备化验证\\|模拟器\\|截图\\|录屏\\|docs/validation" docs/mobile-development-workflow.md docs/templates/mobile-feature-plan-template.md docs/project-status.md` | 待运行 |

## 风险与阻塞

- 当前 release APK 仍使用 Android debug signing，适合本地安装演示，不适合作为正式分发包。
- Three.js 场景 bundle 仍是直接提交的打包产物；仓库里没有完整的前端打包配置，后续若继续调整 3D 逻辑，需要保持 bundle 与源码入口同步。

## 下一步

- 如果需要对外分发，补充正式 keystore 和 release signing 配置后重新打包。
- 如果后续设备侧开始上报真实数据，可将当前控制区按钮替换为真实 `sensorFlow` / `rippleEffect` 数据输入源。
- 若继续做浏览器联调，可优先在 Flutter Web 页面上收敛布局和交互，再回迁到移动端。

## 状态更新

### 2026-05-21：3D 场景联动与双侧波纹控制

- 分支：`main`
- worktree：未启用
- 流程等级：标准
- 并行模式：未启用
- 需求卡/设计：无
- 开发计划：无
- 已完成：
  - Flutter 移动端集成 3D 场景嵌入控制器，Android / iOS 分别接入本地资源加载能力。
  - 增加 Web 端 3D 页面嵌入支持，用于浏览器联调。
  - 轻智能大屏增加控制区与产品介绍区切换动画，移除冗余红框区域并重排内容布局。
  - 3D 场景支持左右独立压电高亮和波点涟漪按钮控制，左右动画异步运行。
  - 构建并验证 `prod` flavor release APK。
- 验证：
  - `flutter pub get`：PASS
  - `dart format --output=none --set-exit-if-changed lib test`：PASS
  - `flutter analyze`：PASS
  - `env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY flutter test`：PASS
  - `env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY flutter build apk --release --flavor prod --dart-define=APP_ENV=prod`：PASS
- 设备化验证：
  - 设备：Android Emulator `Pixel_6_Pro_API_33`
  - 场景：安装 APK、启动应用到首页
  - 截图：`/tmp/showroom_home.png`
  - 录屏：未产生
  - 日志：未单独归档
- 风险：
  - release 包仍为 debug signing
- 下一步：
  - 如需正式交付安装包，补正式签名后重新构建

## 状态更新模板

```markdown
### YYYY-MM-DD：<任务名>

- 分支：`codex/<type>-<topic>`
- worktree：`.worktrees/<topic>`
- 流程等级：轻量 / 标准 / 严格
- 并行模式：未启用 / 多 agent
- 需求卡/设计：`docs/plans/YYYY-MM-DD-<topic>-brief.md`
- 开发计划：`docs/plans/YYYY-MM-DD-<topic>.md`
- 已完成：
  - <具体交付物>
- 验证：
  - `<command>`：<PASS / FAIL / 未运行，原因>
- 设备化验证：
  - 设备：<platform/device/os 或 未运行，原因>
  - 场景：<启动/页面/交互>
  - 截图：<path 或 未产生>
  - 录屏：<path 或 不适用>
  - 日志：<path/摘要 或 不适用>
- 风险：
  - <没有则写“无”>
- 下一步：
  - <明确动作>
```
