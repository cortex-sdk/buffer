---
name: buffer-optimizer
description: Audit and optimize your OpenClaw workspace for session reliability and token efficiency. Measures boot payload, audits AGENTS.md structure, classifies skills, validates memory files, and drafts fixes. Run when asked to audit, optimize, or check your configuration. Companion to the buffer skill.
---

# Buffer Optimizer

Audit your workspace in 7 steps. Run sequentially. Present findings as a report — do not modify files without owner approval.

---

## Step 1: Measure Boot Payload

Run the measurement script:
```bash
bash <SKILL_DIR>/scripts/measure-boot.sh
```

### Thresholds

| File | Target | Action if exceeded |
|---|---|---|
| AGENTS.md | ≤4KB | Convert descriptions to directives. Move reference content out. |
| MEMORY.md | ≤1.5KB | Keep only: this week, priorities, projects, people. |
| HANDOFF.md | ≤2KB | Apply template: current work, stopping point, outcomes, questions, next steps. |
| Each memory/*.md | ≤2KB | Summarize transcripts. |
| Total boot | ≤12KB | Something doesn't belong in boot. |
| Skills loaded | <20 | Exclude unused skills (~75 tokens each). |

## Step 2: Audit AGENTS.md

Run the structure audit:
```bash
bash <SKILL_DIR>/scripts/audit-agents-md.sh
```

Verify five requirements:

**2.1** First `##` section is a skill trigger table. If not → recommend moving it first.

**2.2** Pre-response checkpoint exists after triggers:
```
## Before Every Response
1. Does this message match a skill trigger? → Load that skill.
2. Am I about to do something a skill already handles? → Use the skill.
```

**2.3** Negative triggers section exists:
```
## Don't Reinvent Skills
- [manual pattern] → Use [skill-name]
```

**2.4** Flag weak patterns and propose rewrites:

| Pattern | Rewrite to |
|---|---|
| "You have access to..." | Delete or "Use X when Y" |
| "You might want to..." | "Do X when Y" |
| "Consider..." | "Do X" or delete |
| "Try to..." | "Must" + hard limit |
| "If appropriate..." | Define the condition explicitly |

**2.5** Sections grouped by trigger (when they fire), not topic (what they're about).

## Step 3: Audit Skills

**3.1** Count skills from `<available_skills>` in system prompt.

**3.2** Classify each:
- **DAILY** — most sessions → trigger table + daily driver list
- **WEEKLY** — regular use → trigger table
- **RARE** — occasional → keep, no trigger
- **NEVER** — never triggered → exclusion candidate (~75 tokens saved each)

**3.3** Draft daily driver list for AGENTS.md.

**3.4** Draft exclusion list. Present to owner — do not exclude unilaterally.

## Step 4: Audit Memory Files

**MEMORY.md** — only: this week, priorities (≤5), project states, key people. Flag: old history, architecture, URLs, "what happened" instead of "what matters now."

**HANDOFF.md** — only: current work, stopping point, key outcomes, open questions, next steps. Outcomes must be conclusions, not activities. Each question must be actionable. No architecture, policies, or issue lists.

**memory/*.md** — over 2KB → summarize. Over 3 days old → archive. Duplicates MEMORY.md → remove.

**Ghost files** — list all `*.md` in workspace root. Flag any not in: AGENTS.md, SOUL.md, USER.md, MEMORY.md, HANDOFF.md, IDENTITY.md.

## Step 5: Check Reliability

- **Compaction flush:** Enabled? If unknown, flag.
- **Wrap ritual:** Does a wrap skill/procedure exist? If missing, recommend `buffer` skill.
- **Automated persistence:** Write hooks, observers, auto-commit? If none, flag as priority gap.

## Step 6: Self-Tests

**Recovery:** Read HANDOFF.md — does it reflect current state? If not, flag the gap.

**Skill bypass:** For each daily driver — did you recently do manually what it handles?

**Drift:** Re-read AGENTS.md. Flag any instruction you're not following.

## Step 7: Report

```markdown
## Buffer Optimizer Report — [date]

### Boot Payload
- Total: X bytes (~Y tokens) [PASS/OVER 12KB]
- [file-by-file with pass/fail]

### AGENTS.md Structure
- Triggers first: [YES/NO]
- Pre-response checkpoint: [YES/NO]
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
