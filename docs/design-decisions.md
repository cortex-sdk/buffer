# Design Decisions

The reasoning behind Buffer's major design choices. Each decision was made deliberately — this document explains why.

---

## Two Skills Instead of One

Buffer could ship as a single skill. We split it into two: `buffer` (runtime) and `buffer-optimizer` (setup + audit).

**Why:** Buffer triggers every session — start, monitor, wrap. The optimizer triggers occasionally — first install, weekly audits. A combined skill would load the full audit logic (~1.4KB of tokens) into every session, even though it's dead weight during normal runtime. Two skills means each loads only when needed.

**Trade-off:** Slightly more complex install (though the self-extracting pattern handles this — Buffer extracts the optimizer on first run).

---

## Setup Lives in the Optimizer, Not Buffer

First-time workspace setup (creating HANDOFF.md, validating MEMORY.md, checking AGENTS.md structure) runs through the optimizer, not the main buffer skill.

**Why:** Setup runs once. Buffer's three modes (start, monitor, wrap) run on every session. Keeping setup in Buffer would mean conditional logic ("is this the first time?") polluting the runtime path. Moving setup to the optimizer keeps Buffer purely runtime — no branching, no first-run detection after the initial extraction.

---

## Percentage-Based Thresholds

Buffer uses percentage zones (under 25%, 25–40%, 40–50%, over 50%) instead of hardcoded token counts.

**Why:** Context windows range from 32K to over 1M tokens across models. Hardcoded thresholds (like "wrap at 400K") only work for one model class. Percentages adapt automatically — 50% of a 200K window is 100K, 50% of a 1M window is 500K. One set of rules works everywhere.

**What we tried first:** Hardcoded thresholds at 400K/500K tokens. Worked great for Opus with a 1M window. Completely wrong for smaller models — 400K is over 100% of some context windows. Percentages were the obvious fix once we tested across model sizes.

**Trade-off:** Less precise than model-specific tuning. But a consistent, portable default beats a tuned threshold that breaks when you switch models.

---

## Outcomes Over Activity Logs

HANDOFF.md captures conclusions ("X works because Y") instead of activities ("we tested X, then tried Y, then built Z").

**Why:** A new session needs to know what's true now and what to do next. Activity logs force the next session to re-derive conclusions from a narrative. Outcomes let it build directly on results.

**Example:**
- ❌ "We ran 5 experiments comparing extraction approaches with different prompt strategies"
- ✅ "Structured tags with augmented prompts eliminate extraction noise across all model tiers"

The first requires the next session to figure out what the experiments concluded. The second is immediately actionable.

---

## Five-Section HANDOFF.md Template

Every handoff has exactly five sections: Current Work, Stopping Point, Key Outcomes, Open Questions, Next Steps.

**Why:** Each section serves a distinct recovery function:

| Section | Recovery question it answers |
|---|---|
| Current Work | Where am I? |
| Stopping Point | What was I doing? |
| Key Outcomes | What's been decided? |
| Open Questions | What's unresolved? |
| Next Steps | What should I do? |

An agent reading this file can orient in seconds without loading any other context. Fewer sections would leave gaps. More sections would add overhead without proportional value.

---

## Pre-Response Checkpoint Must Be First in AGENTS.md

Buffer Optimizer requires the skill trigger checkpoint to be the very first section of AGENTS.md.

**Why:** Attention in long prompts is strongest at the beginning and end. The checkpoint asks "does a skill handle this?" before the agent starts forming a response. If the checkpoint is buried after rules and policies, the agent has already committed to an approach before it considers whether a skill exists for the task.

This is the single highest-impact structural choice in AGENTS.md.

---

## Negative Triggers

In addition to positive triggers ("when X happens, use skill Y"), Buffer Optimizer checks for negative triggers ("don't do X manually — skill Y handles that").

**Why:** Positive and negative triggers catch different failure modes:
- **Positive:** "User shared a URL → use the research skill." Direct match.
- **Negative:** "Don't paste file contents in chat → use the sharing skill." Catches the agent doing the right thing (sharing a file) the wrong way (dumping contents into the conversation).

Agents bypass skills in predictable patterns. Negative triggers name those patterns explicitly.

---

## No External Dependencies

Buffer works with a file system and shell access. No database, no API keys, no external services.

**Why:** Buffer should work for every OpenClaw user, regardless of their setup. External dependencies create installation friction, failure modes, and support burden. File-based state is simple, portable, and inspectable — the owner can read HANDOFF.md in any text editor.

**Alternative considered:** We could have integrated with a persistent memory system for richer context recovery. But that would limit Buffer's audience to users of that specific system. Buffer is infrastructure — it should work everywhere, with optional integrations for users who want them.

---

## 2KB Limit for HANDOFF.md

HANDOFF.md is capped at 2KB.

**Why:** This file loads into every session's boot context. Too small (1KB) and you can't capture enough outcomes from a productive session. Too large (4KB) and you're spending context on session state instead of actual work.

2KB fits 5–8 outcomes, 3–5 open questions, and 5 next steps — the typical output of a productive session. If you consistently need more than 2KB, the handoff probably contains activity logs instead of conclusions, or architectural context that belongs in project files.

---

## Overwrite, Don't Append

HANDOFF.md is overwritten every wrap, not appended to.

**Why:** HANDOFF.md captures current state, not history. The previous session's handoff is irrelevant once the new session has been running — its context was consumed at start.

**What appending looked like:** We tried it. After three sessions, HANDOFF.md was 6KB of accumulated state — three versions of "current work," three sets of next steps, outcomes from sessions that no longer mattered. The agent couldn't distinguish current state from stale state. Overwrite forces clarity: what's true right now?

If historical session information matters, it belongs in memory files or a long-term memory system — not in the session bridge.

---

## Self-Extracting Optimizer

On first run, Buffer extracts `buffer-optimizer` automatically rather than requiring a separate install.

**Why:** Two skills that work together but require separate installation creates friction and confusion. The user installs one thing (`buffer`), and Buffer handles the rest. If extraction fails (sandboxed environment, read-only filesystem), Buffer degrades gracefully — it tells the owner how to install the optimizer separately and continues with runtime session management.

**Trade-off:** The optimizer's full content is embedded in the buffer SKILL.md, making it larger than a pure runtime skill. But this only loads on first run — after extraction, Buffer skips the embedded content entirely.
