# Contributing

Thanks for your interest in contributing to pr-scout.

## What to work on

Check the open issues. Anything labeled `good first issue` is a good starting point.

If you want to propose something new, open an issue first before writing code. It avoids wasted effort if the direction doesn't fit.

## Setup

```bash
git clone https://github.com/shuchitajain/pr-scout.git
cd pr-scout
```

No build step required. pr-scout is plain bash and markdown.

## What's in scope

- Improvements to the agent prompt in `.ai/pr-scout/agents/pr-scout.md`
- New or improved prompt rules under `.ai/pr-scout/prompts/`
- Fixes or improvements to `scripts/pr-scout-init.sh`
- New IDE wrapper templates under `.ai/pr-scout/templates/`
- Additional VCS or tracker support

## What's out of scope

- Adding a CLI or Python layer (the host IDE's LLM handles reasoning)
- Breaking changes to existing init behavior without a migration path
- Lint, style, or formatting opinions added to the agent

## Pull requests

- Keep PRs focused. One thing per PR.
- Update `examples/` if your change affects agent output format.
- Test `scripts/pr-scout init` against a real repo before opening a PR.

## Questions

Open an issue or reach out on [LinkedIn](https://www.linkedin.com/in/shuchita-jain/).
