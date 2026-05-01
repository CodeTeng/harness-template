---
name: openspec-apply-change
description: Refine design/tasks via Superpowers (brainstorming + writing-plans) and execute with TDD subagents (subagent-driven-development). Use when the user wants to start, continue, or finish implementing an OpenSpec change.
license: MIT
compatibility: Requires openspec CLI and Superpowers skills (brainstorming, writing-plans, subagent-driven-development, test-driven-development, verification-before-completion).
metadata:
  author: harness-template
  version: "2.0"
---

This is the bridge from OpenSpec proposals to delivered code. It assumes
`/opsx:propose` already produced draft `proposal.md`, `design.md`, and
`tasks.md`, and the human has confirmed the proposal. From here it covers
steps ③ Design, ④ Build, and ⑤ Verify of the workflow.

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

### 5. Execute via subagent-driven-development

Invoke `superpowers:subagent-driven-development`.

**Standing instruction for every implementer subagent**: before writing code,
read:
1. `openspec/changes/<name>/proposal.md` — intent and non-goals
2. `openspec/changes/<name>/design.md` — architecture and rationale
3. Every relevant `openspec/specs/<capability>/spec.md` — durable contracts

This is non-negotiable. Subagents inherit no conversation history; their only
context is what you pass them and what they read. Spec files are the unified
context that keeps every subagent on the same page.

Per task, the skill will:
1. Dispatch an implementer subagent (TDD red-green-refactor).
2. Dispatch a spec-compliance reviewer subagent.
3. Dispatch a code-quality reviewer subagent.
4. Loop fixes until both reviewers approve.
5. Mark the task `- [x]` in `tasks.md`.

Continue until all tasks are done or a blocker surfaces.

### 6. Verification gate

Invoke `superpowers:verification-before-completion`.

For every completion claim, run the actual verification command (tests, build,
lint), read the output, then say "done". No "should pass" claims.

### 7. Show final status

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
Phase ④ Build: subagent-driven-development

Task 3/7: <task description>
  ▸ Implementer subagent: ✓ DONE (4/4 tests passing, committed)
  ▸ Spec reviewer: ✓ approved
  ▸ Quality reviewer: ✓ approved
  ✓ Task complete
```

## Output On Completion

```
## Build Complete

Change: <change-name>
Progress: 7/7 ✓
Verification: <test command> → all green

Run `/opsx:archive <change-name>` to close the loop.
```

## Output On Pause

```
## Build Paused

Change: <change-name>
Progress: 4/7

Blocker: <description>
  Raised by: [implementer | spec-reviewer | quality-reviewer]

Options:
1. <option 1>
2. <option 2>
```

---

## Guardrails

- Never start on `main`/`master` without explicit consent.
- Never skip a Superpowers skill this skill requires — they are the quality scaffold.
- Never have a subagent read a plan file by reference; pass full task text.
- Always route brainstorming/writing-plans output back into `openspec/changes/<name>/`.
- Always instruct subagents to read `openspec/specs/` before coding.
- Always run real verification commands before claiming done.
- If the user explicitly says "skip TDD" or "skip review", honor it but warn
  once and record the exception in `design.md` under "Process exceptions".

## Fluid Workflow Integration

This skill supports re-entry. Re-running it after a pause:
1. Reloads status from CLI.
2. Skips brainstorming/writing-plans if their work is already done.
3. Resumes `subagent-driven-development` at the next unchecked task.
