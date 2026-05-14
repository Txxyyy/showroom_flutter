# <Feature Name> Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** <一句话说明这次要构建或修复什么。>

**Architecture:** <2-3 句说明实现方案、主要边界和数据流。>

**Tech Stack:** Flutter 3.13.9, Dart 3.1.5, `webview_flutter`, Android/iOS flavors, Three.js WebView assets when relevant.

---

日期：YYYY-MM-DD
等级：标准 / 严格
需求卡：`docs/plans/YYYY-MM-DD-<topic>-brief.md`
设计文档：`docs/plans/YYYY-MM-DD-<topic>-design.md` 或不适用

## Assumptions

- <当前基线、范围边界、不会触碰的内容>

## Success Criteria

- <可验证标准 1>
- <可验证标准 2>
- 设备化验证证据已记录，若适用。
- `docs/project-status.md` 已更新。

## Worktree

使用 `superpowers:using-git-worktrees` 创建隔离工作区：

```bash
git check-ignore -v .worktrees/
git worktree add .worktrees/<topic> -b codex/<type>-<topic> main
cd .worktrees/<topic>
flutter pub get
```

基线检查：

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

如果基线失败，先记录失败并询问是否继续，不要把既有失败混入新任务。

## Change Scope

| 文件 | 动作 | 说明 |
| --- | --- | --- |
| `<path>` | Create / Modify / Test | <为什么需要改> |

## TDD Points

| 行为 | 测试文件 | RED 命令 | GREEN 命令 |
| --- | --- | --- | --- |
| <行为描述> | `<test-path>` | `flutter test <test-path>` | `flutter test <test-path>` |

## Parallel Execution Matrix

仅严格任务且启用多 agent 时填写；不启用时写“不启用，原因：<原因>”。

| Agent | Worktree | Branch | 职责 | 可写范围 | 禁止修改 | 验证命令 | 集成顺序 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Agent A | `.worktrees/<topic>-<slice>` | `codex/feature-<topic>-<slice>` | <职责> | `<path>` | `<path>` | `flutter test <test-path>` | 1 |

主会话负责需求、架构、共享接口、集成和最终质量门。Agent 只在分配范围内实现，不回滚他人改动。

## Task 1: <Component Or Behavior>

**Files:**
- Modify: `<exact/path.dart>`
- Test: `<exact/test_path.dart>`

**Step 1: Write the failing test**

```dart
test('<specific behavior>', () {
  // Arrange
  // Act
  // Assert
});
```

**Step 2: Run test to verify it fails**

Run:

```bash
flutter test <exact/test_path.dart>
```

Expected: FAIL because <missing behavior or known bug>.

**Step 3: Write minimal implementation**

Implement only what is needed for the failing test. Do not refactor unrelated code.

**Step 4: Run test to verify it passes**

Run:

```bash
flutter test <exact/test_path.dart>
```

Expected: PASS.

**Step 5: Commit**

```bash
git add <exact/path.dart> <exact/test_path.dart>
git commit -m "<type>: <short summary>"
```

## Task 2: <Next Component Or Behavior>

Repeat the same RED / GREEN / REFACTOR structure with exact files, commands, expected output, and commit step.

## Quality Gates

Use `superpowers:verification-before-completion` before claiming completion.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

平台配置变更追加：

```bash
flutter build apk --debug --flavor dev --dart-define=APP_ENV=dev
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --simulator --debug --flavor dev --dart-define=APP_ENV=dev
```

## Device Verification

启用：是 / 否，原因：<UI、交互、WebView、平台能力、严格任务，或跳过原因>

| 平台 | 设备/系统 | 场景 | 验收点 | 证据 |
| --- | --- | --- | --- | --- |
| iOS / Android | <device> | <启动、页面、关键交互> | <视觉或逻辑结论> | <截图/录屏/日志路径> |

优先命令：

```bash
flutter devices
flutter test integration_test -d <device-id> --flavor dev --dart-define=APP_ENV=dev
flutter run -d <device-id> --flavor dev --dart-define=APP_ENV=dev
```

无 `integration_test/` 时记录 smoke 步骤：

- 操作路径：<启动应用 -> 页面 -> 交互>
- 截图：`docs/validation/YYYY-MM-DD-<topic>/screenshots/<platform>-<screen>.png`
- 录屏：`docs/validation/YYYY-MM-DD-<topic>/recordings/<platform>-<flow>.mp4` 或不适用
- 日志：`docs/validation/YYYY-MM-DD-<topic>/logs/<platform>-<flow>.log` 或不适用

## Review And Finish

- 评审要求：自检 / `superpowers:requesting-code-review`。
- 处理反馈：`superpowers:receiving-code-review`。
- 分支收尾：`superpowers:finishing-a-development-branch`。
- 分支处理：合并 / PR / 保留 / 丢弃。
- 提交范围：<paths>
- 提交信息：`feat: <short summary>`
