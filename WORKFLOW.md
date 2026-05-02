# WORKFLOW.md

完整的 OpenSpec + Superpowers 工作流。`AGENTS.md` 是简短的路由层，本文是详细版本。

## 两套工具链各自的定位

- **OpenSpec** 管 **规格和记忆** —— 提案、长期能力规格、归档。它是 *我们约定要做什么* 的单一真相源。
- **Superpowers** 管 **设计和执行** —— brainstorming 探讨方案、writing-plans 把任务原子化成 TDD 步骤、subagent-driven-development 派子代理逐任务构建、verification-before-completion 做完工验证。它是 *我们怎么做* 的方法论。

两者不是替代关系，而是组合：

```
OpenSpec 提案 & 记忆 ── Superpowers 设计 & 构建 ── OpenSpec 归档
```

## 完整闭环

```
┌──────────────────┐
│ ① /opsx:propose  │  在 openspec/changes/<name>/ 下
│   (OpenSpec)     │  起草 proposal.md + design.md + tasks.md
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ② 人工审查        │  确认 proposal.md 抓住了正确的意图。
│   (manual)       │  这是写代码前唯一强制的人类把关点。
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ③ 设计           │  superpowers:brainstorming
│   (Superpowers)  │    → 深化 design.md（架构、备选方案）
│                  │  superpowers:writing-plans
│                  │    → 把 tasks.md 原子化成 TDD 红绿重构步骤
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ④ 构建           │  superpowers:subagent-driven-development
│   (Superpowers)  │    → 每个任务派一个全新的实现子代理（TDD）
│                  │    → 规格符合性审查子代理
│                  │    → 代码质量审查子代理
│                  │    → 循环修复直到两次审查都通过
│                  │    → 在 tasks.md 里把任务标记为 `- [x]`
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ⑤ 验证           │  superpowers:verification-before-completion
│   (Superpowers)  │  跑真实的 test / build / lint 命令，读取输出。
│                  │  之后才能宣布「完成」。
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ⑥ /opsx:archive  │  把 openspec/changes/<name>/ 移入 archive/
│   (OpenSpec)     │  把 delta specs 同步进 openspec/specs/<capability>/
│                  │  项目知识库随之增长。
└──────────────────┘
```

③ + ④ + ⑤ 三步都由 `**/opsx:apply <name>**` 触发。这条命令是 OpenSpec 与 Superpowers 之间的桥。

## 单一真相源规则

每种 artifact **有且只有一个** 存放位置：


| Artifact      | 存放位置                                          | 起草者                      | 深化者                            |
| ------------- | --------------------------------------------- | ------------------------ | ------------------------------ |
| `proposal.md` | `openspec/changes/<name>/`                    | `/opsx:propose`          | 人工审查（②）                        |
| `design.md`   | `openspec/changes/<name>/`                    | `/opsx:propose`（草稿）      | `superpowers:brainstorming`（③） |
| `tasks.md`    | `openspec/changes/<name>/`                    | `/opsx:propose`（草稿）      | `superpowers:writing-plans`（③） |
| 能力规格          | `openspec/specs/<capability>/spec.md`         | `/opsx:archive`（spec 同步） | 之后每一次 change                   |
| 归档            | `openspec/changes/archive/YYYY-MM-DD-<name>/` | `/opsx:archive`          | —                              |


> **关键覆盖项。** Superpowers 的 `brainstorming` 和 `writing-plans` 默认会把产物写到 `docs/superpowers/specs/` 和 `docs/superpowers/plans/`。**在本模板里你必须覆盖这个默认值**，让它们直接写到 `openspec/changes/<name>/design.md` 和 `tasks.md`。我们不允许 artifact 分裂在两个位置。OpenSpec 是唯一真相源。

## 子代理如何获得统一上下文

`subagent-driven-development` 派出全新实现子代理时，子代理 **完全没有** 对话历史。它的全部上下文来源就是你传给它的 + 它自己读的。要让所有子代理保持一致，控制器（你）必须指示每个子代理在写代码前依次读取：

1. `openspec/changes/<name>/proposal.md` —— 意图和非目标
2. `openspec/changes/<name>/design.md` —— 架构和决策依据
3. 所有相关的 `openspec/specs/<capability>/spec.md` —— 长期契约

这一点不可妥协。规格层就是让所有子代理保持一致的统一上下文。如果 `openspec/specs/` 还是空的（项目早期），仅 proposal + design 也够用。

## 当用户只说「帮我做个 X」时

不要直接动手。即便 X 看起来很简单：

1. 先跑 `/opsx:propose`。草稿能锁定意图，避免你做出错误假设。
2. 让人类确认 proposal（②）。
3. 跑 `/opsx:apply` 完成设计 + 构建。
4. 跑 `/opsx:archive` 同步规格。

「这事简单到不需要走流程」的感觉，恰恰是最容易让未经审视的假设浪费工作的时刻。

## 当你确实不知道该怎么做时

用 `/opsx:explore`。这是只读的「思考伙伴」模式。你可以读代码、画图、对比方案 —— 但不能写代码。等问题轮廓清晰后，退出 explore 模式，跑 `/opsx:propose`。

## Skill 速查表

**OpenSpec 工作流 skills**（本模板自带）：

- `openspec-propose` —— 由 `/opsx:propose` 调用
- `openspec-apply-change` —— 由 `/opsx:apply` 调用（编排 Superpowers）
- `openspec-archive-change` —— 由 `/opsx:archive` 调用
- `openspec-explore` —— 由 `/opsx:explore` 调用

**Superpowers 方法论 skills**（Cursor 插件）：

- `superpowers:brainstorming` —— 设计阶段
- `superpowers:writing-plans` —— 把任务原子化成 TDD 步骤
- `superpowers:subagent-driven-development` —— 构建阶段
- `superpowers:test-driven-development` —— TDD 纪律（每个实现子代理都要遵守）
- `superpowers:verification-before-completion` —— 验证守门
- `superpowers:using-git-worktrees` —— 隔离 feature 工作
- `superpowers:finishing-a-development-branch` —— 收尾分支

