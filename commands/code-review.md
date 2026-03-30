---
effort: medium
---

Run a lensed code review on recent changes. Automatically detects which review lenses apply based on changed files, then dispatches a code reviewer with those lenses as additional focus areas.

## Inputs

- `$ARGUMENTS`: Optional. Accepts one or more of:
  - A git range: `HEAD~3..HEAD`, `abc123..def456`
  - A lens name to force: `security`, `performance`, `data-integrity`, `migration`
  - `all` — force all lenses regardless of file triggers
  - Empty -> reviews the most recent commit (`HEAD~1..HEAD`)

## Process

1. **Determine the diff range:**
   ```bash
   # Default: last commit
   BASE_SHA=$(git rev-parse HEAD~1)
   HEAD_SHA=$(git rev-parse HEAD)

   # Or use the provided range
   git diff --stat $BASE_SHA..$HEAD_SHA
   git diff --name-only $BASE_SHA..$HEAD_SHA
   ```

2. **Detect applicable lenses:**

   Read all `.md` files in `.claude/rules/review-lenses/` in the current project. Each lens config has a `## Triggers` section listing file path patterns.

   Match the changed files (`git diff --name-only`) against each lens's trigger patterns. A lens activates if ANY changed file matches ANY of its triggers.

   If `$ARGUMENTS` contains a lens name, force-activate that lens regardless of triggers.
   If `$ARGUMENTS` contains `all`, activate all lenses.

   If no lenses match, still run the base code review without lenses — the review is still valuable.

3. **Build the review prompt:**

   Start with the base code review template (below), then append each activated lens's review criteria as an additional section.

4. **Dispatch the code review agent:**

   Launch a subagent with `model: sonnet` using the built prompt.

   The agent receives:
   - The git diff range to review
   - The base code review checklist
   - All activated lens criteria (appended as additional focus areas)
   - The project's CLAUDE.md for general context

   The agent has access to: Read, Grep, Glob, Bash (for git commands)

5. **Present findings:**
   - Group by severity: Critical → Important → Minor
   - For each finding, include file:line reference
   - If a finding comes from a specific lens, tag it: `[security]`, `[performance]`, etc.
   - Include the merge readiness verdict

---

## Base Code Review Template

```
You are a code reviewer. Review the changes in the given git range for production readiness.

## Git Range

**Base:** {BASE_SHA}
**Head:** {HEAD_SHA}

Run these commands to see the changes:
```bash
git diff --stat {BASE_SHA}..{HEAD_SHA}
git diff {BASE_SHA}..{HEAD_SHA}
```

Read the CLAUDE.md file for project context and conventions.

## Base Review Checklist

**Code Quality:**
- Clean separation of concerns?
- Proper error handling for the context? (external APIs need it, internal calls usually don't)
- Edge cases handled?
- No unnecessary abstractions or premature generalization?

**Architecture:**
- Follows existing patterns in the codebase?
- No unintended side effects on other services?
- Database access follows the project's async patterns?

**Testing:**
- Tests cover the new behavior?
- Tests assert on structure, not on personality content (randomized messages)?
- No mocking of sync methods with AsyncMock?

**Production Readiness:**
- Health endpoint still works?
- No secrets in source code?
- Static assets have cache-busting (`?v={{ v }}`)?
- No breaking changes to APIs used by other services?

{LENS_SECTIONS}

## Output Format

### Strengths
[What's well done — be specific, cite file:line]

### Issues

#### Critical (Must Fix)
[Bugs, security issues, data loss risks, broken functionality]
{Tag each with lens if applicable: [security], [data-integrity], etc.}

#### Important (Should Fix)
[Architecture problems, missing edge cases, test gaps]

#### Minor (Nice to Have)
[Style, optimization, documentation]

**For each issue:**
- File:line reference
- What's wrong
- Why it matters
- How to fix

### Assessment

**Ready to merge?** [Yes / No / With fixes]
**Active lenses:** [{list of lenses that were applied}]
**Reasoning:** [1-2 sentences]
```

---

## Output

Present as:

```
## Code Review Results

**Range:** `{BASE_SHA}..{HEAD_SHA}` ({N} files changed)
**Lenses:** {list of activated lenses, or "base only"}

### Strengths
[what's well done]

### Critical
[must-fix issues + how to fix]

### Important
[should-fix issues + how to fix]

### Minor
[nice-to-haves]

**Verdict:** [Ready / With fixes / Not ready]
```
