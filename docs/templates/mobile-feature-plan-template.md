# <功能名> 开发计划

> **For Claude:** 如进入执行阶段，使用 `superpowers:executing-plans` 按任务逐项实现。

日期：YYYY-MM-DD
等级：标准 / 严格
需求卡：`docs/plans/YYYY-MM-DD-<topic>-brief.md`

## 假设

- <当前基线、范围边界、不会触碰的内容>

## 成功标准

- <可验证标准 1>
- <可验证标准 2>
- 设备化验证证据已记录，若适用。
- `docs/project-status.md` 已更新。

## worktree

```bash
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

## 变更范围

| 文件 | 动作 | 说明 |
| --- | --- | --- |
| `<path>` | 新增 / 修改 / 测试 | <为什么需要改> |

## TDD 点

| 行为 | 测试文件 | RED 命令 | GREEN 命令 |
| --- | --- | --- | --- |
| <行为描述> | `<test-path>` | `flutter test <test-path>` | `flutter test <test-path>` |

## 并行执行矩阵

仅严格任务且启用多 agent 时填写；不启用时写“不启用，原因：<原因>”。

| Agent | Worktree | Branch | 职责 | 可写范围 | 禁止修改 | 验证命令 | 集成顺序 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Agent A | `.worktrees/<topic>-<slice>` | `codex/feature-<topic>-<slice>` | <职责> | `<path>` | `<path>` | `flutter test <test-path>` | 1 |

主会话负责需求、架构、共享接口、集成和最终质量门。Agent 只在分配范围内实现，不回滚他人改动。

## 任务清单

1. 写最小失败测试，并确认失败原因符合预期。
2. 写最小实现让测试通过。
3. 在绿色状态下做必要局部整理。
4. 运行相关质量门和设备化验证。
5. 更新 `docs/project-status.md`。

## 质量门

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

## 设备化验证

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

## 收尾

- 评审要求：自检 / 请求代码评审。
- 分支处理：合并 / PR / 保留 / 丢弃。
- 提交范围：<paths>
- 提交信息：`feat: <short summary>`
