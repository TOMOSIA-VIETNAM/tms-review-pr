# /tms:review-pr — Agent Review Pull Request Github

[Tiếng Việt](./README.md) · **English** · [日本語](./README.ja.md)

A plugin that teaches the Agent to review GitHub Pull Requests **consistently** — the more you use it, the better it understands your project.

The first time, it reads your existing conventions (README, CLAUDE.md, AGENTS.md, docs, wiki…). After that it always applies that repo's specific rules; type an extra rule in chat and it remembers it right away into the memory for that repo — close to the real conventions, light on generic rules.

What if a suggestion only lives on a PR comment? It asks you before remembering (to avoid injecting fake rules through a PR).

Project conventions don't stand still — on each `/tms:review-pr`, if it's due, the plugin re-reads the convention docs so memory doesn't go stale. Schedule details: [Convention refresh cycle](#convention-refresh-cycle).

## Prerequisites

- [Claude Code](https://claude.ai/code) installed
- [`gh`](https://cli.github.com/) logged in (`gh auth login`) — the plugin posts reviews through this account

## Install

Inside a Claude Code session:

```
/plugin marketplace add TOMOSIA-VIETNAM/tms-review-pr
/plugin install tms@review-pr
```

## Update to the latest

`plugin.json` declares no `version` (the project is under active development) — every new commit on `main` becomes a build of its own. Once installed, pull the latest:

```
/plugin marketplace update review-pr
/plugin update tms@review-pr
```

Then `/reload-plugins` (or open a new Claude Code session) to reload.

## How to use

The slash command **only runs when you type it** — Claude never calls `/tms:review-pr` on its own.

```
/tms:review-pr https://github.com/<owner>/<repo>/pull/<number>
```

URLs ending in `/files`, `/changes`, with query strings… all work — they just need to contain a valid PR link.

Add instructions right after the URL for **that run only** (does not change saved config), e.g.:

```
/tms:review-pr https://github.com/org/repo/pull/123 focus on security
```

**Works in parallel, no fear of clobbering branches.** On each review, the PR code is checked out into its own [git worktree](https://git-scm.com/docs/git-worktree) — it does not change the branch/working tree of the repo you're coding in. You can open multiple `/tms:review-pr` sessions (several PRs at once) while still committing/editing normally on your current branch.

## First time for a repo that's never been set up

The plugin asks **once** (4 questions):

1. Review **language** (vi / en / ja)
2. **Post the review now or keep it as a draft?** (`auto_submit_review`) — `true`: everyone sees it immediately; `false` (default): a draft on GitHub you Submit yourself
3. **Auto-close a thread when an old finding is fixed?** (`auto_resolve_fixed_findings`) — default `false`
4. **How often to re-scan project conventions?** — see [Convention refresh cycle](#convention-refresh-cycle) below (default every **1 month**)

After that it reads your existing convention docs and remembers them for later runs.

Remembered data lives inside the repo you're reviewing, at `notebooks/review/<repo-name>/` (its own local git, not pushed). Keep this directory in your project's `.gitignore` — the plugin adds it if missing.

## How it works (short)

```
/tms:review-pr <PR_URL>
        │
        ▼
Check out the PR code into its own worktree (won't touch the branch you're working on)
        │
        ▼
Review the changes, following:
  • general technical rules
  • the conventions / memory of this specific repo
        │
        ▼
Post 1 review: overview + line-by-line comments (when needed)
  • severity as emoji: 🔴 MUST FIX / 🟠 SHOULD FIX / 🔵 SUGGESTION / 📝 NOTE
  • clean PR → **LGTM 🌟**, no nitpicking
```

Supports many stacks: Rails, Vue, React, Python, Node.js, Lambda, PHP, Laravel, WordPress, Shell, Makefile (and extends itself when it meets a new stack).

**Review + comment only.** No closing/merging PRs, no branch switching, no editing code for you.

## Convention refresh cycle

Project conventions change over time. The plugin can **re-read them periodically** when you run `/tms:review-pr`, so memory doesn't go stale.

| You want | Put in `doctor_schedule` |
|----------|--------------------------|
| Every week | `"1 weeks"` or `"7 days"` |
| Every 2 weeks | `"2 weeks"` |
| Every month (default) | `"1 months"` |
| Every quarter | `"3 months"` |
| Never re-read automatically | `"never"` |

Edit it in `notebooks/review/<repo>/meta.json` — next to the field is a `_comments` line with a quick explanation. Want to re-read **now** (without waiting for the schedule): say **doctor again** / **re-scan conventions** in chat.

## Customize after you've used it

In a repo reviewed at least once:

| Want to change | Edit here |
|----------------|-----------|
| Default language | `notebooks/review/<repo>/ALWAYS_RULE.md` — the `Output language` block |
| Post now / draft, auto-resolve threads, convention re-read cycle | `notebooks/review/<repo>/meta.json` |
| Team-specific rules | `ALWAYS_RULE.md` under the extra-rules section, or say it in chat to record a lesson |
