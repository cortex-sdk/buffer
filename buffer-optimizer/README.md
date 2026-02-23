# Buffer Optimizer

**Audit and optimize your OpenClaw workspace for session reliability and token efficiency. Companion to the [buffer](../buffer/) skill.**

## The Problem

OpenClaw agents accumulate configuration debt. AGENTS.md grows verbose. Memory files bloat with old transcripts. Skills pile up — 75 loaded when 15 are used. HANDOFF.md drifts from useful session bridge to activity log. Ghost files sit in the workspace root, containing instructions the agent never sees.

None of this breaks anything visibly. The agent still works. But each issue silently degrades performance:

- **Bloated boot payload** — more tokens loaded every session, higher cost, less room for actual work
- **Weak AGENTS.md structure** — skills get bypassed because trigger tables aren't positioned where the agent checks first
- **Verbose memory files** — the agent loads session transcripts instead of summaries, wasting context on history instead of current state
- **Ghost files** — instructions written in files the agent never reads, creating false confidence that rules are being followed

Buffer Optimizer detects all of these and drafts fixes.

## How It Works

Seven steps, run sequentially. The skill measures, diagnoses, then proposes — it never modifies files without owner approval.

### Step 1: Measure Boot Payload

Runs a shell script that measures every boot file (AGENTS.md, SOUL.md, USER.md, MEMORY.md, HANDOFF.md, IDENTITY.md), counts memory files, tallies loaded skills, and checks for ghost files. Reports sizes in bytes and estimated tokens.

**Thresholds:**

| File | Target | Why |
|---|---|---|
| AGENTS.md | ≤4KB | Behavioral rules. Every token here loads every turn. Descriptions and explanations should be in docs, not directives. |
| MEMORY.md | ≤1.5KB | Big-picture briefing. If it's over, it contains history or architecture that belongs elsewhere. |
| HANDOFF.md | ≤2KB | Session bridge. If it's over, it's logging activities instead of conclusions. |
| Total boot | ≤12KB | Everything the agent sees before the first message. More than this means something doesn't belong. |
| Skills loaded | <20 | Each skill in `<available_skills>` costs ~75 tokens in the system prompt. 75 skills = ~5,625 tokens of skill listings alone. |

### Step 2: Audit AGENTS.md Structure

AGENTS.md is the most important file in an OpenClaw workspace. It determines what the agent does on every turn. Buffer Optimizer checks five structural requirements:

**Skill triggers are the first section.**
Attention in long prompts is strongest at the beginning and end. Skill triggers determine what the agent does *right now* — they must be positioned where they fire before the agent starts forming a response. If rules or policies come first, the agent has already committed to an approach before it checks whether a skill handles the task.

**Pre-response checkpoint exists.**
Two questions the agent asks before every response:
1. Does this message match a skill trigger? → Load that skill.
2. Am I about to do something a skill already handles? → Use the skill.

Without this gate, skill usage depends on the agent remembering to check — which it won't do reliably when the skill list is buried in the middle of the system prompt.

**Negative triggers exist.**
Positive triggers say "when X happens, use skill Y." Negative triggers say "don't do X manually — skill Y handles that." They catch a different failure mode: the agent doing the right thing in the wrong way. Examples:
- Writing code in the main session → should use a coding agent skill
- Fetching URLs with web_fetch → should use a research skill
- Pasting file contents in chat → should use a file sharing skill

**All instructions are imperative.**
Descriptions ("You have access to...") waste tokens and don't drive behavior. Directives ("Use X when Y") are shorter and more reliable. The audit flags weak patterns like "consider," "try to," "if appropriate" and proposes imperative rewrites.

**Sections grouped by trigger, not topic.**
"During conversation," "Before building," "At wrap" groups instructions by *when they fire*. "Memory," "Tools," "Safety" groups by *what they're about*. Trigger-based organization means the agent finds relevant instructions when it needs them, not when it happens to scan the right topic section.

### Step 3: Audit Skills

Every skill in `<available_skills>` costs tokens in the system prompt whether the agent uses it or not. Buffer Optimizer classifies each skill by usage frequency:

- **DAILY** — used most sessions. Must be in the trigger table and daily driver list.
- **WEEKLY** — used regularly. Should be in the trigger table.
- **RARE** — occasional use. Keep loaded, no trigger needed.
- **NEVER** — never triggered. Candidate for exclusion.

The optimizer drafts a daily driver list (the skills the agent should always have in mind) and an exclusion list (skills that can be removed from the system prompt). At ~75 tokens per skill, excluding 50 unused skills saves ~3,750 tokens per session.

### Step 4: Audit Memory Files

**MEMORY.md** should contain only what matters *right now*: this week's summary, ranked priorities, project states (one line each), and key people. If it contains last month's history or architecture descriptions, that's bloat — it loads every session and takes up context that should be available for actual work.

**HANDOFF.md** should contain only what the next session needs: current work, stopping point, key outcomes, open questions, and next steps. The most common failure mode is the activity log — "we tested X, then we tried Y, then we built Z." The next session doesn't need the journey, it needs the destination. Outcomes should be conclusions ("X works because Y") not activities ("we tested X").

**memory/*.md files** — session transcripts over 2KB should be summarized. Files older than 3 days should be archived. Duplicates of MEMORY.md content should be removed.

**Ghost files** — any `.md` file in the workspace root that isn't in the recognized set (AGENTS.md, SOUL.md, USER.md, MEMORY.md, HANDOFF.md, IDENTITY.md) is a ghost file. OpenClaw doesn't auto-load it. Whatever instructions or content it contains, the agent never sees. Ghost files create a dangerous illusion: the owner thinks the agent follows rules in `GUIDE.md` or `SKILLS.md`, but the agent doesn't know those files exist unless explicitly told to read them.

### Step 5: Check Reliability

Three infrastructure checks:
- **Compaction flush** — does the system persist important context before compacting? If not, information can be lost silently.
- **Wrap ritual** — does a structured wrap procedure exist? Without one, session endings are ad hoc and state gets lost.
- **Automated persistence** — are there write hooks, observers, or auto-commit mechanisms? Without them, everything depends on the agent remembering to save.

### Step 6: Self-Tests

Three behavioral checks the agent runs on itself:
- **Recovery test** — does HANDOFF.md reflect the current state? If not, a crash right now would lose context.
- **Skill bypass test** — did the agent recently do manually what a skill handles? This catches the gap between "skills available" and "skills used."
- **Drift test** — is the agent actually following every instruction in AGENTS.md? Instructions that aren't followed are dead weight.

### Step 7: Report

Everything compiles into a structured report with pass/fail for each check and a prioritized list of proposed changes with token impact estimates. The owner reviews and approves before any changes are made.

## The Relationship Between Buffer and Buffer Optimizer

They're the same system at different timescales.

**Buffer** is runtime — it manages context within a session and bridges between sessions. It runs every session: start, monitor, wrap.

**Buffer Optimizer** is maintenance — it checks whether the workspace is configured to support good runtime behavior. It runs occasionally: when things feel off, after major changes, or on a regular schedule.

Buffer Optimizer validates what Buffer depends on:
- Buffer's Start mode reads HANDOFF.md → Optimizer checks that HANDOFF.md follows the right template
- Buffer's Monitor mode enforces context rules from AGENTS.md → Optimizer checks that those rules exist and are structured correctly
- Buffer's Wrap mode writes HANDOFF.md → Optimizer measures whether the output stays within size targets

The natural cadence: **Buffer every session, Buffer Optimizer every week or two.**

## Requirements

- OpenClaw with workspace file support
- File system + shell access (for measurement scripts)
- No external dependencies

## Installation

```bash
clawhub install buffer-optimizer
```

Or clone from the GitHub repo and copy `buffer-optimizer/` into your workspace `skills/` directory.

## Included Scripts

The skill includes two shell scripts in `scripts/`:

- **measure-boot.sh** — measures all boot files, counts skills, checks thresholds, finds ghost files
- **audit-agents-md.sh** — checks AGENTS.md structure: section ordering, checkpoint presence, negative triggers, weak patterns

Both scripts are called by the skill during the audit. They can also be run standalone for quick checks.
