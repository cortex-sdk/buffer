---
name: buffer
description: Session runtime management for OpenClaw — context window optimization, session continuity, and structured wrap/recovery. Use at session start, during sessions for context monitoring, and at session end for wrap. No external dependencies.
---

# Buffer

Three modes: **start**, **monitor**, **wrap**. Run the one that matches your situation.

---

## Start

Run at every new session. Goal: recover context in under 30 seconds.

1. Read HANDOFF.md — where you left off, outcomes, next steps.
2. Read MEMORY.md — priorities, projects, people.
3. Start working. Do not read other files unless the task requires them.

**No HANDOFF.md?** Check recent `memory/*.md` files, try `memory_search`, then ask the owner. Consider running `buffer-optimizer` to set up your workspace.

---

## Monitor

Apply continuously during the session.

### Intake
Before loading content:
- **Changed?** Don't re-read unmodified files.
- **Need all of it?** Use `grep`, `head`, `limit`/`offset` over full reads.
- **Can reference instead?** Write large output to file, read summary.
- **Cache impact?** Don't edit AGENTS.md/SOUL.md/USER.md/MEMORY.md mid-session (breaks prompt cache, 10x cost).

### Output
- Redirect heavy output (>20 lines) to `/tmp`, read tail/summary.
- Pipe long commands through `tail`/`head`/`grep`.

### Context Thresholds

Thresholds are percentages of your model's context window. Run `session_status` → the **Context** line shows current usage (e.g., "68k/1.0m (7%)").

| Usage | Action |
|---|---|
| **<25%** | No concern. Full performance. |
| **25-40%** | Be intentional about what you load. |
| **40-50%** | ⚠️ Warn owner. Degradation begins on complex tasks. |
| **>50%** | 🔴 Wrap now. |

**Why 50% and not higher?** Research shows context quality degrades well before the window fills — on complex tasks (synthesis, planning, multi-step reasoning), degradation starts at 40-50% capacity. The 50% cap provides a safety margin. See the README for detailed research.

### Degradation signals — wrap immediately if you notice:
- Repeating yourself (context distraction)
- Forgetting earlier decisions (retrieval failure)
- Ignoring relevant earlier context (recency bias)
- Confusion from conflicting information (context clash)
- Referencing something that was wrong earlier (context poisoning)

These signals mean quality is already degraded — don't wait for the percentage threshold.

### Continuous persistence
Don't wait for wrap to save important information. As decisions happen during the session, append key outcomes to HANDOFF.md or a scratch file. If you have a long-term memory system (e.g., a memory plugin or external store), write decisions there immediately.

Test: if this session crashed now, would important stuff survive?

---

## Wrap

Run when: owner says "wrap", you hit 50% context, or conversation concludes.

### Step 1: Extract from the session
Scan for: decisions, outcomes, open questions, corrections, next steps.

### Step 2: Write HANDOFF.md
Overwrite with current state:

```markdown
# HANDOFF.md

## Current Work
[One line — focus area.]

## Stopping Point
[One line — where you left off.]

## Key Outcomes
- [Conclusions, not activities. "X works because Y" not "tested X".]

## Open Questions
- [Each must be actionable by the next session.]

## Next Steps
1. [Most important first. ≤5 items.]
```

**Rules:**
- ≤2KB. Over? Compress outcomes to conclusions only.
- Outcomes = conclusions, not activities.
- Cut anything that doesn't affect future work.
- Cut questions the next session can't act on.
- No architecture docs, standing policies, or issue lists.

### Step 3: Update MEMORY.md only if structure changed
New project, priority shift, new key person, or week rollover. Most sessions: don't touch it.

### Step 4: Persist unpersisted decisions
Scan for decisions or outcomes not yet captured in HANDOFF.md. If you have a long-term memory system, write them there too.

### Step 5: Confirm to owner
What was saved. Whether MEMORY.md was updated. Top next step.

---

## Quick Reference

| File | Purpose | Target | Updated |
|---|---|---|---|
| HANDOFF.md | Session state — recovery file | ≤2KB | Every wrap |
| MEMORY.md | Big picture — priorities, projects, people | ≤1.5KB | When structure changes |
| AGENTS.md | Behavioral rules | ≤4KB | Rarely |

### Context Budget (percentage of model window)

| Zone | Range | Behavior |
|---|---|---|
| Green | <25% | Full performance |
| Yellow | 25-40% | Intentional loading |
| Orange | 40-50% | Warn owner, prepare to wrap |
| Red | >50% | Wrap immediately |

```
Start → Read HANDOFF → Read MEMORY → Work → Monitor → Wrap → Write HANDOFF → End
                                                                      ↓
                                                              [Next session reads it]
```
