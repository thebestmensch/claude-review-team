# Review Ensemble

Review agents for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that automatically evaluate your work from multiple angles — visual quality, accessibility, copy tone, code correctness, and design soundness.

Different agents use different strategies: visual and tone reviewers operate behind an **information firewall** (screenshots and rendered text only, no source code), while code reviewers and advisory agents get full codebase access. The right isolation level depends on what's being reviewed.

## What's Included

### Review Skills (`/slash-commands`)

| Command | Evaluates | Input |
|---------|-----------|-------|
| `/visual-qa` | Broken rendering, anti-patterns, pixel issues | URL or screenshot |
| `/visual-qa polish` | Design quality — hierarchy, spacing, harmony | URL or screenshot |
| `/accessibility-qa` | WCAG 2.1 AA — semantics, ARIA, keyboard, contrast | URL or screenshot |
| `/tone-qa` | Copy voice — does text match your app's personality? | URL or screenshot |
| `/code-review` | Code quality with auto-detected domain lenses | Git range |
| `/setup-ensemble` | Generates project config files via interview | (interactive) |

### Advisory Agents (auto-dispatched during design)

| Agent | Fires during | Purpose |
|-------|-------------|---------|
| Devil's Advocate | Brainstorming, planning | Challenges overengineering, missed solutions, YAGNI |
| Research Agent | Brainstorming | Investigates existing tools and packages |
| Security Reviewer | Standalone or as lens | Auth bypasses, secrets, injection, OWASP top 10 |

### Dispatch Rules (automatic orchestration)

| Rule | Triggers |
|------|----------|
| Visual QA during UI work | After meaningful visual changes |
| Code review dispatch | After feature completion, before merge |
| Advisory agents | During brainstorming and planning |

## How It Works

```
┌─────────────┐    screenshots    ┌──────────────┐
│             │ ────────────────→ │  Visual QA   │  no code, no CSS
│             │    git diff       ├──────────────┤
│  Your Code  │ ────────────────→ │  Code Review │  no UI, has lenses
│             │    DOM snapshot   ├──────────────┤
│             │ ────────────────→ │  A11y QA     │  no CSS, has ARIA tree
│             │    rendered text  ├──────────────┤
│             │ ────────────────→ │  Tone QA     │  no code, has voice guide
└─────────────┘                   └──────────────┘
```

The information firewall is the core design principle. An agent that can see `width: 80%` in CSS will rationalize why a dropdown is that wide. An agent that can only see the screenshot will report that it's disproportionate.

## Install

```bash
git clone <this-repo>
cd review-ensemble
chmod +x install.sh
./install.sh
```

Copies skills, dispatch rules, and agents to `~/.claude/`. Use `--force` to overwrite existing files.

**No frontend work?** Skip the visual, accessibility, and tone QA agents:

```bash
./install.sh --no-frontend
```

You still get lensed code review, devil's advocate, research agent, security reviewer, and all dispatch rules for code-level work.

### Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- [Playwright plugin](https://github.com/anthropics/claude-code-plugins) (for visual/accessibility/tone QA — not needed with `--no-frontend`)

## Project Setup

After installing, each project needs config files that tell the agents what your project looks like, sounds like, and cares about.

### Option A: Interactive (recommended)

```
/setup-ensemble
```

Interviews you about your project, then generates the config files.

### Option B: Manual

```bash
mkdir -p .claude/rules/review-lenses
cp /path/to/review-ensemble/templates/visual-qa-philosophy.md .claude/rules/
cp /path/to/review-ensemble/templates/voice-guide.md .claude/rules/
cp /path/to/review-ensemble/templates/review-lenses/example.md .claude/rules/review-lenses/my-lens.md
```

Edit each file following the guided prompts inside.

### Project Config Files

| File | Purpose | Used by |
|------|---------|---------|
| `.claude/rules/visual-qa-philosophy.md` | Design taste — what good/bad looks like | `/visual-qa`, `/visual-qa polish` |
| `.claude/rules/voice-guide.md` | Copy voice — how the app should sound | `/tone-qa` |
| `.claude/rules/review-lenses/*.md` | Domain review criteria with file triggers | `/code-review` |

Commit these to your repo so the whole team shares the same review standards.

## Writing Review Lenses

Lenses give the code reviewer domain-specific eyes. Each lens has **triggers** (file patterns that activate it) and **criteria** (what to check).

```markdown
# Security Lens

## Triggers
- `**/auth*` — authentication code
- `**/.env*` — secrets files

## Review Criteria

### Auth
- Every non-health endpoint uses auth middleware
- No hardcoded tokens in source

### Injection
- All SQL uses parameterized queries
- No user input in shell commands
```

The `/code-review` skill auto-detects which lenses apply based on changed files. Force specific lenses with `/code-review security performance`.

See `templates/review-lenses/example.md` for a full template with starter ideas.

## Architecture

```
~/.claude/
├── commands/           ← skills (slash commands)
│   ├── visual-qa.md
│   ├── accessibility-qa.md
│   ├── tone-qa.md
│   ├── code-review.md
│   └── setup-ensemble.md
├── rules/              ← dispatch rules (auto-load every conversation)
│   ├── visual-qa-during-ui-work.md
│   ├── code-review-dispatch.md
│   └── advisory-agents.md
└── agents/             ← subagent definitions
    ├── devils-advocate.md
    ├── security-reviewer.md
    └── research-agent.md

your-project/
└── .claude/rules/      ← project-specific config
    ├── visual-qa-philosophy.md
    ├── voice-guide.md
    └── review-lenses/
        ├── security.md
        ├── performance.md
        └── ...
```

## License

MIT
