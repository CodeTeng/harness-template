---
name: openspec-apply-change
description: Refine design/tasks via Superpowers (brainstorming + writing-plans) and execute with TDD subagents (subagent-driven-development), with built-in cost-control gates. Use when the user wants to start, continue, or finish implementing an OpenSpec change.
license: MIT
compatibility: Requires openspec CLI and Superpowers skills (brainstorming, writing-plans, subagent-driven-development, test-driven-development, verification-before-completion).
metadata:
  author: harness-template
  version: "2.1"
---

This is the bridge from OpenSpec proposals to delivered code. It assumes
`/opsx:propose` already produced draft `proposal.md`, `design.md`, and
`tasks.md`, and the human has confirmed the proposal. From here it covers
steps ③ Design, ④ Build, and ⑤ Verify of the workflow.

**Cost-control gates** (added in v2.1) prevent the canonical failure mode
where review-fix loops eat unbounded budget:

- **Control ① Iteration cap** — each task's review-fix loop runs at most 2 rounds; cap-hit triggers escalation.
- **Control ② Task count gate** — `tasks.md` over 8 tasks is refused; 6–8 prompts confirmation.
- **Control ③ Atomization gate** — `tasks.md` is checked against a concrete checklist before any subagent is dispatched.

**Input**: Optionally a change name. If omitted, infer from conversation context.
If ambiguous, MUST prompt the user to choose via the AskUserQuestion tool.

---

## Steps

### 1. Select the change

Provided name → use it. Otherwise:
- Infer from conversation context.
- Auto-select if only one active change exists.
- Else `openspec list --json` + AskUserQuestion.

Announce: "Using change: `<name>`."

### 2. Load full context

```bash
openspec status --change "<name>" --json
openspec instructions apply --change "<name>" --json
```

Read every file the CLI lists. Also read every file under `openspec/specs/`
referenced by the change — those are the durable capability specs.

States:
- `blocked` → tell the user to run `/opsx:propose` first. Stop.
- `all_done` → suggest `/opsx:archive`. Stop.
- Else → continue.

### 3. Decide whether design needs deepening

Open `design.md`. Check:
- Architectural decisions explicit?
- ≥1 alternative documented and rejected with reasons?
- Data flow, error handling, testing approach all covered?
- Could a fresh engineer build from this without asking design questions?

Any "no" → invoke `superpowers:brainstorming`.

**CRITICAL OVERRIDE**: brainstorming defaults to writing its output to
`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. **Override that.** Tell
brainstorming to write its design output directly into
`openspec/changes/<name>/design.md`. OpenSpec is the single source of truth
for this template — we do not split artifacts across two locations.

After brainstorming, get the user to approve the refined `design.md`.

### 4. Decide whether tasks need atomization

Open `tasks.md`. Check:
- Every task has "Write failing test" → "Verify red" → "Implement" → "Verify green" → "Commit"?
- Every code step shows actual code?
- Every test step shows actual test code?
- Every command step shows expected output?
- Exact file paths for every Create/Modify?

Any "no" → invoke `superpowers:writing-plans`.

**CRITICAL OVERRIDE**: writing-plans defaults to writing to
`docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`. **Override that.** Tell
writing-plans to write the atomized plan directly into
`openspec/changes/<name>/tasks.md`.

Inputs for writing-plans:
- `openspec/changes/<name>/design.md` (the deepened design)
- All relevant `openspec/specs/<capability>/spec.md` files

### 5. Atomization quality gate (control ③)

> **Why this gate exists.** A weakly-atomized `tasks.md` makes reviewer
> subagents in step 7 find new issues forever — that's the #1 cause of
> review-fix loops eating budget. Catching it here prevents the loop entirely.

Re-read `tasks.md` and **verify every task** against this concrete checklist:

- [ ] Has the 5-step skeleton: `Write failing test` → `Verify red` (with expected error message) → `Write minimal code` → `Verify green` → `Commit`
- [ ] Every code step contains an **actual code block** (not "implement X" / "add Y" / "handle the case")
- [ ] Every test step contains an **actual test code block** (not "write tests for the above")
- [ ] Every command step contains an **expected output** (not just the command)
- [ ] Every `Create:` / `Modify:` line uses an **exact path** (no "in the appropriate file" / "somewhere under src/")
- [ ] No banned phrases: "TBD", "TODO", "implement later", "appropriate error handling", "similar to Task N"

**If any task fails the checklist:**

1. Re-invoke `superpowers:writing-plans` ONCE with explicit feedback listing
   which tasks failed which checks.
2. Re-run this gate.
3. If it still fails → **stop and escalate to the user** with the failing
   tasks listed. Do NOT proceed to step 6 — under-atomized tasks are the
   root cause of cost blowups.

**If all tasks pass:** announce "Atomization gate passed — N tasks." and continue.

### 6. Task count gate (control ②)

Count the tasks in `tasks.md`.

| Count | Action |
|---|---|
| **≤ 5**  | Proceed silently. |
| **6 – 8** | Warn the user: "This change has N tasks; subagent-driven-development will run ~3–6 subagent calls per task. Estimated total: 18–48 subagent calls. Continue?" Use the **AskUserQuestion tool** with options `Continue` / `Split into smaller changes`. Wait for the answer. |
| **> 8** | **Refuse to proceed.** Reply: "This change has N tasks, which is above the safe ceiling of 8. A single OpenSpec change should cover one focused capability. Suggested action: split this into multiple changes via `/opsx:propose`. If you really want to push through, the user can re-run the command with an explicit `--force` override." Then stop. |

The `--force` override is honored only if the user typed it literally. Do
not infer the override from "just do it" or similar phrases.

### 7. Execute via subagent-driven-development

Invoke `superpowers:subagent-driven-development`.

**Standing instruction for every implementer subagent**: before writing code,
read:

1. `openspec/changes/<name>/proposal.md` — intent and non-goals
2. `openspec/changes/<name>/design.md` — architecture and rationale
3. Every relevant `openspec/specs/<capability>/spec.md` — durable contracts

This is non-negotiable. Subagents inherit no conversation history; their only
context is what you pass them and what they read. Spec files are the unified
context that keeps every subagent on the same page.

**Iteration cap (control ①) — pass to the skill as a hard rule:**

> Each task's review-fix loop runs **at most 2 rounds**.
> A "round" = one implementer turn + one reviewer turn (spec or quality).
> After 2 unresolved rounds, **stop the task and escalate to the controller**.
> The controller (this skill) must then pause and ask the user:
>
> 1. **Accept current implementation** — record the disagreement under
>    "Process exceptions" / "Known compromises" in `design.md` and mark the
>    task `- [x]`.
> 2. **Update spec/design to satisfy the reviewer** — pause this task,
>    update the relevant `design.md` or `openspec/specs/<capability>/spec.md`,
>    then resume.
> 3. **Close this task and defer the residual** — mark the task `- [x]`,
>    open a follow-up note in `design.md` under "Deferred work" with a
>    one-line summary of what's left, and continue with the next task.
>
> Do NOT silently retry beyond 2 rounds. Do NOT mark the task done if no
> option above was chosen.

Per task, the skill will:

1. Dispatch an implementer subagent (TDD red-green-refactor).
2. Dispatch a spec-compliance reviewer subagent.
3. Dispatch a code-quality reviewer subagent.
4. Loop fixes — capped at 2 rounds (per control ①). Escalate on cap hit.
5. Mark the task `- [x]` in `tasks.md` only if both reviews approved or the
   user chose option 1 / 3 above.

Continue until all tasks are done or a blocker surfaces.

### 8. Verification gate

Invoke `superpowers:verification-before-completion`.

For every completion claim, run the actual verification command (tests, build,
lint), read the output, then say "done". No "should pass" claims.

### 9. Show final status

```bash
openspec status --change "<name>"
```

All done → suggest `/opsx:archive <name>`.

---

## Output During Implementation

```
## Building: <change-name>

Phase ③ Design refinement: [brainstorming | skipped]
Phase ③ Task atomization: [writing-plans | skipped]
Phase ③ Atomization gate (control ③): ✓ N tasks pass
Phase ③ Task count gate (control ②):  ✓ N ≤ 5 (or "user confirmed", or "force-overridden")
Phase ④ Build: subagent-driven-development (iteration cap = 2)

Task 3/7: <task description>
  ▸ Round 1 — Implementer: ✓ DONE (4/4 tests passing, committed)
              Spec reviewer: ✗ 2 issues (missing X, extra Y)
              Quality reviewer: skipped (spec round must pass first)
  ▸ Round 2 — Implementer: fixes applied
              Spec reviewer: ✓ approved
              Quality reviewer: ✓ approved
  ✓ Task complete (within iteration cap)
```

## Output On Completion

```
## Build Complete

Change: <change-name>
Progress: 7/7 ✓
Verification: <test command> → all green

Run `/opsx:archive <change-name>` to close the loop.
```

## Output On Pause (Iteration Cap Hit)

```
## Build Paused — iteration cap hit

Change: <change-name>
Task: 4/7 — <task description>
Progress overall: 3/7 complete

Reviewer pings remaining after 2 rounds:
  ▸ Spec reviewer:    <unresolved issues>
  ▸ Quality reviewer: <unresolved issues>

Choose one:
  1. Accept current implementation (record disagreement in design.md)
  2. Update spec/design to satisfy the reviewer (pause this task)
  3. Close this task, defer residual to a follow-up note
```

## Output On Pause (Other Blockers)

```
## Build Paused

Change: <change-name>
Progress: 4/7

Blocker: <description>
  Raised by: [implementer | spec-reviewer | quality-reviewer | atomization-gate | task-count-gate]

Options:
1. <option 1>
2. <option 2>
```

---

## Guardrails

- Never start on `main`/`master` without explicit consent.
- Never skip a Superpowers skill this skill requires — they are the quality scaffold.
- Never have a subagent read a plan file by reference; pass full task text.
- Never silently retry beyond the 2-round iteration cap (control ①).
- Never auto-bypass the atomization gate (control ③) or the task-count
  gate (control ②) — the user must consent or override explicitly.
- Always route brainstorming/writing-plans output back into `openspec/changes/<name>/`.
- Always instruct subagents to read `openspec/specs/` before coding.
- Always run real verification commands before claiming done.
- If the user explicitly says "skip TDD" or "skip review", honor it but warn
  once and record the exception in `design.md` under "Process exceptions".

## Fluid Workflow Integration

This skill supports re-entry. Re-running it after a pause:

1. Reloads status from CLI.
2. Skips brainstorming/writing-plans if their work is already done.
3. Re-runs the atomization and task-count gates (cheap; catches drift).
4. Resumes `subagent-driven-development` at the next unchecked task.
