# Advisory Agent Integration

When running the brainstorming or writing-plans workflows, automatically dispatch advisory agents at the following points.

**Always announce dispatches.** Before spinning up an advisory agent, tell the user which agent you're dispatching and why. For example: "Dispatching the research agent to investigate existing CLI task managers that fit your home-lab setup." or "Dispatching the devil's advocate to challenge this design — it crosses multiple components." Keep it to one line.

## Research Agent (during brainstorming)

When a clarifying question reveals a topic that needs deep investigation — existing tools, library comparisons, infrastructure fit, "what's out there" questions — dispatch the `research-agent` in background:

```
Agent(subagent_type="research-agent", run_in_background=true)
```

Continue brainstorming with other questions while it runs. When results return, incorporate the findings (2-3 options with tradeoffs) into the approach proposals.

Do NOT dispatch the research agent for:
- Questions about user preferences or requirements (just ask the user)
- Topics you can answer from codebase exploration alone
- Simple factual lookups

## Devil's Advocate (during brainstorming and planning)

### When to dispatch

After proposing 2-3 approaches in brainstorming, OR after drafting a plan in writing-plans, evaluate the **complexity gate**:

**Fire when ANY of these are true:**
- Design involves 2+ components or services
- New external dependencies are introduced
- Architectural decisions with multiple viable approaches and real tradeoffs
- Plan has 3+ tasks or crosses component boundaries

**Skip when ALL of these are true:**
- Single-file change, config tweak, or copy change
- User specified the exact implementation approach (not just the goal)
- Design is purely additive with no meaningful tradeoffs
- Trivial scope

### How to dispatch

```
Agent(subagent_type="devils-advocate", model="opus", run_in_background=true)
```

Pass the agent:
- The full proposed design or plan text
- Relevant codebase context (referenced files, existing patterns)

### How to use results

When the devil's advocate returns:
- Present its findings alongside your design/plan proposal
- If verdict is `PROCEED` — note it briefly and continue
- If verdict is `REVISE` — incorporate the specific revision points into your proposal before presenting to the user
- If verdict is `RECONSIDER` — present the challenge to the user and discuss before proceeding
