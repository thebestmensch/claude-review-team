# [Lens Name] Lens

## Triggers

Activate when changes touch:
<!-- List file path patterns (glob-style) that should trigger this lens.
     The code review skill matches `git diff --name-only` against these. -->
- `**/auth*.py`, `**/middleware*` — authentication code
- `**/.env*` — environment/secrets files
- `**/api/**` — API endpoint handlers

## Review Criteria

<!-- Group criteria by topic. Each item should be specific and checkable —
     "verify X" not "consider Y". Include the WHY so the reviewer can
     judge edge cases.

     Good lens criteria:
     - Reference project-specific patterns ("we use parameterized queries with...")
     - Mention past incidents ("this caused X before, check for...")
     - Are concrete ("flag any f-string SQL" not "check for injection")

     Bad lens criteria:
     - Too vague ("make sure it's secure")
     - Too broad (trying to cover everything — keep lenses focused)
     - Duplicate base review (the base checklist already covers general quality)

     Aim for 15-40 lines of criteria per lens. -->

### [Topic 1]
- [Specific thing to check — and why it matters]
- [Another specific thing to check]

### [Topic 2]
- ...

<!--
STARTER LENS IDEAS:

Security:       Auth bypasses, secrets exposure, injection, SSRF
Performance:    N+1 queries, missing indexes, unbounded loops, payload sizes
Data Integrity: Transaction boundaries, constraint violations, migration safety
API Compat:     Breaking changes, missing versioning, undocumented parameters
Migration:      Schema changes, deploy ordering, rollback safety
Concurrency:    Race conditions, lock ordering, deadlock potential
-->
