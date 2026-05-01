# AGENTS.md

This project follows the **OpenSpec + Superpowers** workflow. Read this file
before doing anything else. It tells you how the two toolchains compose and
which artifact you should write where.

> **User instructions always win.** This document and the Superpowers skills
> can be overridden by anything the user asks for in conversation.

---

## The two toolchains, in one sentence each

- **OpenSpec** manages **specs and memory** — proposals, durable capability
  specs, and the archive. It is the single source of truth for *what we
  agreed to build*.
- **Superpowers** manages **design and execution** — brainstorming the
  approach, writing TDD-atomized plans, dispatching subagents to build
  task-by-task, and verifying before claiming done. It is the methodology for
  *how we build it*.

Neither tool replaces the other. They compose:

```
OpenSpec proposes & remembers ── Superpowers designs & builds ── OpenSpec archives
```

---

## The complete loop

```
┌──────────────────┐
│ ① /opsx:propose  │  Drafts proposal.md + design.md + tasks.md
│   (OpenSpec)     │  in openspec/changes/<name>/
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ② Human review   │  Confirm proposal.md captures the right intent.
│   (manual)       │  This is the only mandatory human gate before code.
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ③ Design         │  superpowers:brainstorming
│   (Superpowers)  │    → deepens design.md (architecture, alternatives)
│                  │  superpowers:writing-plans
│                  │    → atomizes tasks.md into TDD red-green-refactor steps
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ④ Build          │  superpowers:subagent-driven-development
│   (Superpowers)  │    → fresh implementer subagent per task (TDD)
│                  │    → spec-compliance reviewer subagent
│                  │    → code-quality reviewer subagent
│                  │    → loop fixes until both reviews approve
│                  │    → mark task `- [x]` in tasks.md
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ⑤ Verify         │  superpowers:verification-before-completion
│   (Superpowers)  │  Run real test/build/lint commands. Read output.
│                  │  Only then claim "done".
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ⑥ /opsx:archive  │  Move openspec/changes/<name>/ → archive/
│   (OpenSpec)     │  Sync delta specs into openspec/specs/<capability>/
│                  │  The project knowledge base grows.
└──────────────────┘
```

Steps ③ + ④ + ⑤ are all triggered by **`/opsx:apply <name>`**. That command is
the bridge between OpenSpec and Superpowers.

---

## Source-of-truth rules

There is **one and only one** place each artifact lives:

| Artifact | Lives in | Authored by | Refined by |
|---|---|---|---|
| `proposal.md` | `openspec/changes/<name>/` | `/opsx:propose` | Human review (step ②) |
| `design.md`   | `openspec/changes/<name>/` | `/opsx:propose` (draft) | `superpowers:brainstorming` (in step ③) |
| `tasks.md`    | `openspec/changes/<name>/` | `/opsx:propose` (draft) | `superpowers:writing-plans` (in step ③) |
| Capability specs | `openspec/specs/<capability>/spec.md` | `/opsx:archive` (via spec sync) | every future change |
| Archive | `openspec/changes/archive/YYYY-MM-DD-<name>/` | `/opsx:archive` | — |

> **Critical override.** Superpowers `brainstorming` and `writing-plans` skills
> default to writing their output into `docs/superpowers/specs/` and
> `docs/superpowers/plans/`. **In this template you must override that** and
> point them at `openspec/changes/<name>/design.md` and `tasks.md`. We do
> not split artifacts across two locations. OpenSpec is the only source of
> truth.

---

## How subagents get unified context

When `subagent-driven-development` dispatches a fresh implementer subagent, the
subagent has **zero** conversation history. Its only context is what you pass
it plus what it reads. To keep every subagent on the same page, the controller
(you) must instruct each subagent to read, before writing any code:

1. `openspec/changes/<name>/proposal.md` — the intent and non-goals
2. `openspec/changes/<name>/design.md` — the architecture and rationale
3. Every relevant `openspec/specs/<capability>/spec.md` — the durable contracts

This is non-negotiable. The spec layer is the unified context that keeps
subagents coherent. If `openspec/specs/` is empty (early-project case), the
proposal + design are sufficient on their own.

---

## Non-negotiables

- **TDD by default.** Every task in `tasks.md` is red → green → refactor → commit. No production code without a failing test first.
- **Verification before claims.** Never say "done", "passing", "fixed" without having just run the verification command and read the output.
- **No placeholders in plans.** No "TBD", "implement later", "add error handling", "similar to Task N". Every code step shows the actual code.
- **One subagent per task.** Never dispatch parallel implementers (they'll conflict). One implementer + two reviewers per task.
- **Never start on `main`/`master`** without explicit user consent. Use a feature branch or a worktree.
- **Brainstorming/writing-plans output goes back into OpenSpec.** Override their default paths.

---

## Entry points (Cursor commands)

| Command | When to use |
|---|---|
| `/opsx:propose [<name-or-description>]` | Start a new change. Drafts proposal/design/tasks. |
| `/opsx:explore [<topic>]` | Think out loud before committing to a change. Read-only thinking partner; never writes code. |
| `/opsx:apply [<name>]` | Refine design + tasks via Superpowers, then build with TDD subagents. The big one. |
| `/opsx:archive [<name>]` | After everything is verified done — close the loop and sync specs. |

---

## Skills you should know about

These are auto-discovered by Cursor; you can also invoke them via the Skill tool.

**OpenSpec workflow skills** (this template):
- `openspec-propose` — used by `/opsx:propose`
- `openspec-apply-change` — used by `/opsx:apply` (orchestrates Superpowers)
- `openspec-archive-change` — used by `/opsx:archive`
- `openspec-explore` — used by `/opsx:explore`

**Superpowers methodology skills** (installed via Cursor plugin):
- `superpowers:brainstorming` — design phase
- `superpowers:writing-plans` — atomize into TDD steps
- `superpowers:subagent-driven-development` — build phase
- `superpowers:test-driven-development` — TDD discipline (followed by every implementer subagent)
- `superpowers:verification-before-completion` — verification gate
- `superpowers:using-git-worktrees` — isolate feature work
- `superpowers:finishing-a-development-branch` — wrap up the branch

---

## When the user just says "build me X"

Don't skip ahead. Even if X seems trivial:

1. Run `/opsx:propose` first. Drafts capture intent and stop you from making
   wrong assumptions.
2. Get the human to confirm the proposal (step ②).
3. Run `/opsx:apply` to do the design + build.
4. Run `/opsx:archive` to sync specs.

The "this is too simple to need a process" feeling is exactly when unexamined
assumptions waste the most work.

---

## When you genuinely don't know what to do

Use `/opsx:explore`. It is a read-only thinking-partner mode. You can read
code, draw diagrams, compare approaches — you cannot write code. When the
shape of the problem becomes clear, exit explore mode and run `/opsx:propose`.
