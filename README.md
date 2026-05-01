# harness-template

> AI 辅助开发工作流模板：**OpenSpec + Superpowers**
>
> 从「写代码」到「按规格交付」的完整闭环。

OpenSpec 管规格和记忆，Superpowers 管设计和执行 —— 两个工具各司其职，组合成一个有质量保证的端到端流程。

---

## 前置依赖

| 工具 | 用途 | 安装 |
|---|---|---|
| `openspec` CLI | 管理规格、变更、归档 | `brew install openspec` 或 `npm i -g openspec`（按官方文档） |
| Cursor + Superpowers 插件 | 提供 brainstorming / writing-plans / subagent-driven-development / TDD 等 skill | 在 Cursor 中安装 [`cursor-public/superpowers`](https://cursor.com) 插件 |
| Git | 版本控制（Superpowers 工作流里强制要求） | 略 |

模板默认 OpenSpec ≥ 1.2.0，Superpowers 已通过 Cursor 插件机制装好。

---

## 项目布局

```
.
├── AGENTS.md                     # AI 入口：整套工作流的「使用说明书」
├── README.md                     # 你正在看的这份
├── .cursor/
│   ├── commands/                 # /opsx:* slash 命令
│   │   ├── opsx-propose.md       # ① 起草 proposal/design/tasks
│   │   ├── opsx-explore.md       # 思考模式（不写代码）
│   │   ├── opsx-apply.md         # ③④⑤ 设计 + 构建 + 验证
│   │   └── opsx-archive.md       # ⑥ 归档 + 同步规格
│   └── skills/                   # Skill 形式的同名实现
│       ├── openspec-propose/
│       ├── openspec-apply-change/
│       ├── openspec-archive-change/
│       └── openspec-explore/
└── openspec/
    ├── config.yaml               # 项目上下文 + 各 artifact 的写作约定
    ├── changes/                  # 活跃变更（每个变更一个目录）
    │   └── archive/              # 已归档的变更（YYYY-MM-DD-<name>/）
    └── specs/                    # 长期能力规格（项目记忆）
```

---

## 完整闭环

```
① /opsx:propose      → OpenSpec 起草 proposal.md + design.md + tasks.md
       ↓
② 人工审查            → 确认 proposal.md 的方向
       ↓
③ /opsx:apply        → Superpowers brainstorming 深化 design.md
                       Superpowers writing-plans 把 tasks.md 拆成 TDD 原子任务
       ↓
④ /opsx:apply        → Superpowers subagent-driven-development 逐任务构建
                       每任务：实现子代理（TDD）+ 规格审查子代理 + 质量审查子代理
       ↓
⑤ /opsx:apply        → verification-before-completion 跑真实命令验证
       ↓
⑥ /opsx:archive      → 归档变更 + 把 delta specs 同步到 openspec/specs/
                       项目知识库随之增长
```

中间三步都由同一个命令 `/opsx:apply` 完成 —— 它就是连接 OpenSpec 与 Superpowers 的桥。

---

## 快速开始

```bash
# 1) 克隆模板，初始化你自己的项目
git clone <this-template> my-project && cd my-project
git remote set-url origin <your-repo>

# 2) 在 Cursor 中打开项目
cursor .

# 3) 在 Cursor Chat 里跑第一个变更
/opsx:propose 添加用户登录（邮箱 + 密码）
```

之后：

1. 仔细读一遍生成的 `openspec/changes/add-user-login/proposal.md`，看方向对不对。
2. 跑 `/opsx:apply add-user-login`：
   - AI 会判断 design.md 是否需要 brainstorming 深化（一般早期都需要）。
   - 然后判断 tasks.md 是否需要 writing-plans 原子化。
   - 最后用 subagent-driven-development 逐任务构建，每一步 TDD 红绿重构 + 双重审查。
3. 全部任务打完 ✓ 后，跑 `/opsx:archive add-user-login`，把这次变更产生的规格沉淀进 `openspec/specs/`。

下次再起新的变更时，子代理读 `openspec/specs/` 就能继承上一轮的所有约定，不需要重新摸索。

---

## 核心约定（重要）

### 单一真相源

所有 artifact 都在 `openspec/` 下。**不要**在 `docs/superpowers/` 下另建一份。

| 产物 | 路径 | 谁起草 | 谁深化 |
|---|---|---|---|
| `proposal.md` | `openspec/changes/<name>/` | `/opsx:propose` | 人工审查 |
| `design.md`   | `openspec/changes/<name>/` | `/opsx:propose` 起草 | `superpowers:brainstorming` |
| `tasks.md`    | `openspec/changes/<name>/` | `/opsx:propose` 起草 | `superpowers:writing-plans` |
| 能力规格 | `openspec/specs/<capability>/spec.md` | `/opsx:archive` 同步 | 后续每次变更 |

> Superpowers 的 brainstorming / writing-plans 默认会把产物写到 `docs/superpowers/...`。
> **本模板里必须覆盖这个默认值**，让它们直接写回 `openspec/changes/<name>/`。
> `.cursor/commands/opsx-apply.md` 已经包含这个覆盖指令，AI 会自动遵守。

### 子代理一定先读规格

每次 `subagent-driven-development` 派出新的实现子代理时，子代理在写代码之前必须依次读：

1. `openspec/changes/<name>/proposal.md` — 意图和非目标
2. `openspec/changes/<name>/design.md` — 架构和理由
3. 相关的 `openspec/specs/<capability>/spec.md` — 长期契约

子代理不继承对话历史，**规格层就是唯一的统一上下文**。这是整套流程能保持一致性的关键。

### TDD 是默认值

每个 task 的形式都是：

```
- [ ] Step 1: 写失败测试
- [ ] Step 2: 跑测试看到红
- [ ] Step 3: 写最小实现
- [ ] Step 4: 跑测试看到绿
- [ ] Step 5: 提交
```

如果某个 task 不是这个形状，说明它还没被 `writing-plans` 充分原子化。

### 验证 = 跑命令读输出

不允许「应该过了吧」「看起来没问题」这种判断。要说「测试通过」就必须刚跑过测试命令并读了输出。`superpowers:verification-before-completion` 就是这个守门员。

---

## 我什么时候应该跑哪个命令？

| 情况 | 命令 |
|---|---|
| 我有一个想法，但还没想清楚 | `/opsx:explore` |
| 我想清楚要做什么了，开始流程 | `/opsx:propose` |
| 起草完了，proposal 看起来 OK，开始干活 | `/opsx:apply` |
| 干到一半被打断，想接着干 | `/opsx:apply`（会从未完成的 task 继续） |
| 全部任务打完 ✓，所有验证都过 | `/opsx:archive` |
| 我突然想看看现在有哪些活跃变更 | `openspec list` |

---

## 它为什么有用

- **每次变更都沉淀成规格**。`/opsx:archive` 会把 delta specs 合并进 `openspec/specs/`，AI 不用重复摸索。
- **brainstorming 强制把假设说清楚**。AI 必须列出至少一个被否决的备选方案及其理由 —— 你能看到决策的全过程。
- **writing-plans 强制原子化**。task 不再是「实现登录功能」这种模糊指令，而是具体到「在 `auth/login.test.ts` 写这段测试」。
- **子代理隔离 + 双重审查**。实现子代理不污染主对话上下文；规格审查 + 质量审查两次拦截，把问题拦在合并前。
- **verification 守门**。代码不到验证通过不算完。

---

## 进阶

- 想要并行做多个变更？给每个变更开一个 git worktree，参考 `superpowers:using-git-worktrees`。
- 想自定义某种 artifact 的写法？编辑 `openspec/config.yaml` 的 `rules` 段。
- 想增加新的 slash 命令？在 `.cursor/commands/` 下新建 `.md` 文件，参考现有命令的 frontmatter 格式。

---

## License

MIT.
