---
name: /opsx-quick
id: opsx-quick
category: Workflow
description: Lightweight path for small changes — TDD inline, no subagents, no full OpenSpec cycle. Asks at the end whether to capture lessons into specs.
---

The **lightweight path** for small changes. Skips the full OpenSpec +
Superpowers cycle and runs everything inline, while keeping TDD and
verification as hard floors.

**Use this when** the change is roughly < 1 hour of work: a bug fix, adding
a field, a small endpoint, a copy change, a log line, a small refactor.

**Don't use this when** the change involves architectural decisions, new
capabilities, multiple files coordinating new behavior, or anything where
"intent could drift". Use `/opsx:propose` instead.

**Cost profile** (vs full cycle):

|              | Full cycle (`propose` → `apply` → `archive`) | Quick path |
| ------------ | -------------------------------------------- | ---------- |
| Subagent calls | ~15-20 (with 3 tasks)                      | **0**      |
| OpenSpec writes | proposal + design + tasks + spec sync      | optional sediment only |
| TDD            | ✓ via subagents                              | ✓ inline   |
| Verification   | ✓                                            | ✓          |
| Quality reviewer | ✓ per task                                | only if user asks |

---

**Input**: The argument after `/opsx:quick` describes what to change.
Required — do not proceed without one.

```
/opsx:quick <自然语言描述要改什么、为什么>
例: /opsx:quick 给 user 表加 phone 字段，加 GET /users/{id}/phone 端点
例: /opsx:quick 修一下 OrderService.refund 计算 0 元退款会抛 NaN 的 bug
```

If no input was provided, ask for one (open-ended) and wait. Do **not** start
guessing.

---

## Steps

### 1. Confirm scope

Read the user's description. In ≤ 5 lines, restate:

```
Plan
─────
意图:    <一句话>
触动文件: <最多列 3 个; 多于 3 个就停下来 → 这事不小>
风险:    <一句话; 没有就写 "无明显风险">
```

**Stop conditions** (any one triggers a switch back to `/opsx:propose`):

- 涉及 > 3 个文件
- 改动跨越 > 1 个 capability
- 描述里隐含架构选择（"用什么技术"、"怎么设计"）
- 你自己读完描述后还需要问澄清问题超过一个

If any stop condition fires, tell the user:

> "这事看起来已经超出 quick 的安全范围（理由: ...）。建议改用 `/opsx:propose <原描述>` 走完整流程。"

Use **AskUserQuestion** with options `Switch to /opsx:propose` / `Continue anyway with /opsx:quick`. If user picks "continue anyway", record this choice in the eventual sediment step (so we know the user was warned).

### 2. Sketch the inline TDD task list (in conversation, NOT in OpenSpec)

In the chat, list 3-5 numbered TDD steps. Do **not** create
`openspec/changes/<name>/`. Format example:

```
Tasks (inline, TDD)
───────────────────
1. 写失败测试: tests/users/test_phone.py::test_get_phone_404_when_unset
   → run pytest -k test_get_phone_404 -x → 期望红 (端点不存在)
2. 实现最小代码: app/api/users.py 加 GET /users/{id}/phone
   → run pytest -k test_get_phone_404 -x → 期望绿
3. 写失败测试: ...test_get_phone_returns_value_when_set
   → run pytest ... → 期望红 (返回 None)
4. 实现: app/api/users.py 读取 user.phone
   → run pytest ... → 期望绿
5. ./init.sh 整体验证 + commit
```

**Quality bar for these inline tasks** (still applies):

- 每步要么是「写测试」要么是「写最少实现让测试过」
- 每步必须可执行可验证 (有具体命令 + 期望输出)
- 没有 "implement properly" / "适当处理" 这种模糊语

If you can't write the list at this granularity, the change isn't suited
for quick — go back to step 1's stop conditions.

### 3. Execute inline (no subagents)

Walk through the task list **yourself** (no Task / subagent dispatch).
Per step:

- 写代码 / 写测试 → 跑命令 → 读输出 → 给用户看输出 → 下一步
- 每写完一个测试 → 必须看到红 → 才写实现
- 每写完一个实现 → 必须看到绿 → 才下一步
- 每个 task 末尾 commit (用 conventional commit 风格)

**TDD is non-negotiable**. If you're tempted to skip "watch it fail",
delete the implementation and start over.

### 4. Final verification

```bash
./init.sh
```

读输出 → 全绿才能进入下一步。**不允许** "看起来 OK"、"应该过了"。
如果有红，回去修，不要往下走。

### 5. Sediment gate (always asks)

After verification passes, **always** ask the user (`AskUserQuestion`):

```
这次修改有什么是值得长期记住的吗？

(a) 是 — 帮我把它沉淀到对应的 spec
(b) 否 — 这是一次性修复，不需要沉淀
(c) 让我先看看 diff 再决定
```

**If (a) — sediment**:

1. 让用户简短说出「应该记什么」（一句话）
2. 找到对应位置:
   - 修改/扩展现有能力 → `openspec/specs/<capability>/spec.md`
   - 全新能力 → 新建 `openspec/specs/<new-capability>/spec.md`
   - 不属于任何能力（项目级约定）→ `docs/CONVENTIONS.md`
3. 用最小 diff 加进去（一段话或几行规则），跑 git commit
4. 报告: "Spec sedimented to `<path>`."

**If (b) — skip**: 直接结束。

**If (c) — show diff first**: 跑 `git diff HEAD~N..HEAD` 显示这次的所有
变更，再回来问 (a)/(b)。

### 6. Done

输出最终 summary:

```
## Quick change complete

意图:        <restated>
Tasks done:  N
Subagents:   0
Verification: ./init.sh → all green
Sediment:    [path | skipped | "user warned + opted to override stop conditions"]
```

---

## Guardrails

- **Never** dispatch a Task / subagent. The whole point of this command is
  to skip subagent overhead. If you find yourself wanting to dispatch one,
  the change is too big — go back to step 1 and switch to `/opsx:propose`.
- **Never** create `openspec/changes/<name>/` directories. Quick path does
  not produce proposal.md / design.md / tasks.md. The only OpenSpec
  side-effect allowed is the sediment step (step 5 option a).
- **Never** skip TDD. Watch tests fail before writing implementation.
- **Never** skip `./init.sh` verification at the end. "Should pass" is not
  a completion claim.
- **Never** silently exceed the 3-file or 1-capability stop conditions.
  Surface them and let the user decide.
- **Always** ask the sediment question (step 5). The user picked "ask by
  default" when configuring this template.
- **Always** include a commit per task, not one big commit at the end.

## When in doubt: prefer `/opsx:propose`

Quick is the exception, propose is the default. If you're unsure whether
a change qualifies, run `/opsx:propose` — the worst case is one extra
proposal draft, which is cheaper than discovering mid-implementation that
the change actually needed full design treatment.
