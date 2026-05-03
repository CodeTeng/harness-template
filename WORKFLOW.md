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

## 轻量路径：`/opsx:quick`（小功能直通车）

完整闭环本身有 5+ 步固定开销 + 每个 task 3+ 次子代理调用。对**真正的小修改**（改个字段、加个 log、修一个 bug、改文案），这个开销不划算。

`/opsx:quick` 是为这种场景设计的轻量入口：

```
/opsx:quick <自然语言描述要改什么>
  → 在对话里 5 行描述意图、文件、风险（不进 OpenSpec）
  → 列出 3-5 步 inline TDD task（不进 OpenSpec）
  → 自己 inline 跑（不派子代理）：每步 红 → 绿 → commit
  → ./init.sh 整体验证
  → 问：「这次有什么值得长期记住的吗？」
       是 → 帮你加一段到 openspec/specs/<capability>/spec.md（最小 diff）
       否 → 完事
```

成本对比（一个修字段 + 加一个 GET 端点）：

|              | 完整闭环（propose → apply → archive） | `/opsx:quick`           |
| ------------ | ------------------------------------- | ----------------------- |
| 子代理调用数 | ~15-20                                | **0**                   |
| OpenSpec 文件创建 | proposal + design + tasks + spec sync | 仅可选的 sediment       |
| TDD          | ✓（在子代理里）                       | ✓（inline）             |
| Verification | ✓                                     | ✓                       |
| 时间         | 10-15 分钟                            | 2-3 分钟                |

### 何时用 `/opsx:quick`

- 改动 < 1 小时工作量
- 触动 ≤ 3 个文件
- 不跨 capability
- 不涉及架构选择
- 你能马上写出 3-5 步 TDD task list

### 何时**不用**（应该走 `/opsx:propose`）

- 涉及多个文件 + 新行为协调
- 隐含技术选型（"用什么实现"、"怎么设计"）
- 你需要问 > 1 个澄清问题才能动手
- 这是一个全新的 capability

### 自动推荐

`/opsx:propose` 在拿到用户描述后会做一次 size 判断 —— 描述明显小（< 50 字 + 单一动作 + bug-fix 信号）时会主动反问「要不要切到 `/opsx:quick`？」让用户决定。这是默认行为，不需要额外配置。

## 当用户只说「帮我做个 X」时

判断 X 的规模再选路径：

- **< 1 小时的小事**（bug fix、加字段、改文案、加 log）→ `/opsx:quick`
- **真正的能力交付**（新功能、跨文件、有设计选择）→ `/opsx:propose`

如果不确定，就 `/opsx:propose` —— size triage 会提示你切换。**「这事简单到不需要走任何流程」的感觉**仍然要警惕：连 `/opsx:quick` 也至少强制 TDD + verification，这两条不能跳。

## 当你确实不知道该怎么做时

用 `/opsx:explore`。这是只读的「思考伙伴」模式。你可以读代码、画图、对比方案 —— 但不能写代码。等问题轮廓清晰后，退出 explore 模式，跑 `/opsx:propose` 或 `/opsx:quick`。

## Skill 速查表

**OpenSpec 工作流 skills**（本模板自带）：

- `openspec-propose` —— 由 `/opsx:propose` 调用
- `openspec-quick` —— 由 `/opsx:quick` 调用（轻量路径）
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

