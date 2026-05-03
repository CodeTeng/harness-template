# harness-template

> AI 辅助开发工作流模板：**OpenSpec + Superpowers**
>
> 从「写代码」到「按规格交付」的完整闭环。

OpenSpec 管规格和记忆，Superpowers 管设计和执行 —— 两个工具各司其职，组合成一个有质量保证的端到端流程。

---

## 前置依赖


| 工具                      | 用途                                                                           | 安装                                                                |
| ----------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `openspec` CLI          | 管理规格、变更、归档                                                                   | `brew install openspec` 或 `npm i -g openspec`（按官方文档）              |
| Cursor + Superpowers 插件 | 提供 brainstorming / writing-plans / subagent-driven-development / TDD 等 skill | 在 Cursor 中安装 `[cursor-public/superpowers](https://cursor.com)` 插件 |
| Git                     | 版本控制（Superpowers 工作流里强制要求）                                                   | 略                                                                 |


模板默认 OpenSpec ≥ 1.2.0，Superpowers 已通过 Cursor 插件机制装好。

---

## 项目布局

```
.
├── AGENTS.md                     # AI 入口（路由层，每个项目自己填 TODO）
├── WORKFLOW.md                   # 工作流参考（模板级、固定不变）
├── README.md                     # 你正在看的这份
├── init.sh                       # 启动 + 验证入口脚本（项目里填栈相关命令）
├── docs/                         # 项目知识目录（每个项目自己填）
│   ├── README.md                 #   docs 目录的索引 + 加新 doc 的指引
│   ├── ARCHITECTURE.md           #   系统架构（TODO 占位）
│   ├── PRODUCT.md                #   产品 / 领域知识（TODO 占位）
│   └── CONVENTIONS.md            #   编码 / 提交规范（TODO 占位）
├── .cursor/
│   ├── rules/                    # alwaysApply 规则（每次对话都加载）
│   │   ├── karpathy-guidelines.mdc          #   思考纪律
│   │   ├── harness-startup-workflow.mdc     #   启动顺序
│   │   └── respond-in-chinese.mdc           #   回答用中文
│   ├── commands/                 # /opsx:* slash 命令
│   │   ├── opsx-propose.md       #   ① 起草 proposal/design/tasks（含 size triage）
│   │   ├── opsx-quick.md         #   小功能直通车（inline TDD + verification，0 子代理）
│   │   ├── opsx-explore.md       #   思考模式（不写代码）
│   │   ├── opsx-apply.md         #   ③④⑤ 设计 + 构建 + 验证（含 3 道 cost-control 闸）
│   │   └── opsx-archive.md       #   ⑥ 归档 + 同步规格
│   └── skills/                   # Skill 形式的同名实现
│       ├── openspec-propose/
│       ├── openspec-quick/
│       ├── openspec-apply-change/
│       ├── openspec-archive-change/
│       └── openspec-explore/
└── openspec/
    ├── config.yaml               # 项目上下文 + 各 artifact 的写作约定
    ├── changes/                  # 活跃变更（每个变更一个目录）
    │   └── archive/              # 已归档的变更（YYYY-MM-DD-<name>/）
    └── specs/                    # 长期能力规格（项目记忆）
```

模板分两层：

- **模板级**（不要改）：`WORKFLOW.md`、`.cursor/`、`init.sh` 骨架、`openspec/config.yaml` —— 整套工作流的固定部分，模板升级时直接替换。
- **项目级**（你来填）：`AGENTS.md`、`docs/*.md`、`init.sh` 里的 TODO 注释块、`README.md` —— 全文搜索 `TODO:` 一处一处替换。

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

## 如何引入到你的项目

下面三种场景任选一种。

### 场景 A · 新项目从零开始（推荐）

```bash
# 通过 GitHub Template
gh repo create my-project --template <owner>/harness-template --private --clone
cd my-project

# 或：clone 后换 remote
git clone https://github.com/<owner>/harness-template.git my-project
cd my-project
rm -rf .git && git init
git add . && git commit -m "chore: bootstrap from harness-template"
git remote add origin <your-new-repo-url>
git push -u origin main
```

### 场景 B · 把模板叠加到已有项目

适用于已有代码库，只想引入 harness 这一层。**只复制必要文件，不动你的现有代码**：

```bash
cd /path/to/existing-project

# 1) 把模板拉到临时目录
git clone https://github.com/<owner>/harness-template.git /tmp/harness-template

# 2) 复制必要文件（-n = 不覆盖现有文件）
cp -rn /tmp/harness-template/{AGENTS.md,WORKFLOW.md,init.sh,docs,.cursor,openspec} .

# 3) 合并 .gitignore（人工 review，避免覆盖你已有的规则）
cat /tmp/harness-template/.gitignore >> .gitignore
# 然后手工去重和审查

# 4) 让 init.sh 可执行
chmod +x init.sh

# 5) 验证
./init.sh

# 6) 提交
git add AGENTS.md WORKFLOW.md init.sh docs .cursor openspec .gitignore
git commit -m "chore: adopt OpenSpec + Superpowers harness"
```

### 场景 C · 一行命令脚本（最快）

适合只想试一下、还没决定要不要长期引入：

```bash
# 在你项目根目录跑
git clone --depth 1 https://github.com/<owner>/harness-template.git /tmp/ht && \
  cp -rn /tmp/ht/{AGENTS.md,WORKFLOW.md,init.sh,docs,.cursor,openspec} . && \
  chmod +x init.sh && \
  rm -rf /tmp/ht && \
  ./init.sh
```

跑完之后看下 `AGENTS.md` 的 TODO 列表，决定要不要继续。

---

## 如何使用这个模板

引入后，按下面的顺序把模板从「壳子」变成「你的项目骨架」。

### 第 1 步 · 填 TODO

全文搜索 `TODO:`，按提示替换。每份 `docs/` 文档顶部都有一段元信息框（**作用 / 何时读 / 何时更新 / 写作风格**）告诉你该写什么。

需要替换 TODO 的文件：

- `AGENTS.md` —— 项目概览、技术栈、快速开始、硬约束、文档索引
- `docs/ARCHITECTURE.md` —— 系统全景图、组件、模块边界、数据流、外部依赖
- `docs/PRODUCT.md` —— 产品定位、用户角色、领域词典、业务规则
- `docs/CONVENTIONS.md` —— 工具链、命名、测试、提交、PR 流程
- `init.sh` —— 取消注释你栈对应的那段（Node / Python / Rust / Go），删除其它

### 第 2 步 · 验证 init.sh

```bash
./init.sh
```

应该看到 `✓ project root confirmed`、`✓ openspec X.Y.Z`、活跃 change 列表，以及你刚配的栈相关命令依次跑通。

### 第 3 步 · 在 Cursor 里跑第一个变更

```
/opsx:propose 添加用户登录（邮箱 + 密码）
```

之后：

1. 仔细读一遍生成的 `openspec/changes/add-user-login/proposal.md`，看方向对不对。
2. 跑 `/opsx:apply add-user-login`：
  - AI 会判断 `design.md` 是否需要 brainstorming 深化（一般早期都需要）。
  - 然后判断 `tasks.md` 是否需要 writing-plans 原子化。
  - 最后用 subagent-driven-development 逐任务构建，每一步 TDD 红绿重构 + 双重审查。
3. 全部任务打完 ✓ 后，跑 `/opsx:archive add-user-login`，把这次变更产生的规格沉淀进 `openspec/specs/`。

下次再起新的变更时，子代理读 `openspec/specs/` 就能继承上一轮的所有约定，不需要重新摸索。

### 第 4 步 · 加项目专属文档

模板自带的 `ARCHITECTURE / PRODUCT / CONVENTIONS` 不够时，按 `docs/README.md` 里的步骤加新 doc：

1. 写 `docs/<新文档>.md`，开头照自带 3 份的元信息框格式
2. 在 `docs/README.md` 的目录表加一行
3. 在 `AGENTS.md` 的「专题文档」路由表加一行

不更新这两张表 = AI 找不到 = 等于没写。

---

## 升级模板

模板级文件和项目级文件分得很清楚，所以升级时不会冲突 —— 你改的是 `docs/*.md` 和 `AGENTS.md`，模板改的是 `WORKFLOW.md`、`.cursor/`、`init.sh` 骨架。

```bash
# 1) 拉最新版到临时目录
git clone --depth 1 https://github.com/<owner>/harness-template.git /tmp/ht-latest

# 2) 比对模板级文件，按需合并
diff -u  WORKFLOW.md            /tmp/ht-latest/WORKFLOW.md
diff -ur .cursor                /tmp/ht-latest/.cursor
diff -u  openspec/config.yaml   /tmp/ht-latest/openspec/config.yaml

# 3) 选择性覆盖
cp /tmp/ht-latest/WORKFLOW.md .
cp -r /tmp/ht-latest/.cursor/rules .cursor/
# init.sh 不要直接覆盖（你的栈命令在里面）；只对比、人工合并

# 4) 清理
rm -rf /tmp/ht-latest

# 5) 跑一遍 init.sh 验证没破坏
./init.sh
```

---

## 核心约定（重要）

### 单一真相源

所有 artifact 都在 `openspec/` 下。**不要**在 `docs/superpowers/` 下另建一份。


| 产物            | 路径                                    | 谁起草                | 谁深化                         |
| ------------- | ------------------------------------- | ------------------ | --------------------------- |
| `proposal.md` | `openspec/changes/<name>/`            | `/opsx:propose`    | 人工审查                        |
| `design.md`   | `openspec/changes/<name>/`            | `/opsx:propose` 起草 | `superpowers:brainstorming` |
| `tasks.md`    | `openspec/changes/<name>/`            | `/opsx:propose` 起草 | `superpowers:writing-plans` |
| 能力规格          | `openspec/specs/<capability>/spec.md` | `/opsx:archive` 同步 | 后续每次变更                      |


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


| 情况                                         | 命令                                                          |
| ------------------------------------------ | ----------------------------------------------------------- |
| 我有一个想法，但还没想清楚                              | `/opsx:explore`                                             |
| **小事**：bug fix / 加字段 / 改文案 / 加 log（< 1 小时）  | `/opsx:quick`                                               |
| 真正的功能或能力交付（不确定时也用这个 — 它会自动判断小事并提示切到 quick） | `/opsx:propose`                                             |
| 起草完了，proposal 看起来 OK，开始干活                  | `/opsx:apply`                                               |
| 干到一半被打断，想接着干                               | `/opsx:apply`（会从未完成的 task 继续）                                |
| 全部任务打完 ✓，所有验证都过                            | `/opsx:archive`                                             |
| 我突然想看看现在有哪些活跃变更                            | `openspec list`                                             |

### 重型路径 vs 轻量路径

|                | `/opsx:propose` → `apply` → `archive`（重型）  | `/opsx:quick`（轻量）            |
| -------------- | -------------------------------------------- | ----------------------------- |
| 适用             | 真正的功能交付（新能力、跨文件、有设计选择）            | 小修改（< 1 小时、≤ 3 文件、无架构决策） |
| 子代理调用数      | ~15-20+                                      | **0**                         |
| OpenSpec 文件创建 | proposal + design + tasks + spec sync        | 仅可选的 sediment              |
| TDD            | ✓（在子代理里）                                | ✓（inline）                    |
| Verification   | ✓                                            | ✓                             |
| 知识沉淀         | 自动同步进 `openspec/specs/`                  | 末尾问一句 → 用户决定           |
| 时间             | 10-15 分钟                                   | 2-3 分钟                       |


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
- 想自定义某种 artifact 的写法？编辑 `openspec/config.yaml` 的 `rules:` 段。
- 想增加新的 slash 命令？在 `.cursor/commands/` 下新建 `.md` 文件，参考现有命令的 frontmatter 格式。
- 想加新的 always-apply rule？在 `.cursor/rules/` 下新建 `.mdc` 文件。

---

## License

MIT.