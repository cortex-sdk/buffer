# Research

Buffer's design is informed by published research on how language models behave as context windows fill. This page summarizes the key findings and how they shaped Buffer's thresholds and degradation model.

---

## Context Rot — Chroma Research (July 2025)

**Source:** [research.trychroma.com/context-rot](https://research.trychroma.com/context-rot)

Chroma tested 18 language models on tasks of varying complexity as context length increased. The core finding: **performance degrades with context length, even on simple tasks.**

### Key Findings

**Degradation is universal.** Every model tested showed performance decline as context grew. No model was immune. The decline was gradual, not catastrophic — performance doesn't fall off a cliff, it erodes.

**Semantic tasks degrade faster.** Simple retrieval ("find this fact in the context") remained relatively reliable at high utilization. But semantic tasks — summarization, synthesis, reasoning about relationships — degraded earlier and more severely. These are exactly the tasks that matter most in agent workflows.

**Distractors accelerate degradation.** Irrelevant content in the context window doesn't just take up space — it actively degrades performance on the relevant content. This means careless context loading (re-reading unchanged files, dumping full outputs, loading entire files when a section would do) isn't just wasteful, it's harmful.

**Larger windows don't fully compensate.** Models with larger context windows showed similar degradation patterns — just at higher absolute token counts. A 1M context window doesn't mean 1M tokens of reliable performance.

### How This Shaped Buffer

- **Percentage-based thresholds** instead of hardcoded token counts — degradation is proportional to window utilization, not absolute size
- **The 50% operational cap** — conservative, but the research shows complex tasks degrading at 40–50%
- **Intake discipline** — every unnecessary token in context actively degrades performance, not just wastes space
- **Wrap before failure** — by the time you notice degradation (repeating, forgetting), you've already been degraded for a while

---

## How Long Contexts Fail — Drew Breunig (June 2025)

**Source:** [dbreunig.com/2025/06/22/how-contexts-fail-and-how-to-fix-them.html](https://www.dbreunig.com/2025/06/22/how-contexts-fail-and-how-to-fix-them.html)

Breunig identified four distinct patterns of context failure. Where Chroma's research quantified *that* context degrades, Breunig categorized *how*.

### The Four Degradation Patterns

**Context Poisoning**
A hallucination or error enters the context early in the conversation. As the session continues, the model references this incorrect information repeatedly, treating it as established fact. The error compounds — later responses build on it, making it harder to detect and correct.

Buffer's response: Continuous persistence. When decisions are captured to external files as they happen, there's a written record to check against. The wrap process extracts *outcomes*, not raw conversation, reducing the chance of propagating errors.

**Context Distraction**
The model starts favoring repetition of its own previous outputs over generating new analysis. Instead of thinking through a problem fresh, it restates what it said before — sometimes verbatim. The context becomes an echo chamber where the model's own outputs are the loudest signal.

Buffer's response: Context thresholds. Distraction correlates with context length. Wrapping before the window fills too full reduces the chance of the model falling into repetition loops. The wrap itself resets this pattern — the next session starts with clean context.

**Context Confusion**
Irrelevant content in the context window influences responses even when it shouldn't. The model can't fully ignore information that's present — it bleeds into analysis, recommendations, and decisions. More noise in the context means less reliable signal.

Buffer's response: Intake discipline. Don't load content you don't need. Use targeted reads instead of full file loads. Redirect heavy outputs to files instead of keeping them in context. Every token you don't load is a distraction you've prevented.

**Context Clash**
Contradictory information in the context — an early decision followed by a later correction, two conflicting sources, or updated information that doesn't replace the original — causes the model to produce inconsistent or confused responses. It may alternate between the contradicting positions or try to reconcile them incorrectly.

Buffer's response: Overwrite, don't append. HANDOFF.md is replaced every wrap, not accumulated. The current state supersedes all previous states. Within a session, continuous persistence to external files means decisions have a single source of truth outside the context window.

### How This Shaped Buffer

- **Degradation signals** — Buffer watches for all four patterns (repeating, forgetting, ignoring context, referencing errors) as behavioral triggers for wrapping
- **Intake as defense** — context discipline isn't just about cost, it's about preventing confusion and distraction
- **External truth** — decisions persisted to files are more reliable than decisions only in context
- **Fresh starts** — wrapping and starting a new session is a feature, not a failure. It resets degradation.

---

## Implications for Agent Design

These findings point to a broader principle: **the context window is a tool, not a storage system.**

Treating the context window as a place to accumulate everything — conversation history, file reads, tool outputs, old decisions — guarantees degradation. The window fills with noise, relevant information gets harder to retrieve, and the model's reasoning quality drops.

Buffer treats the context window as a cache:
- Load what you need for the current task
- Keep it lean through intake discipline
- Persist important information externally
- Wrap and start fresh before quality degrades
- Bridge sessions through structured handoffs, not accumulated context

The research validates this approach. Models perform best with relevant, focused context — not maximum context.

---

## What We Don't Know

Honest documentation means acknowledging gaps.

**Model-specific degradation curves.** Chroma tested 18 models, but published results don't include fine-grained degradation curves for every model at every context percentage. The 50% operational cap is a conservative default informed by the general pattern — not a precisely calibrated threshold for any specific model. Some models may handle 60% reliably; others may degrade earlier.

**Long-term effectiveness.** Buffer has been tested in production use but not in a controlled longitudinal study. We don't have data on whether structured handoffs maintain quality over 50+ consecutive sessions versus unstructured approaches. The logic is sound, but the long-term data doesn't exist yet.

**Interaction with compaction.** Many agent frameworks compact context when it gets too large. Buffer's thresholds are based on raw context usage — they don't account for how compaction changes the quality of what remains. A compacted 60% context window may be better or worse than an uncompacted 40% window depending on what was kept.

**Degradation signal reliability.** Buffer watches for behavioral patterns like repetition and forgotten decisions. But these signals are identified by the same agent whose context may be degraded — the detector is also the patient. We don't know how reliably agents self-diagnose degradation at different utilization levels.

These gaps inform the conservative design. When you don't know exactly where the line is, you stay well inside it.
