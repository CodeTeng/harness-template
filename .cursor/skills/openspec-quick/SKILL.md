---
name: openspec-quick
description: Lightweight path for small changes — TDD inline, no subagents, no full OpenSpec cycle. Use when a change is roughly under 1 hour: bug fixes, adding fields, copy changes, small endpoints, log lines, small refactors.
license: MIT
compatibility: Requires git + the project's test runner (./init.sh).
metadata:
  author: harness-template
  version: "1.0"
---

The lightweight path. Skips the full OpenSpec + Superpowers cycle. Runs
everything inline. Keeps TDD and verification as hard floors.

**Use when** the change is < 1 hour: bug fix, add a field, small endpoint,
copy change, log line, small refactor.

**Don't use when** the change involves architectural decisions, new
capabilities, multi-file new behavior. Use `openspec-propose` instead.

**Cost profile**: 0 subagent calls, 0 OpenSpec change files, optional
sediment at the end. ~5–10× cheaper than the full cycle for small work.

---

## Steps

### 1. Confirm scope

Restate the user's intent in ≤ 5 lines:

```
意图:    <一句话>
触动文件: <最多 3 个; 多于 3 个 → 这事不小>
风险:    <一句话; 没有就写 "无明显风险">
```

**Stop conditions** (any one → switch back to propose):

- > 3 files touched
- > 1 capability touched
- description implies an architectural choice
- you'd need > 1 clarifying question

If any fires, use **AskUserQuestion**:

> "This looks beyond the safe range for quick (reason: ...). Switch to
> `/opsx:propose <original description>`?"

Options: `Switch to /opsx:propose` / `Continue anyway with /opsx:quick`.
If "continue anyway", record the override in step 5's sediment.

### 2. Sketch the inline TDD task list (in conversation, NOT in OpenSpec)

List 3–5 numbered TDD steps in the chat. Do NOT create
`openspec/changes/<name>/`.

Each step is either "write failing test" or "write minimal code to pass".
Each step has a concrete command + expected output. No vague language
("implement properly", "适当处理").

If you can't write the list at this granularity → the change isn't quick.
Go back to step 1's stop conditions.

### 3. Execute inline (no subagents)

Walk the list yourself. Per step:

- Write code or test → run command → read output → show user → next step
- Test step must show **red** before any implementation
- Implementation step must show **green** before moving on
- Commit at each task boundary (conventional commits)

**TDD is non-negotiable.** Tempted to skip "watch it fail"? Delete the
implementation, start over.

### 4. Final verification

```bash
./init.sh
```

Read the output. All green required. No "should pass" claims.

### 5. Sediment gate (always asks)

After verification, ALWAYS use **AskUserQuestion**:

> "这次修改有什么是值得长期记住的吗？"
>
> (a) 是 — 帮我把它沉淀到对应的 spec
> (b) 否 — 这是一次性修复，不需要沉淀
> (c) 让我先看看 diff 再决定

**If (a)**:

1. Ask user for a one-sentence "what to remember".
2. Find target file:
   - Updates/extends an existing capability → `openspec/specs/<capability>/spec.md`
   - Brand-new capability → new `openspec/specs/<new-capability>/spec.md`
   - Project-wide convention → `docs/CONVENTIONS.md`
3. Add the smallest possible diff (a paragraph or a few rules). Commit.
4. Report: "Spec sedimented to `<path>`."

**If (b)**: end.

**If (c)**: run `git diff HEAD~N..HEAD`, show user, then ask (a)/(b) again.

### 6. Done

Output:

```
## Quick change complete

意图:         <restated>
Tasks done:   N
Subagents:    0
Verification: ./init.sh → all green
Sediment:     [path | skipped | "user warned + opted to override stop conditions"]
```

---

## Guardrails

- Never dispatch a Task / subagent. If you want to, the change is too big.
- Never create `openspec/changes/<name>/`. The only OpenSpec side-effect
  allowed is the sediment step (5a).
- Never skip TDD red-green-refactor.
- Never skip `./init.sh` at the end.
- Never silently exceed the 3-file / 1-capability stop conditions.
- Always ask the sediment question (the user configured this template
  with "ask by default").
- Commit per task, not one big commit at the end.

## When in doubt: prefer `openspec-propose`

Quick is the exception. Propose is the default. The cost of running
propose unnecessarily (one extra draft) is much smaller than the cost of
discovering mid-implementation that quick wasn't enough.
