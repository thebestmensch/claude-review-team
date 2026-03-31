# Code Review Dispatch

When implementation work is completed, automatically dispatch a lensed code review at the following points.

**Always announce dispatches.** Before spinning up the code review, tell the user which lenses are activating and why. Keep it to one line.

## When to Dispatch

### Mandatory
- After completing a feature or bug fix (before commit)
- Before merge to main
- After each task in subagent-driven development

### Optional but Valuable
- After fixing a complex bug (did the fix introduce new issues?)
- After refactoring (did it break the contract?)
- When stuck (fresh perspective on the code)

## How to Dispatch

Use the `/code-review` skill, which handles lens detection automatically:

```
Skill("code-review")
```

Or force specific lenses:
```
Skill("code-review", args="security performance")
```

The skill will:
1. Get the git diff for the range
2. Match changed files against lens trigger patterns in `.claude/rules/review-lenses/`
3. Append matching lens criteria to the base review prompt
4. Dispatch a sonnet subagent in background

## Lens Activation Logic

Lenses activate based on changed file paths. Each lens config in `.claude/rules/review-lenses/` defines its own trigger patterns. Multiple lenses can fire simultaneously.

**When no lenses match:** The base code review still runs — it covers general code quality, architecture, and testing. Lenses add domain-specific depth, they don't replace the base review.

**When multiple lenses match:** All matching lenses are included. This is fine — the lenses cover different concerns.

## Supplementary Agents

Alongside the lensed code review, two specialized agents auto-dispatch when their trigger patterns match the diff. They run in background, in parallel with the lensed review.

### Silent Failure Hunter

**Fires when the diff contains:** `try`, `except`, `catch`, `raise`, `throw`, `.catch(`, `Promise`, `fallback`, or `retry` patterns.

Dispatches `silent-failure-hunter` agent in background. It audits error handling for swallowed exceptions, empty catch blocks, broad exception catching, and fallbacks that mask real problems.

### Type Design Analyzer

**Fires when the diff contains:** new `class` definitions, Pydantic `BaseModel` subclasses, `@dataclass`, TypeScript `interface`/`type` declarations, Django model definitions, or `CREATE TABLE` statements.

Dispatches `type-design-analyzer` agent in background. It rates new types on encapsulation, invariant expression, usefulness, and enforcement.

### Dispatch Pattern

```python
# Both fire alongside the lensed review, not instead of it
Agent(subagent_type="silent-failure-hunter", model="sonnet", run_in_background=true)
Agent(subagent_type="type-design-analyzer", model="sonnet", run_in_background=true)
```

Announce all dispatches in one line: "Dispatching lensed code review (security, performance) + silent failure hunter + type design analyzer."

**When neither triggers:** Only the lensed review runs, as before. The supplementary agents add depth — they don't replace the base review.

## How to Use Results

When the code review returns:

- **Critical issues** -> fix immediately before proceeding
- **Important issues** -> fix before committing/merging
- **Minor issues** -> note for the user, fix if trivial
- **Lens-tagged findings** (e.g., `[security]`, `[data-integrity]`) -> these came from domain-specific checks and are often the highest-value findings

When supplementary agents return:

- **Silent failure findings** -> treat CRITICAL and HIGH the same as lensed review critical/important issues
- **Type design ratings** -> present ratings and concerns to the user; fix enforcement gaps if straightforward

If any reviewer flags something you disagree with, push back with technical reasoning — don't blindly implement.

## Relationship to Other Review Systems

This rule covers **code-level** review. It complements but does not replace:
- `visual-qa-during-ui-work.md` — visual/accessibility/tone review (operates on rendered output, not code)
- `advisory-agents.md` — design-phase review (operates on plans and proposals, not implementations)
