---
effort: high
---

Generate project-specific config files for Claude Review Team by interviewing the user about their project's design, voice, and review concerns.

## Process

1. **Check what exists:**
   - Look for `.claude/rules/visual-qa-philosophy.md`
   - Look for `.claude/rules/voice-guide.md`
   - Look for `.claude/rules/review-lenses/` directory with any `.md` files

   Report what was found. If all three exist, ask if the user wants to regenerate any of them.

2. **Explore the project first:**
   - Read CLAUDE.md if it exists
   - Check the tech stack (package.json, pyproject.toml, Gemfile, go.mod, etc.)
   - Look at the directory structure
   - Note the frameworks, languages, and patterns in use

3. **For each missing config, interview the user one question at a time:**

   ### Visual QA Philosophy (`.claude/rules/visual-qa-philosophy.md`)

   Ask these questions, one per message:
   1. "Describe your app's visual identity in a few sentences. What does it feel like? (warm/cool, minimal/rich, playful/serious, etc.)"
   2. "What are your biggest visual 'never do this' rules? Things that would immediately look wrong."
   3. "What platform? (web app, mobile app, desktop app, or multiple)"

   Generate the philosophy file from the answers + what you learned from the codebase.

   ### Voice Guide (`.claude/rules/voice-guide.md`)

   Ask these questions, one per message:
   1. "How should the app talk to users? Give me a few adjectives and an analogy. (e.g., 'warm and direct — like a friend who happens to be a great cook')"
   2. "What should the app NEVER sound like? Any specific phrases or tones to avoid?"
   3. "Any personality elements beyond standard UI? (mascots, themed language, humor, branded terms) — or is it straightforward?"

   Generate the voice guide from the answers.

   ### Review Lenses (`.claude/rules/review-lenses/`)

   Ask these questions, one per message:
   1. "What are the 2-3 biggest concerns when reviewing code in this project? (e.g., security, performance, data consistency, API compatibility, migration safety)"
   2. For each concern the user names, ask: "For [concern] — what specific file patterns should trigger a review, and what are the concrete things to check?"

   Generate one lens file per concern.

4. **After generating each file:**
   - Show the user what was created (full content)
   - Ask if they want to adjust anything
   - Create the `.claude/rules/` directory structure if it doesn't exist

5. **When done:**
   - Summarize what was created
   - Note that these files should be committed to the repo so team members share the same review standards
