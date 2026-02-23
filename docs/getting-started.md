# Getting Started

## Install

**Option A — ClawhHub:**
```bash
clawhub install buffer
```

**Option B — Clone from GitHub:**
```bash
git clone https://github.com/sigmalabs-ai/buffer.git
cp -r buffer/buffer ~/.openclaw/workspace/skills/
```

Both methods install the `buffer` skill into your workspace. That's the only thing you need.

## First Run

Tell your agent to run Buffer. Here's what happens:

1. **Buffer checks for its companion skill** (`buffer-optimizer`). If it's not installed, Buffer extracts it automatically into your skills directory. This is a one-time setup — future sessions skip this step.

2. **Buffer sets up your workspace.** It creates `HANDOFF.md` if you don't have one, validates your `MEMORY.md`, and checks that your `AGENTS.md` has the right structure for reliable skill execution.

3. **Buffer reports what it did.** You'll see what was created, what was validated, and whether anything needs your attention.

After first run, Buffer switches to its normal session lifecycle: recover context, monitor the session, wrap when it's time.

## What You Need

- **OpenClaw** with workspace file support
- **File system + shell access** (for measurement scripts during audits)
- No external dependencies, no API keys, no database
- Works with any model and any context window size

## What Gets Created

Buffer manages three files in your workspace:

| File | Purpose | Created by |
|---|---|---|
| `HANDOFF.md` | Session bridge — what the next session needs to know | Buffer (every wrap) |
| `MEMORY.md` | Big picture — priorities, projects, people | Buffer (when structure changes) |
| `AGENTS.md` | Agent behavior rules — skill triggers, context rules | Buffer Optimizer (setup only) |

Buffer never overwrites your existing files without telling you first. If `MEMORY.md` or `AGENTS.md` already exist, Buffer validates them and suggests improvements — it doesn't replace them.

## After Setup

Once Buffer is running, you don't need to think about it. It works automatically:

- **Session start:** Reads `HANDOFF.md` and `MEMORY.md` to recover where you left off
- **During work:** Monitors context usage, enforces intake discipline, watches for degradation
- **Session end:** Extracts outcomes, writes a structured handoff, updates memory if needed

The agent manages all of this. Your only interaction is the occasional "wrap session" command when you're done working — and Buffer will prompt you to wrap if context gets high enough.

## Running an Audit

Buffer Optimizer runs separately from the main Buffer skill. Ask your agent to run an audit when:

- Things feel off — the agent seems to forget context or ignore skills
- You've made major changes to your workspace
- It's been a week or two since the last check

The audit measures your boot payload, checks your AGENTS.md structure, classifies your skills by usage, validates memory files, and produces a report with specific recommendations. Nothing changes until you approve it.

## Troubleshooting

**Skills aren't firing:**
Check your AGENTS.md structure. The pre-response checkpoint must be the first section, with the skill trigger table immediately after. If triggers are buried below rules and policies, the agent commits to an approach before checking whether a skill handles the task. Run `buffer-optimizer` to audit the structure.

**Handoffs feel thin or unhelpful:**
Check whether outcomes are conclusions or activity logs. "We tested X, then tried Y" forces the next session to re-derive what happened. "X works because Y" lets it build immediately. If HANDOFF.md reads like a journal, the wrap step isn't compressing enough.

**Context growing too fast:**
Check intake discipline. Common culprits: re-reading files that haven't changed, loading full files when a targeted read would do, keeping large tool outputs in context instead of redirecting to `/tmp`. Run an audit — `buffer-optimizer` measures your boot payload and flags bloat.

**Agent doesn't seem to know what happened last session:**
Check that HANDOFF.md exists and has content. If it's empty or missing, the previous session didn't wrap properly. Also check that the agent's startup procedure reads HANDOFF.md — Buffer's Start mode handles this, but the skill needs to be loaded.

**Audit reports look wrong:**
The measurement scripts use the `OPENCLAW_WORKSPACE` environment variable, defaulting to `~/.openclaw/workspace`. If your workspace is elsewhere, set this variable before running audits.

## Uninstall

Remove the skill directories:
```bash
rm -rf ~/.openclaw/workspace/skills/buffer
rm -rf ~/.openclaw/workspace/skills/buffer-optimizer
```

Buffer doesn't modify any system files. The workspace files it creates (`HANDOFF.md`, any `MEMORY.md` improvements) are standard OpenClaw files that work fine without Buffer installed.
