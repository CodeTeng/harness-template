# CONVENTIONS.md

> **作用**：项目专属的编码、命名、提交、评审约定。让 AI 写出来的代码风格和现有代码一致。
>
> **何时读**：写或评审任何代码前；判断 import 路径、命名格式、提交信息要怎么写时。
>
> **何时更新**：约定变了、引入新工具链、团队达成新共识时。改动也走 OpenSpec change，把决策写进 design.md。
>
> **写作风格**：具体到能直接照做，少给原则、多给规则和例子。
>
> 把所有 `TODO:` 替换成本项目的真实内容，然后删除本提示框。

---

## 工具链

TODO: 列出项目使用的格式化、lint、类型检查、测试工具及调用方式。`./init.sh` 应该串起所有这些。


| 工具         | 命令                        |
| ---------- | ------------------------- |
| TODO: 格式化  | TODO: 例 `ruff format .`   |
| TODO: Lint | TODO: 例 `ruff check .`    |
| TODO: 类型   | TODO: 例 `mypy --strict .` |
| TODO: 测试   | TODO: 例 `pytest -q`       |


## 命名

TODO: 写到具体到 AI 能照搬的程度，不要写"清晰即可"这种废话。

- 文件：TODO: 例 `snake_case.py`
- 类：TODO: 例 `PascalCase`
- 函数 / 变量：TODO: 例 `snake_case`，函数用动词（`fetch_order` 不是 `order_fetcher`）
- 常量：TODO: 例 `UPPER_SNAKE_CASE`
- 测试文件：TODO: 例 `tests/<同源路径>/test_<module>.py`

## 导入和模块边界

TODO: 写清楚 import 规则。AI 子代理在审查阶段会按这个判断 import 是否合规。

- TODO: 例「绝对导入，从 `src/` 起，不允许 `../../..` 链。」
- TODO: 例「不允许循环导入，由 lint 强制。」
- TODO: 例「跨组件边界见 `[ARCHITECTURE.md](ARCHITECTURE.md)`。」

## 测试

模板默认 TDD（见 `superpowers:test-driven-development`）。下面是项目特定补充：

- TODO: 例「单元测试不允许碰真实数据库；集成测试用 `pytest-postgresql`。」
- TODO: 例「mock 的边界：只 mock 外部 HTTP 调用，不 mock 自家代码。」
- TODO: 例「测试名格式：`test_<动作>_<条件>_<期望>`，例 `test_create_order_when_user_unverified_raises`。」
- TODO: 例「覆盖率门槛：核心模块 90%+，工具模块 70%+。」

## 提交信息

TODO: 写明项目的 commit 规则。

- TODO: 例「Conventional Commits：`feat:` / `fix:` / `chore:` / `refactor:` / `docs:` / `test:`。」
- TODO: 例「主题行 ≤ 72 字符，祈使句（`add X`，不是 `added X`）。」
- TODO: 例「正文解释 **why**，不解释 **what**（diff 已经展示 what 了）。」
- TODO: 例「正文末尾引用 OpenSpec change 名字：`Change: add-user-login`。」

## PR / Code Review

TODO: 列出本项目的 PR 流程。

- TODO: 例「每个 PR 对应一个 OpenSpec change。PR 标题 = change 名。」
- TODO: 例「PR 描述链接到 `openspec/changes/<name>/proposal.md`。」
- TODO: 例「Reviewer 要确认：每一行改动都能追溯到 tasks.md 中的某个 task。」

## 错误处理

TODO: 写出本项目处理错误的统一方式。

- TODO: 例「跨进程/网络边界的错误必须是有类型的（不允许裸 `Exception`）。」
- TODO: 例「禁止吞错误（`try: ... except: pass` 是 lint 错误）；要么处理、要么 rethrow。」

## 日志

TODO: 写出日志规范。

- TODO: 例「生产环境结构化日志（JSON）；开发环境可读。」
- TODO: 例「绝对不许 log 密钥、PII、完整请求/响应 body。」
- TODO: 例「日志 level：DEBUG/INFO/WARN/ERROR；business-critical 事件用 INFO。」

## 故意不做的事

TODO: 列出在代码层面**故意拒绝**的做法，避免 AI 自作主张引入。

- TODO: 例「禁止 `Any` 类型未配 `# reason:` 注释。」
- TODO: 例「禁止全局可变状态。」
- TODO: 例「禁止 `# TODO` 注释不带 issue 号或 change 名。」