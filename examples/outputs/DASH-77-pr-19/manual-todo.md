# Manual To-Do — DASH-77 / PR #19

Items that could not be anchored to a diff line or require manual follow-up before the review is complete.

---

## Unanchored Findings

- [ ] **Finding 3** — Large export memory risk. No diff-locatable anchor (no existing pagination code to comment against). Raise with the author: confirm whether a row count ceiling exists for `getEvents()` or whether chunking is needed before merge.

---

## Story Gaps

- [ ] AC 3 (column selection) is entirely absent from this diff. Confirm with PM whether column selection is deferred to a follow-up story or is a blocking gap for this PR.
- [ ] AC 5 (date range scoping) is absent. Confirm whether this PR should be blocked or whether a follow-up ticket will be raised.
