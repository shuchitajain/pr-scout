<div align="center">

<img src="banner.png" width="100%" />

# pr-scout
> An AI agent that checks whether a pull request actually does what the story says it should.

<p>
  <a href="#what-you-get">What You Get</a> •
  <a href="#setup">Setup</a> •
  <a href="#usage">Usage</a> •
  <a href="#what-it-wont-do">What It Won't Do</a>
</p>

<p>
  <a href="https://www.linkedin.com/in/shuchita-jain/"><img src="https://img.shields.io/badge/Follow%20on-LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" /></a>&nbsp;
  <a href="https://medium.com/@coderSJ"><img src="https://img.shields.io/badge/Follow%20on-Medium-12100E?style=for-the-badge" /></a>
</p>

</div>

---

Point it at a PR and a story ID. It reads the diff, fetches your acceptance criteria, and tells you what's implemented, what's missing, and what smells off. Every claim comes with file-level evidence. No lint noise, no style opinions, no generic scorecards.

---

## What you get

**A briefing, not a wall of comments.**

Every run produces a `briefing.md` with four sections:

- **Story Verdict**: pass, partial, or blocked, per story
- **PR Narrative**: a plain-English walkthrough of what the change actually does
- **Compliance Matrix**: each acceptance criterion mapped to its evidence in the diff
- **Findings**: up to 5 concrete risks, each with a file reference and a reviewer question

**Inline review comments, ready to post.**

After the briefing, pr-scout writes a `review-comments.json` and proposes the list in chat. You review them, drop or edit any you don't want, and confirm. It posts the approved set directly to the PR via your VCS (GitHub, GitLab, Bitbucket, Azure DevOps). Nothing gets posted without your sign-off.

---

## Setup

Run this once from your repo root:

```bash
git clone https://github.com/shuchitajain/pr-scout.git ./pr-scout
./pr-scout/scripts/pr-scout init .
```

That's it. Init is additive and won't touch files that already exist.

---

## Usage

In your AI chat:

```text
# Check uncommitted working tree changes against a story
/pr-scout self-check for story PROJ-123

# Check all commits on your current branch not yet in main (plus any uncommitted changes)
/pr-scout self-check against main for story PROJ-123

# Same, against a different base
/pr-scout self-check against origin/qa for story PROJ-123

# Check a specific commit against a remote branch
/pr-scout self-check commit a3f9c2b against origin/main for story PROJ-123

# Self-check against multiple stories
/pr-scout self-check against main for story PROJ-123 PROJ-456

# Review an open PR
/pr-scout review pr 314 for story PROJ-123

# Review a PR against multiple stories
/pr-scout review pr 314 for story PROJ-123 PROJ-456

# Include a plan file for triangle checks
/pr-scout review pr 314 for story PROJ-123 include-plan
```

After the briefing, pr-scout presents the proposed inline comments and waits. Drop some, edit others, or approve as-is. When you're ready, tell it to post and it will push the approved set to the PR via your VCS.

Story IDs are fetched directly from your tracker (Jira, etc.). PR-Scout looks for acceptance criteria in a dedicated AC field first, then in description sections headed `Acceptance Criteria` or `AC`, then in checklist-like issue content when clearly used that way. If story text is fetched but no reliable AC block is found, it reports `AC missing from fetched payload` and asks you for pasted AC or the correct field name/key. If a story isn't in a connected tracker, paste the text and acceptance criteria instead.

---

## What it won't do

pr-scout is deliberately narrow. It does not:

- Check lint, formatting, or style
- Score code quality in the abstract
- Generate tests
- Review code unrelated to the story

If a finding isn't grounded in a specific file and a story risk, it doesn't appear.

---

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Owner

Shuchita Jain
