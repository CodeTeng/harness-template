---
name: /opsx-apply
id: opsx-apply
category: Workflow
description: Refine design/tasks via Superpowers and execute with TDD subagents (steps ③④⑤ of the workflow)
---

Apply (refine + build) an OpenSpec change using the Superpowers methodology.

This command is the **bridge from OpenSpec proposals to delivered code**. It assumes
`/opsx:propose` already produced draft `proposal.md`, `design.md`, and `tasks.md`,
and the human has confirmed the proposal in step ②. From here it:

- ③ **Designs** — uses Superpowers `brainstorming` to deepen `design.md`,
  then `writing-plans` to atomize `tasks.md` into TDD-ready steps.
- ④ **Builds** — uses Superpowers `subagent-driven-development` to execute
  each task with one fresh subagent per task, following TDD red-green-refactor.
- ⑤ **Verifies** — uses Superpowers `verification-before-completion` before
  declaring done.

**Input**: Optionally specify a change name (e.g., `/opsx:apply add-auth`). If omitted,
infer from conversation context. If ambiguous, MUST prompt the user to choose.

---

## Steps

### 1. Select the change

If a name was provided, use it. Otherwise:
- Infer from conversation context if the user mentioned a change.
- Auto-select if only one active change exists.
- If ambiguous, run `openspec list --json` and use the **AskUserQuestion tool** to let the user pick.

Announce: "Using change: `<name>`. Override with `/opsx:apply <other>`."

### 2. Load the full context

Run:
```bash
openspec status --change "<name>" --json
openspec instructions apply --change "<name>" --json
```

Then **Read** every file the CLI lists (proposal, design, tasks, any delta specs).
Also read every file under `openspec/specs/` that is referenced by the change —
those are the durable capability specs that constrain implementation.

Handle states:
- `state: "blocked"` → missing artifacts. Stop and tell the user to run `/opsx:propose` first.
- `state: "all_done"` → congratulate, suggest `/opsx:archive`. Stop.
- Otherwise → continue.

### 3. Decide whether design needs deepening

Open `design.md`. Ask yourself:
- Are the architectural decisions explicit?
- Are at least one or two alternatives documented and rejected with reasons?
- Are data flow, error handling, and testing approach all covered?
- Could a fresh engineer build this without asking design questions?

If **any** answer is "no" → **invoke the Superpowers `brainstorming` skill**.

> Use the Skill tool with `superpowers:brainstorming` (or read its SKILL.md if Skill tool unavailable).
> Tell brainstorming the design output should be written **directly to**
> `openspec/changes/<name>/design.md`, NOT to `docs/superpowers/specs/`.
> Override the default spec location — OpenSpec is the single source of truth for this template.

After brainstorming, the user must approve the refined `design.md` before proceeding.

If design is already solid, skip this step and announce: "Design is solid, skipping brainstorming."

### 4. Decide whether tasks need atomization

Open `tasks.md`. Ask yourself:
- Does every task have explicit "Write failing test" → "Verify red" → "Implement" → "Verify green" → "Commit" steps?
- Does every code step show the actual code (not "implement X")?
- Does every test step show the actual test code?
- Does every command step show expected output?
- Are exact file paths given for every Create/Modify?

If **any** answer is "no" → **invoke the Superpowers `writing-plans` skill**.

> Use the Skill tool with `superpowers:writing-plans`.
> Tell writing-plans the plan output should be written **directly to**
> `openspec/changes/<name>/tasks.md`, NOT to `docs/superpowers/plans/`.
> The input spec is `openspec/changes/<name>/design.md` plus the relevant
> capability specs under `openspec/specs/`.

If tasks are already atomized, skip this step and announce: "Tasks are atomized, skipping writing-plans."

### 5. Atomization quality gate (control ③)

> **Why this gate exists.** A weakly-atomized `tasks.md` makes reviewer
> subagents in step 7 find new issues forever — that's the #1 cause of
> review-fix loops eating budget. Catching it here prevents the loop entirely.

Re-read `tasks.md` and **verify every task** against this concrete checklist:

- [ ] Has the 5-step skeleton: `Write failing test` → `Verify red` (with expected error message) → `Write minimal code` → `Verify green` → `Commit`
- [ ] Every code step contains an **actual code block** (not "implement X" / "add Y / "handle the case")
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
| **> 8** | **Refuse to proceed.** Reply: "This change has N tasks, which is above the safe ceiling of 8. A single OpenSpec change should cover one focused capability. Suggested action: split this into multiple changes via `/opsx:propose`. If you really want to push through, re-run `/opsx:apply <name> --force` (you'll need to override this gate explicitly)." Then stop. |

The `--force` override is honored only if the user typed it literally. Do
not infer the override from "just do it" or similar phrases.

### 7. Execute via subagent-driven-development

**Invoke the Superpowers `subagent-driven-development` skill.**

Provide it with:

- The atomized `tasks.md`.
- A **standing instruction for every implementer subagent**: before writing
  code, read
  - `openspec/changes/<name>/proposal.md` (intent),
  - `openspec/changes/<name>/design.md` (architecture),
  - every relevant `openspec/specs/<capability>/spec.md` (durable contracts).
- **Iteration cap (control ①)** — pass this to the skill as a hard rule:

  > Each task's review-fix loop runs **at most 2 rounds**.
  > A "round" = one implementer turn + one reviewer turn (spec or quality).
  > After 2 unresolved rounds, **stop the task and escalate to the controller**.
  > The controller (you, this command) must then pause and ask the user:
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

That way each fresh subagent inherits unified context from the spec layer
without inheriting your conversation pollution, and no single task can
silently consume an unbounded budget.

The skill will, per task:

1. Dispatch an implementer subagent (TDD red-green-refactor).
2. Dispatch a spec-compliance reviewer subagent.
3. Dispatch a code-quality reviewer subagent.
4. Loop fixes — capped at 2 rounds (per control ①). Escalate on cap hit.
5. Mark task done in `tasks.md` only if both reviews approved or the user
   chose option 1 / 3 above.

Continue until all tasks are checked off OR a blocker is hit.

### 8. Verification gate

Before claiming completion, **invoke the Superpowers `verification-before-completion` skill.**

For each completion claim, run the actual verification command (test suite,
build, lint), read the output, and only then say "done".

### 9. Show final status

```bash
openspec status --change "<name>"
```

If all tasks are checked, suggest the user run `/opsx:archive <name>` to close the loop
and sync `openspec/specs/`.

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

Task 4/7: <task description>
  ...
```

## Output On Completion

```
## Build Complete

Change: <change-name>
Progress: 7/7 tasks complete ✓
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

What would you like to do?
```

## Output On Pause (Other Blockers)

```
## Build Paused

Change: <change-name>
Progress: 4/7 tasks complete

Blocker: <description>
  ▸ Raised by: [implementer | spec-reviewer | quality-reviewer | atomization-gate | task-count-gate]

Options:
1. <option 1>
2. <option 2>

What would you like to do?
```

---

## Guardrails

- **Never** start implementation on `main`/`master` without explicit consent.
- **Never** skip a Superpowers skill that this command requires — they are
  the quality scaffold.
- **Never** make a subagent read a plan file by reference; pass the full task text.
- **Never** silently retry beyond the 2-round iteration cap (control ①).
- **Never** auto-bypass the atomization gate (control ③) or the task-count
  gate (control ②) — the user must consent or override explicitly.
- **Always** route brainstorming/writing-plans output back into the OpenSpec
  change folder (override their default `docs/superpowers/...` paths).
- **Always** instruct subagents to read `openspec/specs/` before coding.
- **Always** run real verification commands before claiming done.
- If the user explicitly says "skip TDD" or "skip review", honor it but
  warn once and record the decision in `design.md` under "Process exceptions".

## Fluid Workflow Integration

This command supports re-entry. Run it again after a pause and it will:

1. Reload status from CLI.
2. Skip brainstorming/writing-plans if their work is already done.
3. Re-run the atomization and task-count gates (cheap; catches drift).
4. Resume `subagent-driven-development` at the next unchecked task.
