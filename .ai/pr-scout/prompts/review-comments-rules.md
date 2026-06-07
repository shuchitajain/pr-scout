# Review Comments Rules

## When to generate a comment

Only generate a comment when the finding has a concrete diff-locatable anchor: a specific file path and a line that appears in the diff. If the finding cites general behavior without a changed line to point at, skip the comment and log the finding reference in manual-todo.md instead.

## Resolving diff position

Diff position is the 1-based line offset from the start of the hunk header (`@@`) in the unified diff, counting every line including context lines. It is not the absolute line number in the file. Parse each `@@ -old_start,old_lines +new_start,new_lines @@` header to compute it. Store both `line` (absolute line in the new file, for human verification) and `diff_position` (what the VCS review API requires).

## Comment body rules

- 1-3 sentences max. Cut every word that doesn't add meaning.
- No em dashes. Use commas, colons, or a new sentence.
- Banned words and phrases: "it's worth noting", "ensure that", "it is important to", "leverage", "utilize", "delve", "potentially", "could possibly", "please note"
- Don't open by restating the finding title.
- Direct and conversational — written as if a teammate left it.
- End with a concrete question or action, not a general observation.

## Output schema (per comment)

{
  "id": "<finding-id>",
  "file": "<repo-relative path>",
  "line": <absolute line in new file>,
  "diff_position": <1-based hunk offset>,
  "side": "RIGHT",
  "body": "<comment text>",
  "confidence": "high|medium|low",
  "finding_ref": "Finding N"
}

## Cap

Max 5 comments per run, matching the findings cap. Order by confidence (high first), then by user/business impact.
