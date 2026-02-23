# Buffer Skill Reference

The `buffer` skill is the runtime component. It manages your sessions — recovering context, monitoring the context window, persisting decisions, and writing structured handoffs.

## Modes

Buffer has three modes that map to the session lifecycle:

| Mode | When | What it does |
|---|---|---|
| **Start** | Every new session | Recovers context from previous session |
| **Monitor** | Continuously during work | Controls intake, tracks usage, detects degradation |
| **Wrap** | Session end | Extracts outcomes, writes handoff, updates memory |

On first run only, Buffer also runs a **setup** sequence that extracts the companion `buffer-optimizer` skill and initializes workspace files.

---

## Start

Runs at the beginning of every new session. Goal: recover context instantly.

**What it does:**
1. Reads `HANDOFF.md` — where you left off, outcomes from last session, next steps
2. Reads `MEMORY.md` — current priorities, active projects, key people
3. Begins working immediately

**If HANDOFF.md doesn't exist:**
Buffer checks recent `memory/*.md` files and runs a memory search for context. If nothing is found, it asks the owner for orientation and recommends running `buffer-optimizer` to set up the workspace.

**Design note:** Start deliberately reads only two files. The agent doesn't load project files, old logs, or skill docs unless the current task requires them. Every file loaded at start consumes context that should be available for actual work.

---

## Monitor

Applies continuously throughout the session. Two responsibilities: intake discipline and degradation detection.

### Intake Discipline

Before loading any content into the context window, the agent applies four checks:

| Check | Question | If yes... |
|---|---|---|
| **Changed?** | Has this file been modified since I last read it? | Skip — don't reload unchanged files |
| **Need all of it?** | Do I need the full file, or just a section? | Use `grep`, `head`, `limit`/`offset` for targeted reads |
| **Can reference?** | Can I store this to disk and read a summary? | Redirect heavy output (>20 lines) to `/tmp` |
| **Cache impact?** | Will editing this break prompt caching? | Don't edit AGENTS.md/SOUL.md/USER.md/MEMORY.md mid-session |

**Why this matters:** Every token that enters the context window stays for the rest of the session. Prompt-cached tokens cost 10x less than uncached tokens. Re-reading an unchanged 4KB AGENTS.md costs the same as a new read but adds zero information.

### Context Thresholds

Thresholds are percentages of the model's context window, so they adapt automatically across models:

| Zone | Usage | Action |
|---|---|---|
| 🟢 Green | Under 25% | No concern. Full performance. |
| 🟡 Yellow | 25–40% | Be intentional about what you load. |
| 🟠 Orange | 40–50% | ⚠️ Warn the owner. Degradation begins on complex tasks. |
| 🔴 Red | Over 50% | 🔴 Wrap now. Quality is compromised. |

The 50% operational cap is conservative by design. Research shows degradation on complex tasks beginning at 40–50% of context capacity. Simple retrieval tasks remain reliable longer, but synthesis, reasoning, and multi-step planning degrade earlier.

### Degradation Signals

Independent of percentage, Buffer watches for behavioral patterns that indicate context quality has degraded:

- **Repeating itself** — restating information already covered (context distraction)
- **Forgetting decisions** — contradicting or re-asking about resolved questions (retrieval failure)
- **Ignoring earlier context** — only using recent information, missing relevant earlier material (recency bias)
- **Confusion from conflicts** — contradictory information in context causing inconsistent responses (context clash)
- **Referencing errors** — treating earlier hallucinations or mistakes as facts (context poisoning)

Any degradation signal should prompt the agent to warn the owner and recommend wrapping. The owner decides when to wrap — an unannounced wrap mid-task could lose unsaved work.

### Continuous Persistence

Buffer doesn't wait for session end to save important work. Throughout the session:

- Key decisions get appended to `HANDOFF.md` or a scratch file as they happen
- If a long-term memory system is available, decisions are written there immediately
- The test: **if this session crashed right now, would important stuff survive?**

This means the wrap phase is a cleanup pass, not a rescue operation.

---

## Wrap

Runs when: the owner says "wrap session," context hits 50%, or the conversation naturally concludes.

### Step 1: Extract from the session

Buffer scans the session for:
- Decisions made
- Outcomes reached (conclusions, not activities)
- Open questions that weren't resolved
- Corrections or changes in direction
- Logical next steps

### Step 2: Write HANDOFF.md

Buffer overwrites `HANDOFF.md` with the current state:

```markdown
# HANDOFF.md

## Current Work
[One line — what the session was focused on.]

## Stopping Point
[One line — exactly where things left off.]

## Key Outcomes
- [Conclusions, not activities. "X works because Y" — not "tested X."]

## Open Questions
- [Each must be actionable by the next session.]

## Next Steps
1. [Most important first. ≤5 items.]
```

**Rules:**
- Maximum 2KB. If over, compress outcomes to conclusions only.
- Outcomes are conclusions, not activity logs.
- Cut anything that doesn't directly affect future work.
- No architecture docs, standing policies, or issue lists.

### Step 3: Update MEMORY.md (conditional)

Only if something structural changed: new project started, priority shifted, new key person, or week rolled over. **Most sessions don't touch MEMORY.md.**

### Step 4: Persist unpersisted decisions

Final scan for anything that was decided during the session but not yet captured in `HANDOFF.md` or long-term memory.

### Step 5: Confirm to owner

Buffer tells the owner:
- What was saved
- Whether `MEMORY.md` was updated
- The top next step

---

## First Run Behavior

On the very first run, before entering the normal Start mode, Buffer checks whether `buffer-optimizer` exists as a sibling skill. If not:

1. Creates the `skills/buffer-optimizer/` directory
2. Writes `SKILL.md` with the full optimizer skill
3. Creates the measurement scripts (`measure-boot.sh`, `audit-agents-md.sh`)
4. Runs the optimizer's setup steps (create HANDOFF.md, validate MEMORY.md, check AGENTS.md)
5. Reports what was set up

If extraction fails (sandbox environment, read-only filesystem), Buffer tells the owner to install the optimizer separately and continues with normal session management.

After first run, this extraction logic is skipped entirely. Buffer is purely runtime from that point forward.

---

## File Dependencies

| File | Buffer reads | Buffer writes | Required? |
|---|---|---|---|
| `HANDOFF.md` | Start | Wrap | Created if missing |
| `MEMORY.md` | Start | Wrap (conditional) | Validated, not overwritten |
| `AGENTS.md` | — | — | Checked by optimizer only |
| `memory/*.md` | Start (fallback) | — | Optional |
