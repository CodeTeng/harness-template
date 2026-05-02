# docs/ — 项目知识目录

> **这是给项目所有者填的目录**。模板自带 3 份占位文档（`ARCHITECTURE.md` / `PRODUCT.md` / `CONVENTIONS.md`），里面满是 `TODO:` 标记 —— 把它们替换成你项目的真实内容。
>
> 工作流相关的文档不在这里 —— 那些固定不变，放在项目根的 `[WORKFLOW.md](../WORKFLOW.md)`。

---

## AI 怎么用这个目录

**不要一次性全部加载**。按需查阅，由 `[AGENTS.md](../AGENTS.md)` 里「专题文档」表来路由。

发现某个事实未来还要用？提议**作为某个 OpenSpec change 的一部分**更新到这里 —— 不要静默地改。

## 自带文档


| 文档                                   | 作用               | 何时读                           |
| ------------------------------------ | ---------------- | ----------------------------- |
| `[ARCHITECTURE.md](ARCHITECTURE.md)` | 系统地图：组件、边界、数据流   | 跨组件改动、设计落地、评估爆炸半径             |
| `[PRODUCT.md](PRODUCT.md)`           | 产品 + 领域词典 + 业务规则 | 写新功能 proposal/design 时；遇到陌生术语 |
| `[CONVENTIONS.md](CONVENTIONS.md)`   | 编码、命名、提交、评审规范    | 写或评审任何代码前                     |


## 加新文档

当模板被 fork 到真实项目里，你大概率会想加项目专属的专题文档。常见模式：

- `docs/api-patterns.md` — API 设计规范、错误格式、分页约定
- `docs/database-rules.md` — schema 演进规则、迁移流程、索引策略
- `docs/testing-standards.md` — 测试分层、mock 策略、CI 规则
- `docs/RUNBOOK.md` — 运维手册（部署、回滚、on-call）
- `docs/TROUBLESHOOTING.md` — 反复出现的故障模式 + 修复方法
- `docs/DECISIONS/<NN>-<topic>.md` — ADR 风格的架构决策记录

**加新文档时**：

1. 写 `docs/<新文档>.md`，开头照着自带 3 份的格式写一段「作用 / 何时读 / 何时更新 / 写作风格」框。
2. 在本文件（`docs/README.md`）的「自带文档」表加一行。
3. 在 `[AGENTS.md](../AGENTS.md)` 的「专题文档」路由表加一行。

不更新这两张表 = AI 找不到 = 等于没写。

## docs/ vs openspec/specs/ 的边界

模板里有两个写"项目知识"的地方，别搞混。


| 放在 `docs/`     | 放在 `openspec/specs/`          |
| -------------- | ----------------------------- |
| 稳定、跨能力的知识      | 单个 capability 的契约（输入/输出/边界条件） |
| 系统**今天怎么运作**   | 某个能力**承诺什么**                  |
| 产品 / 领域术语      | 一个能力的具体行为                     |
| 编码约定、运维手册、故障排查 | 该能力的输入、输出、边界条件                |


判断准则一句话：**未来某次 change 可能整段重写它吗？** 会的话归 specs，不会归 docs。

例：

- 「我们用 PostgreSQL 而不是 MySQL，因为 X」→ `docs/ARCHITECTURE.md`（稳定决策）
- 「订单状态机有 7 个状态，转移规则如下」→ `openspec/specs/order/spec.md`（这个能力的契约）

