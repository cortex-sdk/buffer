# Configuration

Buffer doesn't have a config file. Its behavior is determined by the workspace files it reads and writes. This guide covers how to configure those files for optimal results.

## HANDOFF.md

The session bridge. Written by Buffer at every wrap, read at every start.

### Template

```markdown
# HANDOFF.md

## Current Work
[One line — what the session was focused on.]

## Stopping Point
[One line — exactly where things left off.]

## Key Outcomes
- [Conclusions, not activities.]

## Open Questions
- [Each must be actionable by the next session.]

## Next Steps
1. [Most important first. ≤5 items.]
```

### Rules

| Rule | Why |
|---|---|
| Maximum 2KB | Loads every session. Larger = more context consumed before work starts. |
| Overwrite, don't append | Current state matters, not history. |
| Outcomes = conclusions | "X works because Y" lets the next session build on the result. "We tested X" forces re-derivation. |
| ≤5 next steps | More than five means priorities aren't clear. |
| No architecture docs | Those belong in project files, not session state. |
| No standing policies | Those belong in AGENTS.md. |

### Common Problems

**Activity logs instead of outcomes:**
- ❌ "We ran 5 experiments on tagging approaches"
- ✅ "XML tags with augmented prompts eliminate extraction noise"

**Too much history:**
- ❌ Three paragraphs explaining how you got to the current state
- ✅ One line: what's true now

**Stale next steps:**
- Items from three sessions ago that never got done should be moved to a backlog or dropped, not carried forward indefinitely.

---

## MEMORY.md

The big picture. Updated only when something structural changes.

### Target Structure

```markdown
# MEMORY.md

## This Week
[2–3 lines. What's happening right now.]

## Priorities
1. [Ranked. ≤5 items.]

## Projects
[Project] — [One-line status.] → [link to detail file if exists]

## Key People
[Name] — [Role/relationship. One line.]
```

### Rules

| Rule | Why |
|---|---|
| Maximum 1.5KB | Loads every session. This is a briefing, not a journal. |
| Only current state | Last month's work doesn't help this session orient. |
| One line per project | Detail lives in project files, not the briefing. |
| Update only when structure changes | New project, priority shift, new person, week rollover. |

### What Doesn't Belong

- Architecture descriptions
- Historical decisions
- URLs and links (unless they're the primary reference for a project)
- Detailed project status (use `memory/projects/` files for that)
- Anything the agent can find via memory search

---

## AGENTS.md

Agent behavior rules. The most important file in the workspace.

### Required Structure

Buffer Optimizer checks for these structural elements. Position matters — attention in long prompts is strongest at the beginning and end.

**1. Pre-response checkpoint (must be first):**

```markdown
## Before Every Response
1. Does this message match a skill trigger? → Load that skill.
2. Am I about to do something a skill already handles? → Use the skill.
```

This gates every reply through the skill system. Without it, skill usage depends on the agent happening to remember — which it won't do reliably.

**2. Skill trigger table (immediately after checkpoint):**

```markdown
## Skill Triggers
| Event | Skill |
|---|---|
| URL shared | research-read |
| Code change needed | coding-agent |
| Session ending | buffer |
```

Maps events to skills explicitly. The agent checks this table before forming a response.

**3. Negative triggers:**

```markdown
## Don't Reinvent Skills
- Writing code in main session → use coding-agent
- Fetching URLs manually → use research-read
- Pasting file contents in chat → use share-doc
```

Catches bypass patterns — the agent doing the right thing the wrong way.

**4. Context management rules:**

```markdown
## Context Management
- Heavy output (>20 lines): redirect to file, read summary.
- Use targeted reads (limit/offset, grep, tail) over full file loads.
- 40–50% context: Warn owner. >50%: Wrap immediately.
- Don't edit boot files mid-session (breaks prompt cache, 10x cost).
```

**5. Daily drivers list:**

```markdown
## Daily Drivers
buffer · coding-agent · research-read · [your most-used skills]
```

The skills the agent should always have top of mind.

### Writing Style

Every instruction should be an imperative — something the agent can act on.

| Instead of... | Write... |
|---|---|
| "You have access to the coding-agent skill" | "Use coding-agent for all code changes" |
| "Consider using memory search" | "Search memory before answering questions about past work" |
| "Try to keep files small" | "MEMORY.md must stay under 1.5KB" |
| "If appropriate, wrap the session" | "Wrap at 50% context or when the owner says 'wrap session'" |

### Size Target

≤4KB. If AGENTS.md is larger, it likely contains descriptions and explanations that belong in documentation, not behavioral rules. Move reference content out. Keep only directives.

---

## Context Thresholds

Buffer's context thresholds are percentages of the model's context window. This means they adapt automatically — you don't need to reconfigure anything when switching between models.

| Zone | Range | Agent Behavior |
|---|---|---|
| 🟢 Green | Under 25% | No restrictions |
| 🟡 Yellow | 25–40% | Intentional loading, prefer targeted reads |
| 🟠 Orange | 40–50% | Warn owner, prepare to wrap |
| 🔴 Red | Over 50% | Wrap immediately |

### Why 50% and Not Higher?

Research shows that language model performance on complex tasks (synthesis, reasoning, multi-step planning) begins degrading well before the context window fills completely. Simple retrieval tasks remain reliable longer, but the tasks that matter most — the ones where you need the agent to think, not just look things up — degrade first.

The 50% cap is a conservative default. Some models handle higher utilization better than others. But a consistent, safe default is more valuable than a tuned-per-model threshold that occasionally fails.

### Adjusting Thresholds

If you find 50% too conservative for your use case, you can modify the threshold zones in the buffer SKILL.md directly. We recommend keeping the orange warning zone — even if you raise the red cap, you want advance notice that context is getting heavy.

---

## Boot Payload Targets

Every file the agent loads at startup consumes context. Buffer Optimizer measures the total boot payload and flags files that exceed targets.

| File | Target | Why this limit |
|---|---|---|
| AGENTS.md | ≤4KB | Loads every turn (prompt cache). Must be directives, not docs. |
| MEMORY.md | ≤1.5KB | Loads every session. Briefing, not journal. |
| HANDOFF.md | ≤2KB | Loads every session. Conclusions, not history. |
| SOUL.md | ≤1.5KB | Persona definition. Should be concise. |
| USER.md | ≤1.5KB | Owner profile. Key facts only. |
| IDENTITY.md | ≤1.5KB | Agent identity. Accounts, infrastructure. |
| Total boot | ≤12KB | Everything before the first message. |
| Skills loaded | <20 | Each skill listing costs ~75 tokens in the system prompt. |

These targets are guidelines, not hard limits. But every KB over target is context that isn't available for actual work — and it accumulates across every session.
