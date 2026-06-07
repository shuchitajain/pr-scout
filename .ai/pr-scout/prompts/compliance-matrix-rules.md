# Story Compliance Matrix Rules

Use these statuses only:
- Implemented
- Ambiguous
- Missing

## Multiple stories

When more than one story is provided, produce a separate matrix section per story. Label each section with the story ID and title. Unscoped changes are listed once at the end, not repeated per story.

## Per story

For each acceptance criterion:
- Keep original AC text intact
- Map to evidence from changed files
- Explain why status is assigned in one sentence

Also include:
- Assumptions detected
- Unscoped changes (once, after all story matrices)

## Evidence requirements
- Point to file path and changed behavior
- Avoid broad claims without direct diff evidence

If no evidence exists for an AC:
- Mark Missing
- Do not infer from surrounding code
