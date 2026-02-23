# Buffer

**Session management for OpenClaw agents — context window optimization, seamless session continuity, and structured wrap/recovery.**

## The Problem

Every OpenClaw session starts from zero. The agent reads its system prompt, sees its workspace files, and has no idea what happened yesterday. If the last session didn't save state properly — or saved it in the wrong format — the agent wastes the first 10 minutes re-discovering context, asking the owner "what were we working on?", or worse, silently proceeding with stale assumptions.

Meanwhile, during a session, the context window fills up invisibly. There's no built-in warning system. The agent loads file after file, reads full documents when it needs one line, and doesn't notice when quality starts degrading. By the time it starts repeating itself or forgetting earlier decisions, the session is already compromised.

Buffer solves both problems with a simple lifecycle: **start → monitor → wrap → repeat.**

## How It Works

Buffer has four modes, matching the four phases of a session:

### Setup (run once)

Creates the workspace files Buffer depends on:
- **HANDOFF.md** — the session recovery file. Written at the end of every session, read at the start of the next one. This is the bridge between sessions.
- **MEMORY.md** — the big picture. Priorities, projects, key people. Changes rarely.
- Context management rules in **AGENTS.md** — thresholds and wrap triggers.

If these files already exist, Setup validates them against Buffer's templates.

### Start (every new session)

A 30-second cold start sequence:
1. Read HANDOFF.md — where you left off, what was decided, what's next.
2. Read MEMORY.md — priorities, projects, people.
3. Start working.

That's it. No re-reading old transcripts, no loading project files "just in case," no asking the owner for context. HANDOFF.md has everything the agent needs because the last session's Wrap mode put it there.

### Monitor (during session)

Continuous discipline for context window health:

**Intake control** — before loading anything into context, the agent checks: Has this file changed? Do I need all of it, or just a section? Can I write the output to a file and read a summary instead? Will editing this file break prompt caching?

**Output management** — heavy tool output (>20 lines) gets redirected to temp files. The agent reads the tail or summary, not the whole thing.

**Threshold monitoring** — the agent tracks context usage as a percentage of the model's window and acts on thresholds (see [Context Thresholds](#context-thresholds) below).

**Degradation detection** — the agent watches for behavioral signals that indicate context quality has already degraded, regardless of token count.

**Continuous persistence** — important decisions get saved as they happen, not batched at wrap time. If the session crashes, the important stuff survives.

### Wrap (end of session)

Structured extraction that writes everything the next session needs:
1. Scan the conversation for decisions, outcomes, open questions, corrections, and next steps.
2. Write HANDOFF.md with a specific five-section template.
3. Update MEMORY.md only if something structural changed (new project, priority shift, etc.).
4. Confirm to the owner what was saved.

## The HANDOFF.md Template

This is the core of Buffer's session continuity. Every wrap produces a HANDOFF.md with exactly five sections:

```markdown
# HANDOFF.md

## Current Work
[One line — what the focus area was.]

## Stopping Point
[One line — exactly where you left off.]

## Key Outcomes
[Decisions and conclusions that affect future work.]
- [Conclusions, not activities. "X works because Y" — not "tested X".]

## Open Questions
[Unresolved items the next session needs to know about.]
- [Each must be actionable by the next session.]

## Next Steps
1. [Most important first. ≤5 items.]
```

### Why this structure?

**Current Work + Stopping Point** tell the next session *where it is* — enough to orient in seconds.

**Key Outcomes** are the highest-value section. These are *conclusions*, not activity logs. The next session doesn't need to know "we ran 5 experiments" — it needs to know "tags improve extraction quality by 40%." This prevents re-derivation: the next session won't redo work because it has the results.

**Open Questions** prevent dropped threads. Without this section, unresolved items from one session silently disappear. The next session doesn't know to pick them up.

**Next Steps** give the agent a starting point. Instead of asking "what should I do?", it reads step 1 and starts working.

### Writing rules

- **≤2KB.** This file loads into every session's boot context. Keep it tight.
- **Outcomes are conclusions, not activities.** "Ran 5 experiments" → "Tags improve extraction by 40%."
- **Every outcome must affect future work.** Interesting but irrelevant → cut.
- **Every open question must be actionable.** If the next session can't do anything with it → cut.
- **No architecture descriptions** (project docs), **no standing policies** (AGENTS.md), **no issue lists** (issue tracker). Each of these has a home — HANDOFF.md isn't it.

## Context Thresholds

Buffer uses percentage-based thresholds instead of hardcoded token counts. This makes the skill work across any model — whether you're running Claude with a 200K window, Gemini with 1M, or a local model with 32K.

| Zone | Usage | Action |
|---|---|---|
| 🟢 Green | <25% | Full performance. No concern. |
| 🟡 Yellow | 25-40% | Be intentional about what you load. |
| 🟠 Orange | 40-50% | Warn the owner. Degradation begins on complex tasks. |
| 🔴 Red | >50% | Wrap immediately. |

### Why 50% and not higher?

The thresholds are deliberately conservative, and they're based on research into how context window performance actually degrades.

#### The Research: Context Rot

**Chroma Research (July 2025)** published ["Context Rot: How Increasing Input Tokens Impacts LLM Performance"](https://research.trychroma.com/context-rot), evaluating 18 state-of-the-art models including GPT-4.1, Claude 4, Gemini 2.5, and Qwen3. Their key findings:

- **Performance degrades with input length even on simple tasks.** Models show measurable accuracy drops on basic retrieval as context grows — and the tasks agents actually perform (synthesis, planning, multi-step reasoning) are far more demanding than retrieval.
- **Degradation is non-uniform.** It's not a smooth decline. Some models hold steady until a threshold, then drop sharply. Others degrade gradually from the start. You can't predict exactly when quality will fall for your specific model and task.
- **Distractors accelerate degradation.** When context contains information that's *related but not relevant* to the current task — which describes most of an agent's accumulated context — accuracy drops faster. Agent context windows are full of previous tool outputs, old file reads, and earlier conversation turns that are exactly this kind of distractor.
- **Semantic tasks degrade faster than lexical ones.** Standard "needle in a haystack" tests (finding an exact phrase) show near-perfect scores even at high context. But when the task requires semantic understanding — connecting concepts, inferring relationships, synthesizing across sources — degradation is significantly worse. Agent tasks are almost entirely semantic.
- **Haystack structure matters.** Logically structured documents (like the conversation history an agent accumulates) can actually perform *worse* than randomly shuffled text, suggesting that attention mechanisms interact with document structure in unintuitive ways.

**Drew Breunig (June 2025)** identified [four degradation patterns](https://www.dbreunig.com/2025/06/22/how-contexts-fail-and-how-to-fix-them.html) in long-context agent sessions:

- **Context Poisoning** — A hallucination or error enters the context and gets repeatedly referenced in subsequent turns. The error compounds because the model treats its own earlier output as ground truth.
- **Context Distraction** — The context grows so long that the model leans heavily on recent context and repeats past actions rather than forming new plans. The agent gets stuck in loops.
- **Context Confusion** — Irrelevant information in the context influences responses. The agent uses wrong tools, references wrong files, or applies logic from an unrelated earlier task.
- **Context Clash** — Conflicting information exists in context (e.g., an old decision and a new decision that supersedes it). The model oscillates between them or produces inconsistent outputs.

#### What this means for thresholds

The research shows that context quality degrades *before* the window fills — often significantly before. But the exact degradation curve depends on your model, your tasks, and what's in your context.

Buffer's thresholds are set at the conservative end:
- **50% wrap trigger** — provides a safety margin even for the most degradation-prone models and tasks
- **40% warning** — gives the owner and agent time to plan a clean wrap rather than an emergency one
- **25% "be intentional"** — the point at which careless loading starts to have a real cost, even if quality is still high

If you're running a model with strong long-context performance (Claude Opus, Gemini 2.5 Pro) on relatively simple tasks, you could safely push these higher. If you're running a smaller model or doing complex synthesis work, you might want them lower.

The behavioral degradation signals in the skill (repeating yourself, forgetting decisions, confusion from conflicting context) are the real-time check. Percentage thresholds are the safety net — the signals are the ground truth.

## Context Window as Cache

The context window is a cache, not a database. Buffer treats it accordingly:

- **Bootstrap files are cached** — AGENTS.md, SOUL.md, USER.md, MEMORY.md stay in the prompt cache. Editing them mid-session invalidates the cache and increases cost by up to 10x on the next turn. Defer edits to session end.
- **Load what you need** — use `limit`/`offset` on reads, `grep`/`tail` for targeted extraction. Never load a full file when you need one section.
- **Source of truth is on disk** — workspace files, not context. If something isn't in context, it's still on disk. The agent can re-read it.
- **Heavy output goes to files** — redirect large tool output to `/tmp` and read a summary. Don't let raw output bloat the context.

## Memory Tiers

Buffer operates on a three-tier memory model:

| Tier | What's stored | Persistence | Managed by |
|---|---|---|---|
| **Context Window** | Current conversation, loaded files, tool output | Current session only | Monitor mode |
| **Workspace Files** | HANDOFF.md, MEMORY.md, project docs | Persists on disk | Wrap mode |
| **Long-Term Memory** | Decisions, preferences, lessons, facts | Persists across sessions | Optional (memory plugin, external store) |

Buffer works completely with just the first two tiers. HANDOFF.md bridges sessions. MEMORY.md provides the big picture. The agent writes to both during wrap. No plugins or external systems required.

If you have a long-term memory system (memory plugin, vector store, or similar), the third tier adds continuous persistence — decisions and lessons get written the moment they happen, not just at wrap time. This is an upgrade, not a requirement.

## Cost Awareness

Every token in context costs money. Buffer reduces cost through:

- **Prompt cache preservation** — not editing bootstrap files mid-session keeps cached tokens at 1/10th the price
- **Targeted reads** — loading 20 lines instead of 500 saves tokens directly
- **Output redirection** — keeping heavy tool output out of context
- **Timely wraps** — wrapping before degradation prevents wasted tokens on low-quality turns
- **Percentage-based thresholds** — the same rules apply whether your window is 32K or 1M, automatically scaling cost management to your model

Note: some providers (including Anthropic) charge higher rates for context beyond certain thresholds (e.g., 2x input price over 200K tokens). Buffer's conservative wrap targets naturally keep usage below these pricing tiers in most sessions.

## Requirements

- OpenClaw with workspace file support
- File system + shell access (for `session_status`, file reads)
- No external dependencies
- Works with any model and context window size

## Installation

```bash
clawhub install buffer
```

Or clone from the GitHub repo and copy `buffer/` into your workspace `skills/` directory.

## Companion Skill

**[buffer-optimizer](../buffer-optimizer/)** audits your workspace configuration to ensure Buffer can operate effectively. It measures boot payload, audits AGENTS.md structure, classifies skills, and validates memory files. Run it periodically to keep your setup tuned.

Buffer runs your sessions. Buffer-optimizer tunes your setup.

## References

- Chroma Research. ["Context Rot: How Increasing Input Tokens Impacts LLM Performance."](https://research.trychroma.com/context-rot) July 2025.
- Drew Breunig. ["How Long Contexts Fail."](https://www.dbreunig.com/2025/06/22/how-contexts-fail-and-how-to-fix-them.html) June 2025.
- LangChain. ["How to Fix Your Context."](https://github.com/langchain-ai/how_to_fix_your_context) Based on Breunig's degradation taxonomy.
