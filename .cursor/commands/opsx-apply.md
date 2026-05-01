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

### 5. Execute via subagent-driven-development

**Invoke the Superpowers `subagent-driven-development` skill.**

Provide it with:
- The atomized `tasks.md`.
- A standing instruction that **every implementer subagent** must, before
  writing code, read:
  - `openspec/changes/<name>/proposal.md` (intent)
  - `openspec/changes/<name>/design.md` (architecture)
  - Every relevant `openspec/specs/<capability>/spec.md` (durable contracts)

That way each fresh subagent inherits unified context from the spec layer
without inheriting your conversation pollution.

The skill will, per task:
1. Dispatch an implementer subagent (TDD red-green-refactor).
2. Dispatch a spec-compliance reviewer subagent.
3. Dispatch a code-quality reviewer subagent.
4. Loop fixes until both reviews pass.
5. Mark task done in `tasks.md`.

Continue until all tasks are checked off OR a blocker is hit.

### 6. Verification gate

Before claiming completion, **invoke the Superpowers `verification-before-completion` skill.**

For each completion claim, run the actual verification command (test suite,
build, lint), read the output, and only then say "done".

### 7. Show final status

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
Phase ④ Build: subagent-driven-development

Task 3/7: <task description>
  ▸ Implementer subagent: ✓ DONE (4/4 tests passing, committed)
  ▸ Spec reviewer: ✓ approved
  ▸ Quality reviewer: ✓ approved
  ✓ Task complete

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

## Output On Pause

```
## Build Paused

Change: <change-name>
Progress: 4/7 tasks complete

Blocker: <description>
  ▸ This was raised by: [implementer | spec-reviewer | quality-reviewer]

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
3. Resume `subagent-driven-development` at the next unchecked task.
