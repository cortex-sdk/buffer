# Buffer Optimizer Reference

The `buffer-optimizer` skill handles workspace setup and periodic audits. It runs occasionally — on first install, when things feel off, after major changes, or on a regular cadence (weekly or bi-weekly).

## Modes

| Mode | When | What it does |
|---|---|---|
| **Setup** | First install | Creates workspace files, validates structure, classifies skills |
| **Audit** | Periodically | Measures, diagnoses, and proposes fixes |

---

## Setup

Runs on first install or when the owner asks to configure their workspace.

### Step 1: Create HANDOFF.md

If missing, creates the template:

```markdown
# HANDOFF.md

## Current Work
## Stopping Point
## Key Outcomes
## Open Questions
## Next Steps
```

### Step 2: Validate MEMORY.md

Checks that MEMORY.md contains only what belongs there:
- This week's summary (2–3 lines)
- Priorities (≤5)
- Project states (one line each)
- Key people

Target: ≤1.5KB. If MEMORY.md is missing, the optimizer creates a minimal version with the owner's name and current focus.

### Step 3: Check AGENTS.md Structure

The optimizer verifies four structural requirements and drafts missing sections for owner approval:

**Pre-response checkpoint** — must be the first section:
```markdown
## Before Every Response
1. Does this message match a skill trigger? → Load that skill.
2. Am I about to do something a skill already handles? → Use the skill.
```

**Skill trigger table** — immediately after the checkpoint:
```markdown
## Skill Triggers
| Event | Skill |
|---|---|
| [event] | [skill-name] |
```

**Negative triggers** — catches bypass patterns:
```markdown
## Don't Reinvent Skills
- [manual pattern] → Use [skill-name]
```

**Context management rules:**
```markdown
## Context Management
- Heavy output (>20 lines): redirect to file, read summary.
- Use targeted reads (limit/offset, grep, tail) over full file loads.
- 40–50% context: Warn owner. >50%: Wrap immediately.
- Don't edit boot files mid-session (breaks prompt cache, 10x cost).
```

### Step 4: Classify Skills

Lists all loaded skills and classifies each by usage frequency:
- **DAILY** — used most sessions
- **WEEKLY** — used regularly
- **RARE** — occasional use
- **NEVER** — never triggered, candidate for exclusion

Drafts a daily driver list and an exclusion list for the owner to review.

### Step 5: Report

Summarizes what was created, validated, and what needs the owner's review.

---

## Audit

The audit runs seven steps sequentially. It measures, diagnoses, and proposes — it never modifies files without owner approval.

### Step 1: Measure Boot Payload

Runs `measure-boot.sh` to measure every file the agent loads at startup.

**Thresholds:**

| File | Target | If exceeded |
|---|---|---|
| AGENTS.md | ≤4KB | Convert descriptions to imperatives. Move reference content to docs. |
| MEMORY.md | ≤1.5KB | Keep only: this week, priorities, projects, people. |
| HANDOFF.md | ≤2KB | Compress to conclusions. Apply the five-section template. |
| Each memory/*.md | ≤2KB | Summarize transcripts. Archive old logs. |
| Total boot payload | ≤12KB | Something doesn't belong in boot. |
| Skills loaded | <20 | Exclude unused skills (~75 tokens each in system prompt). |

### Step 2: Audit AGENTS.md

Runs `audit-agents-md.sh` to check structural requirements:

| Check | What it verifies |
|---|---|
| 2.1 | Pre-response checkpoint is the first section |
| 2.2 | Skill trigger table immediately follows |
| 2.3 | Negative triggers section exists |
| 2.4 | No weak instruction patterns (see below) |
| 2.5 | Sections grouped by trigger, not topic |

**Weak patterns** — the audit flags these and proposes imperative rewrites:

| Weak Pattern | Rewrite to |
|---|---|
| "You have access to..." | Delete, or "Use X when Y" |
| "You might want to..." | "Do X when Y" |
| "Consider..." | "Do X" or delete |
| "Try to..." | "Must" + hard limit |
| "If appropriate..." | Define the condition explicitly |

### Step 3: Audit Skills

- Counts all skills from the system prompt
- Classifies each: DAILY / WEEKLY / RARE / NEVER
- Drafts a daily driver list for AGENTS.md
- Drafts an exclusion list with estimated token savings
- **Does not exclude anything without owner approval**

At ~75 tokens per skill listing, excluding 50 unused skills saves ~3,750 tokens per session.

### Step 4: Audit Memory Files

**MEMORY.md** — flags old history, architecture descriptions, URLs, anything that isn't current priorities/projects/people.

**HANDOFF.md** — checks the five-section template. Flags activity logs masquerading as outcomes ("we tested X" instead of "X works because Y").

**memory/*.md** — files over 2KB get flagged for summarization. Files older than 3 days get flagged for archiving. Duplicates of MEMORY.md content get flagged for removal.

**Ghost files** — any `.md` file in the workspace root that isn't in the recognized set (AGENTS.md, SOUL.md, USER.md, MEMORY.md, HANDOFF.md, IDENTITY.md). OpenClaw doesn't auto-load these files. Whatever instructions they contain, the agent never sees them — creating a dangerous gap between what the owner thinks is configured and what the agent actually follows.

### Step 5: Check Reliability

Three infrastructure checks:

| Check | What it verifies | Why it matters |
|---|---|---|
| Compaction flush | Does the system persist context before compacting? | Without it, information can be lost silently |
| Wrap ritual | Does a structured wrap procedure exist? | Without it, session endings lose state |
| Automated persistence | Write hooks, observers, auto-commit? | Without it, everything depends on the agent remembering |

### Step 6: Self-Tests

Three behavioral checks the agent runs on itself:

| Test | What it checks |
|---|---|
| **Recovery** | Does HANDOFF.md reflect the current state? If not, a crash right now would lose context. |
| **Skill bypass** | Did the agent recently do manually what a skill handles? |
| **Drift** | Is the agent following every instruction in AGENTS.md? |

### Step 7: Report

Everything compiles into a structured report:

```markdown
## Buffer Optimizer Report — [date]

### Boot Payload
- Total: X bytes (~Y tokens) [PASS/OVER 12KB]
- [file-by-file with pass/fail]

### AGENTS.md Structure
- Pre-response checkpoint: [YES/NO]
- Triggers first: [YES/NO]
- Negative triggers: [YES/NO]
- Weak patterns: [count]
- Organization: [trigger/topic]

### Skills
- Loaded: N (target: <20)
- Daily drivers: [list]
- Exclusion candidates: [list] (~X tokens saved)

### Memory
- MEMORY.md: X bytes [PASS/OVER]
- HANDOFF.md: X bytes [PASS/OVER]
- Ghost files: [list or none]
- Files needing work: [list or none]

### Reliability
- Compaction flush: [enabled/disabled/unknown]
- Wrap ritual: [exists/missing]
- Persistence: [exists/missing]

### Self-Tests
- Recovery: [yes/no]
- Skill bypasses: [list or none]
- Drift: [list or none]

### Proposed Changes
1. **[Change]** — [rationale]. Saves ~X tokens.
```

The owner reviews and approves before any changes are implemented.

---

## Included Scripts

Two shell scripts in `scripts/`:

### measure-boot.sh

Measures all boot files (AGENTS.md, SOUL.md, USER.md, MEMORY.md, HANDOFF.md, IDENTITY.md) in bytes, lines, and estimated tokens. Counts memory files and loaded skills. Checks for ghost files. Reports against thresholds with pass/fail.

### audit-agents-md.sh

Checks AGENTS.md structural requirements: first section positioning, checkpoint presence, negative triggers, weak instruction patterns. Reports with pass/fail for each check.

Both scripts can be run standalone for quick checks outside of a full audit.

---

## Relationship to Buffer

Buffer Optimizer validates what the Buffer runtime depends on:

| Buffer does... | Optimizer validates... |
|---|---|
| Reads HANDOFF.md on start | HANDOFF.md follows the right template |
| Enforces context rules from AGENTS.md | Those rules exist and are structured correctly |
| Writes HANDOFF.md on wrap | Output stays within size targets |
| Loads skills via trigger table | Trigger table is positioned correctly |

**Natural cadence:** Buffer every session. Buffer Optimizer every week or two.
