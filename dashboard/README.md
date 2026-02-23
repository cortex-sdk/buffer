# Buffer Dashboard

A real-time session monitor for OpenClaw agents. Shows context window usage, live session activity, and educational guides for session management.

## What It Shows

### Left Column — Context Window

**The percentage and bar** show how much of the context window is being used. The bar scales from 0% to 50% (the operational cap) since sessions should wrap before reaching 50%.

**Zone badges** change based on usage:
- **HEALTHY** (green, under 25%) — full performance, no restrictions
- **CAUTION** (yellow, 25–40%) — be intentional about what gets loaded
- **DEGRADE** (orange, 40–50%) — complex reasoning starts to suffer
- **WRAP** (red, over 50%) — quality is compromised, wrap the session

**Model and duration** show which model is running and how long the session has been active.

**Nudge** — a contextual hint that appears when something needs attention, like high topic count or fast context growth.

### Right Column — Current Session

A live feed of what's happening in the session, updated by the agent as work progresses.

- **Main focus** — the primary topic for this session. Set automatically from HANDOFF.md at session start, updated if the session pivots.
- **Topics covered** — chronological list of everything discussed (gray bars)
- **Decisions** — choices made during the session (yellow bars)
- **Outcomes** — things completed (green bars)

This is the content that gets written to HANDOFF.md when the session wraps. You can see at any moment what would carry forward if the session ended.

### Buttons

**Session management tips** — opens a guide teaching six core principles: context as shared workspace, focused topics, what the zones mean, how to wrap, signs of degradation, and why wrapping is free.

**HANDOFF.md** — opens a modal showing the current contents of the handoff file. This is the bridge between sessions — what the last session left and what the next session will read.

**Session startup** — opens a modal showing everything that loads when a session begins: each workspace file with its purpose and size, skill count, memory files, and total token cost.

## How It Works

The dashboard is a lightweight Node.js server that reads OpenClaw files directly:

- **Context usage** — reads the JSONL session transcript to get actual token counts from the last API call
- **Session feed** — reads `scratch/live-session.json`, a file the agent maintains during the session
- **Boot payload** — measures workspace files on disk (AGENTS.md, SOUL.md, etc.)
- **HANDOFF.md** — reads the file directly

No database, no external APIs, no Cortex dependency. Works for any OpenClaw user.

The page auto-refreshes every 10 seconds.

## The Live Session File

The agent writes `scratch/live-session.json` during the session with this structure:

```json
{
  "focus": "What the session is about",
  "startedAt": "2026-02-23T20:31:00Z",
  "topics": [
    "First thing discussed",
    "Second thing discussed"
  ],
  "decisions": [
    "Choice that was made and why"
  ],
  "outcomes": [
    "Thing that was completed"
  ],
  "updatedAt": "2026-02-23T22:00:00Z"
}
```

The agent is responsible for keeping this current. At session start, it sets the focus from HANDOFF.md's "Current Work" or "Next Steps." As the session progresses, it adds topics, decisions, and outcomes. At wrap, this becomes the source material for the new HANDOFF.md.

If the live session file doesn't exist, the dashboard falls back to showing HANDOFF.md content.

## Setup

The dashboard runs as a launchd service on macOS:

**Server:** `~/.openclaw/workspace/tools/context-monitor-server.mjs`
**HTML:** `~/.openclaw/workspace/tools/context-monitor.html`
**LaunchAgent:** `~/Library/LaunchAgents/com.openclaw.context-monitor.plist`

Default port: 8111 (localhost only). Exposed externally via Tailscale Serve on port 8112.

### Starting the server

The launchd service starts automatically and restarts on crash. To manually restart:

```bash
# Kill and let launchd restart
pkill -f "context-monitor-server"

# Or kick launchd directly
launchctl kickstart -k gui/$(id -u)/com.openclaw.context-monitor
```

### Exposing via Tailscale

```bash
tailscale serve --bg 8112 http://127.0.0.1:8111
```

## Requirements

- Node.js
- OpenClaw with workspace file support
- No external dependencies

## Built by Sigma Labs
