# 项目状态

最后更新：2026-05-06

## 当前工作

| 项目 | 状态 |
| --- | --- |
| 仓库 | `showroom_flutter` |
| 当前分支 | `codex/mobile-workflow-foundation` |
| 当前任务 | 规范移动端 AI 协作开发工作流 |
| 工作流文档 | `docs/mobile-development-workflow.md` |
| 计划目录 | `docs/plans/` |
| worktree 目录 | `.worktrees/` |

## 最近完成

- 梳理了需求收敛、开发计划、worktree 隔离、TDD、验证、评审和状态更新的技能编排顺序。
- 将移动端开发工作流主协议写入 `docs/mobile-development-workflow.md`。
- 新增项目状态文档，用于记录每次任务的验证证据、风险和下一步。
- 对工作流做了一轮减重：新增轻量、标准、严格三级流程，并用节点交付物矩阵限制文档产出，避免流程重于开发。
- 将主流程文档从阶段长说明收敛为分级规则、交付物矩阵和技能触发矩阵。
- 补充多 agent 并行开发规范：作为严格流程的可选加速器，使用 integration worktree、agent worktree 和并行执行矩阵约束职责边界。
- 补充移动端设备化验证规范：按需自动启动 iOS Simulator 或 Android Emulator，记录截图、录屏、日志和视觉结论。

## 验证记录

| 日期 | 范围 | 命令 | 结果 |
| --- | --- | --- | --- |
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

- 当前分支仍包含上一轮已产生的 Flutter flavor、CI 和平台配置改动；这些改动未在本次工作流修正文档中继续扩大，也未回滚。
- 本地 `flutter test` 之前出现过 Flutter test harness WebSocket 连接问题；后续功能开发需要在对应 worktree 中重新验证并记录实际结果。

## 下一步

- 用一次真实需求试运行该工作流：先判断轻量、标准或严格，再决定是否需要需求卡、计划和 worktree。
- 如果决定保留上一轮 flavor/CI 改动，需要单独走一次评审和验证。
- 如果决定回滚上一轮 flavor/CI 改动，需要在用户明确确认后单独处理。
- 试运行后观察两个指标：需求澄清是否更快、交付物是否真的帮助开发；如果没有帮助，继续删减。

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
