# Visual QA During UI Work

When you are implementing UI changes (CSS, HTML templates, JSX/TSX components, React Native styles), run a visual QA review at natural checkpoints — not after every edit, but after each meaningful visual change is believed complete.

## Agents

| | Bug QA | Polish QA | Accessibility QA | Tone QA |
|---|---|---|---|---|
| **Question** | "Is this broken?" | "Is this good?" | "Can everyone use this?" | "Does this sound like us?" |
| **Evaluates** | Anti-patterns + design rules | Design Polish Checklist | WCAG 2.1 AA + ARIA | Project voice guide |
| **Judgment** | Objective | Subjective — design taste | Objective — standards | Subjective — voice match |
| **Model** | `sonnet` | `sonnet` (or `opus`) | `sonnet` | `sonnet` |
| **Output** | Bugs with severity | Recommendations | Issues with WCAG refs | Findings with rewrites |
| **Skill** | `/visual-qa` | `/visual-qa polish` | `/accessibility-qa` | `/tone-qa` |

## When to trigger

### Bug QA (every visual checkpoint)
- After completing a round of visual/styling changes and confirming they render
- After fixing issues from a previous QA pass (second pass)

### Polish QA + Accessibility QA + Tone QA (milestones only)
- Before declaring a UI task or full screen done
- When the user asks you to review how something looks
- When doing a systematic screen-by-screen review
- NOT after every small edit — only at natural completion points
- Accessibility and Tone don't need to run together — use judgment:
  - **Accessibility:** when the change affects interactive elements, forms, navigation, or dynamic content
  - **Tone:** when the change affects user-facing text, empty states, error messages, or labels

## Protocol

1. **Two-tier screenshot capture** via Playwright (or ask user for simulator screenshot on React Native):

   **Tier 1 — Full page:**
   - Take a **full-page screenshot** (`browser_take_screenshot`, `fullPage: true`)
   - Capture a **DOM snapshot** (`browser_snapshot`) to identify widgets

   **Tier 2 — Per-widget at 2x CSS zoom:**
   - From the DOM snapshot, identify every distinct widget/card/section
   - Use `browser_run_code` to CSS-zoom each widget to 2x (`transform: scale(2)`) and screenshot via `page.screenshot` with `clip` — this renders 1px artifacts as 2px features, catching boundary issues invisible at 1x
   - For interactive widgets, also hover and re-screenshot at 2x

   Full-page-only reviews miss pixel-level issues. Widget-only reviews miss composition. You need both.

2. Read the project's `.claude/rules/visual-qa-philosophy.md` for design context

3. **Announce and dispatch agents in background** (`run_in_background: true`):
   - **Always:** Tell the user you're dispatching the Bug QA agent and what screen/component it's reviewing, then dispatch (`/visual-qa`) — pass screenshots + philosophy file
   - **At milestones:** Also tell the user you're dispatching in parallel as applicable:
     - Polish QA (`/visual-qa polish`) — always at milestones
     - Accessibility QA (`/accessibility-qa`) — when interactive elements, forms, or navigation changed
     - Tone QA (`/tone-qa`) — when user-facing text, empty states, or error messages changed

4. **Do NOT make more visual changes while waiting** — work on non-visual aspects or wait

5. **Bug QA findings** (when they return):
   - **High severity** → fix immediately
   - **Medium severity** → fix if straightforward, otherwise note for user
   - **Low severity** → mention to user, fix only if trivial

6. **Polish QA findings** (when they return):
   - Present as **recommendations**, not bugs — the user decides what to act on
   - Group by impact (significant, moderate, minor)
   - Include rationale for each recommendation

7. **Accessibility QA findings** (when they return):
   - **High severity** (blocks access) → fix immediately
   - **Medium severity** (degrades experience) → fix if straightforward
   - **Low severity** (best-practice gap) → mention to user

8. **Tone QA findings** (when they return):
   - Present as **recommendations**, like Polish QA — the user decides what to act on
   - **Significant** (undermines project voice) → fix the copy
   - **Moderate/Minor** → note for user

9. After fixing Bug QA issues, take new screenshots and run a **second Bug QA pass** only (not Polish/Accessibility/Tone again)

10. **Maximum 2 Bug QA passes per checkpoint.** After 2 passes, present any remaining findings to the user and move on. Do not enter an infinite correction loop.

## Information firewall

All review agents receive ONLY what their skill specifies:
- **Bug QA / Polish QA:** Screenshots + philosophy file + optional DOM snapshot (element names only)
- **Accessibility QA:** Screenshots + DOM snapshot (full accessibility tree with roles, labels, states) + optional accessibility notes
- **Tone QA:** Screenshots + DOM snapshot (text content) + voice guide

None of them receive:
- Source code, CSS, HTML, or templates
- File paths or directory structure
- Token values, class names, or component names
- Any implementation context

This separation is the entire point — the agents cannot rationalize implementation choices, they can only evaluate what's rendered.

## Learning from misses

If the user identifies visual issues that either agent missed:
- **Defects** (broken rendering, wrong colors, missing elements) → add to "Known Anti-Patterns" section
- **Design quality** (poor hierarchy, cramped spacing, color disharmony) → add to "Design Polish Checklist" section
