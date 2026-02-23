---
name: buffer-optimizer
description: Set up and optimize your OpenClaw workspace for operational reliability. Handles initial configuration (HANDOFF.md, MEMORY.md, AGENTS.md structure) and periodic audits (boot payload, skill management, memory hygiene). Run on first install, when asked to audit or optimize, or when things feel off. Companion to the buffer skill.
---

# Buffer Optimizer

Two modes: **setup** (first install) and **audit** (periodic maintenance). Run the one that matches your situation.

---

## Setup

Run on first install, or when the owner asks to configure their workspace for Buffer.

### 1. Create HANDOFF.md
If missing, create:
```markdown
# HANDOFF.md
## Current Work
## Stopping Point
## Key Outcomes
## Open Questions
## Next Steps
```

### 2. Validate MEMORY.md
Must contain only: this week (2-3 lines), priorities (≤5), project states (one line each), key people. Target: ≤1.5KB. If missing, create a minimal version with the owner's name and current focus.

### 3. Check AGENTS.md structure
Verify these exist. If missing, draft them and present to owner for approval:

**Pre-response checkpoint** (must be the first section):
```markdown
## Before Every Response
1. Does this message match a skill trigger? → Load that skill.
2. Am I about to do something a skill already handles? → Use the skill.
```

**Skill trigger table** (immediately after checkpoint):
```markdown
## Skill Triggers
| Event | Skill |
|---|---|
| [event] | [skill-name] |
```

**Negative triggers:**
```markdown
## Don't Reinvent Skills
- [manual pattern] → Use [skill-name]
```

**Context management rules:**
```markdown
## Context Management
- Heavy output (>20 lines): redirect to file, read summary.
- Use targeted reads (limit/offset, grep, tail) over full file loads.
- 40-50% context: Warn owner. >50%: Wrap immediately.
- Don't edit boot files mid-session (breaks prompt cache, 10x cost).
```

### 4. Classify skills
List all loaded skills. Classify as DAILY/WEEKLY/RARE/NEVER. Draft a daily driver list. Flag NEVER skills for potential exclusion.

### 5. Report setup status
Tell the owner what was created, what was validated, and what needs their review. Recommend installing `buffer` for runtime session management.

---

## Audit

Run periodically (weekly or bi-weekly), after major changes, or when the owner asks.

### Step 1: Measure Boot Payload

Run:
```bash
bash <SKILL_DIR>/scripts/measure-boot.sh
```

#### Thresholds

| File | Target | Action if exceeded |
|---|---|---|
| AGENTS.md | ≤4KB | Convert descriptions to directives. Move reference content out. |
| MEMORY.md | ≤1.5KB | Keep only: this week, priorities, projects, people. |
| HANDOFF.md | ≤2KB | Apply template: current work, stopping point, outcomes, questions, next steps. |
| Each memory/*.md | ≤2KB | Summarize transcripts. |
| Total boot | ≤12KB | Something doesn't belong in boot. |
| Skills loaded | <20 | Exclude unused skills (~75 tokens each). |

### Step 2: Audit AGENTS.md

Run:
```bash
bash <SKILL_DIR>/scripts/audit-agents-md.sh
```

Verify:
- **2.1** Pre-response checkpoint is the first section.
- **2.2** Skill trigger table immediately follows.
- **2.3** Negative triggers section exists.
- **2.4** No weak patterns:

| Pattern | Rewrite to |
|---|---|
| "You have access to..." | Delete or "Use X when Y" |
| "You might want to..." | "Do X when Y" |
| "Consider..." | "Do X" or delete |
| "Try to..." | "Must" + hard limit |
| "If appropriate..." | Define the condition explicitly |

- **2.5** Sections grouped by trigger, not topic.

### Step 3: Audit Skills

- Count skills from `<available_skills>` in system prompt.
- Classify each: DAILY / WEEKLY / RARE / NEVER.
- Draft daily driver list for AGENTS.md.
- Draft exclusion list. Present to owner — do not exclude unilaterally.

### Step 4: Audit Memory Files

- **MEMORY.md** — only: this week, priorities, projects, people. Flag old history, architecture, URLs.
- **HANDOFF.md** — only: current work, stopping point, outcomes, questions, next steps. Outcomes = conclusions, not activities.
- **memory/*.md** — over 2KB → summarize. Over 3 days → archive. Duplicates → remove.
- **Ghost files** — flag any `*.md` in workspace root not in: AGENTS.md, SOUL.md, USER.md, MEMORY.md, HANDOFF.md, IDENTITY.md.

### Step 5: Check Reliability

- **Compaction flush:** Enabled? If unknown, flag.
- **Wrap ritual:** Does `buffer` skill or equivalent exist? If missing, recommend install.
- **Automated persistence:** Write hooks, observers, auto-commit? If none, flag as priority gap.

### Step 6: Self-Tests

- **Recovery:** Read HANDOFF.md — does it reflect current state?
- **Skill bypass:** Did you recently do manually what a daily driver skill handles?
- **Drift:** Re-read AGENTS.md. Flag any instruction you're not following.

### Step 7: Report

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

Wait for owner approval before implementing.
