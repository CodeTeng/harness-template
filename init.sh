#!/usr/bin/env bash
#
# init.sh — single entry point for project bootstrap + verification.
#
# Run this:
#   • before starting any work (confirms baseline is healthy)
#   • before claiming a task is "done" (confirms you didn't break baseline)
#
# CUSTOMIZE the "Project verification" section below for your stack.
# Until then, this script only verifies the harness itself is wired up.

set -e

cd "$(dirname "$0")"

echo "=== Harness Initialization ==="

# ─── Sanity: are we in the project root? ────────────────────────────────────
if [ ! -f "openspec/config.yaml" ]; then
  echo "✗ openspec/config.yaml not found — not in project root?" >&2
  exit 1
fi
echo "✓ project root confirmed"

# ─── OpenSpec CLI reachable? ────────────────────────────────────────────────
if ! command -v openspec >/dev/null 2>&1; then
  echo "✗ openspec CLI not installed. See README.md prerequisites." >&2
  exit 1
fi
echo "✓ openspec $(openspec --version)"

# ─── Show active changes (so the agent knows what's in flight) ──────────────
echo
echo "=== Active OpenSpec changes ==="
openspec list || true

# ─── Project verification ───────────────────────────────────────────────────
# TODO(project owner): uncomment the block matching your stack and adapt.
#
# Node / TypeScript:
#   echo; echo "=== Install + typecheck + test ==="
#   npm install
#   npm run typecheck
#   npm test
#
# Python (uv):
#   echo; echo "=== Sync + typecheck + test ==="
#   uv sync
#   uv run mypy .
#   uv run pytest
#
# Python (poetry):
#   echo; echo "=== Install + typecheck + test ==="
#   poetry install
#   poetry run mypy .
#   poetry run pytest
#
# Rust:
#   echo; echo "=== Build + test ==="
#   cargo build
#   cargo test
#
# Go:
#   echo; echo "=== Build + test ==="
#   go build ./...
#   go test ./...
#
# After customizing, delete this TODO block.
# ─────────────────────────────────────────────────────────────────────────────

echo
echo "=== Verification complete ==="
echo
echo "Next steps:"
echo "  1. openspec list              — see active changes"
echo "  2. /opsx:propose <description> — start a new change"
echo "  3. /opsx:apply <name>          — refine + build via Superpowers"
