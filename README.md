# Buffer

**Session management for OpenClaw agents.**

Buffer gives your agent structured context window management, seamless session continuity, and disciplined wrap/recovery — with no external dependencies.

## Two Skills

| Skill | What it does | When to use |
|---|---|---|
| **[buffer](./buffer/)** | Session lifecycle — start, monitor, wrap | Every session |
| **[buffer-optimizer](./buffer-optimizer/)** | Workspace audit — measure, diagnose, fix | Periodically |

**Buffer** runs your sessions. It recovers context on cold start, monitors context window health during work, and writes structured handoffs at session end so the next session picks up exactly where you left off.

**Buffer-optimizer** tunes your setup. It audits boot payload, checks AGENTS.md structure, classifies skills by usage, validates memory files, and drafts fixes. Run it when things feel off, after major changes, or every week or two.

## Install

From [ClawhHub](https://clawhub.ai):

```bash
clawhub install buffer
clawhub install buffer-optimizer
```

Or clone this repo and copy the skill directories into your workspace:

```bash
git clone https://github.com/cortex-sdk/buffer.git
cp -r buffer/buffer ~/.openclaw/workspace/skills/
cp -r buffer/buffer-optimizer ~/.openclaw/workspace/skills/
```

Then start a new OpenClaw session so it picks up the skills.

## How It Works

### The Session Lifecycle

```
[New Session]
    ↓
buffer (Start) → Read HANDOFF.md → Read MEMORY.md → Orient
    ↓
buffer (Monitor) → Intake discipline, output management, threshold checks
    ↓
buffer (Wrap) → Extract outcomes → Write HANDOFF.md → Update MEMORY.md if needed
    ↓
[Session Ends]
    ↓
[Next Session] → buffer (Start) reads what buffer (Wrap) wrote
```

### Context Thresholds

Buffer uses percentage-based thresholds that work across any model and context window size:

| Zone | Usage | Action |
|---|---|---|
| 🟢 Green | <25% | Full performance |
| 🟡 Yellow | 25-40% | Intentional loading |
| 🟠 Orange | 40-50% | Warn owner, prepare to wrap |
| 🔴 Red | >50% | Wrap immediately |

Thresholds are based on research into context window performance degradation. See the [buffer docs](./buffer/README.md#context-thresholds) for the full research backing.

### The HANDOFF.md Bridge

Every wrap produces a structured HANDOFF.md that the next session reads on startup:

```markdown
# HANDOFF.md

## Current Work
[What you were focused on.]

## Stopping Point
[Where you left off.]

## Key Outcomes
- [Conclusions, not activities.]

## Open Questions
- [Unresolved items — each actionable.]

## Next Steps
1. [Most important first.]
```

## Requirements

- OpenClaw with workspace file support
- File system + shell access
- No external dependencies

## Documentation

- [Buffer — full docs](./buffer/README.md)
- [Buffer Optimizer — full docs](./buffer-optimizer/README.md)

## Research

Buffer's thresholds and degradation detection are informed by:

- [Context Rot — Chroma Research](https://research.trychroma.com/context-rot) (July 2025)
- [How Long Contexts Fail — Drew Breunig](https://www.dbreunig.com/2025/06/22/how-contexts-fail-and-how-to-fix-them.html) (June 2025)

## License

MIT
