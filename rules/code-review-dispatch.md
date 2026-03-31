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

Alongside the lensed code review, specialized agents auto-dispatch when their trigger patterns match the diff. They run in background, in parallel with the lensed review.

| Agent | Fires when diff contains | Audits |
|-------|--------------------------|--------|
| `silent-failure-hunter` | `try`, `except`, `catch`, `raise`, `throw`, `.catch(`, `Promise`, `fallback`, `retry` | Swallowed exceptions, empty catches, broad catching, masked errors |
| `type-design-analyzer` | New `class` defs, `BaseModel`, `@dataclass`, TS `interface`/`type`, Django models, `CREATE TABLE` | Encapsulation, invariant expression/enforcement |
| `concurrency-auditor` | `async with`, `await`, `get_db`, `Lock`, `transaction`, `BEGIN`, `gather`, `create_task`, sync endpoints | Held connections, write contention, race conditions, locking hazards |
| `api-contract-reviewer` | Route/endpoint handler changes **AND** a frontend/mobile directory exists in the repo | Response shape drift, renamed fields, broken consumer assumptions |
| `test-gap-analyzer` | Test files in the diff, **OR** new functions/endpoints without corresponding test files | Untested error paths, missing edge cases, brittle assertions |

### Dispatch Pattern

Pass the same git diff range that the lensed review uses. The prompt must scope each agent to only the changed code:

```python
# Fire alongside the lensed review, not instead of it
# Prompt must include: "Review only the changes in git diff {BASE_SHA}..{HEAD_SHA}"
Agent(subagent_type="silent-failure-hunter", model="sonnet", run_in_background=true,
      prompt="Review error handling in the changes from git diff {BASE_SHA}..{HEAD_SHA}. ...")
Agent(subagent_type="concurrency-auditor", model="sonnet", run_in_background=true,
      prompt="Audit concurrency patterns in the changes from git diff {BASE_SHA}..{HEAD_SHA}. ...")
# ... etc for each triggered agent
```

Announce all dispatches in one line: "Dispatching lensed code review (security, performance) + silent failure hunter + concurrency auditor."

**When none trigger:** Only the lensed review runs, as before. The supplementary agents add depth — they don't replace the base review.

**Limit parallel agents:** Dispatch at most 3 supplementary agents per review. If more than 3 trigger, prioritize by relevance to the change — skip agents whose triggers match only incidentally (e.g., a trivial `try/except` in a test file shouldn't fire the silent failure hunter).

## How to Use Results

When the code review returns:

- **Critical issues** -> fix immediately before proceeding
- **Important issues** -> fix before committing/merging
- **Minor issues** -> note for the user, fix if trivial
- **Lens-tagged findings** (e.g., `[security]`, `[data-integrity]`) -> these came from domain-specific checks and are often the highest-value findings

When supplementary agents return:

- **Silent failure findings** -> treat CRITICAL and HIGH the same as lensed review critical/important issues
- **Type design ratings** -> present ratings and concerns to the user; fix enforcement gaps if straightforward
- **Concurrency issues** -> CRITICAL (deadlock/corruption) fix immediately; HIGH (intermittent) fix before merge
- **API contract issues** -> CRITICAL (will crash/404) fix immediately; note safe additive changes
- **Test gap findings** -> add tests for critical gaps; note important gaps for the user

If any reviewer flags something you disagree with, push back with technical reasoning — don't blindly implement.

## Relationship to Other Review Systems

This rule covers **code-level** review. It complements but does not replace:
- `visual-qa-during-ui-work.md` — visual/accessibility/tone review (operates on rendered output, not code)
- `advisory-agents.md` — design-phase review (operates on plans and proposals, not implementations)
