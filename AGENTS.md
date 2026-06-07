# AGENTS.md

Entry point for AI agents working on this repository.

This repo contains PR-Scout source assets that are installed into consumer repositories.

## What this repo ships

1. Agent assets in .ai/pr-scout/
2. Installer scripts in scripts/
3. User-facing docs in README.md

## Repo structure

.ai/pr-scout/
- agents/
- prompts/
- templates/
- outputs/

scripts/
- pr-scout
- pr-scout-init.sh

## Hard constraints

- Installer must be additive and idempotent
- Existing target files must never be overwritten
- Never auto-create ~/.claude.json
- Agent output must stay story-validation centered, not generic review
- Evidence must always point to concrete files and changed behavior

## Validation contract

Every run should produce:
- briefing.md
- review-comments.json (when findings have diff-locatable anchors)
- manual-todo.md only when input fetch or parsing gaps exist

## Decision tracking

If you change output contract, installer behavior, or prompt policy, append a note to decisions.md in this repo before ending the session.
