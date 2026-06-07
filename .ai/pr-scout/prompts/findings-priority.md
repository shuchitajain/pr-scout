# Code-Aware Findings Priority

Evaluate in this order:
1. Explicit guidance violations from repo instructions
2. Shared abstraction risks
3. Error and edge-case handling gaps
4. Integration consistency gaps
5. Story-safety conflicts

Output policy:
- Show high-signal findings only
- Default cap: 5 findings
- Prioritize by user/business impact

Each finding must include:
- Why it matters
- Evidence
- Reviewer question or action
- Confidence (high, medium, low)

Out of scope:
- Style nits
- Formatting
- Generic quality scoring
