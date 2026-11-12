---
name: orchestrate
description: Trigger this if the user says 'orchestrate', or asks you to coordinate subagents instead of doing the implementation yourself.
---

# Orchestrate

You are the orchestrator, not the implementer. Plan the work, hand it to
delegates, check what they return, and integrate it. Do not write the
implementation yourself, even when it would be faster. The point is to keep
your context on the whole task, not on file contents.

You do these yourself:

- Read enough code and docs to split the work and write good briefs. Hand
  broad searches to a read-only delegate and keep only the conclusion.
- Run checks, read diffs, and judge results.
- Handle git: branches, commits, merging delegate work.
- Trivial integration fixes, such as an import, a typo, or a one-line merge
  conflict. Anything larger goes back to a delegate.

## 1. Plan

Restate the goal in 1-2 sentences, with what is out of scope. Ask the user
only if ambiguity changes the result.

Split the work into tasks. Each task has one clear outcome and owns a set of
files. Note shared interfaces between tasks, such as types, function
signatures, or API shapes, and settle them before anyone starts. Mark which
tasks depend on others.

Use as few delegates as the work allows. A small change is one task. Do not
split work only to look parallel.

## 2. Brief

Delegates get no history. Each brief stands alone:

```
Repo: <abs path>  Branch/worktree: <where to work>
Goal: <one outcome>
You own: <files or dirs>. Do not edit anything else.
Contracts: <interfaces you must match or provide>
Context: <relevant files, conventions, prior findings>
Out of scope: <what not to do>
Checks: <commands to run before you report>
Do the work yourself. Do not start subagents. Do not commit or push unless
told. Report: what changed (file:line), check output, open questions.
```

## 3. Run

Start independent tasks in parallel, in one message. Start a dependent task
when what it needs has landed.

Delegates that run at the same time in one checkout must own disjoint files.
Otherwise give each its own worktree.

- T3 Code: follow its orchestration rules. Call `orchestrator_capabilities`
  once, then `delegate_task` per task. Use `isolation: "worktree"` for
  parallel work that would collide.
- Claude Code: the `Agent` tool, with `isolation: "worktree"` when needed.
- Codex: `spawn_agent` cannot run Opus. Use T3 Code's `delegate_task` or
  another route that runs Opus.

Use the latest Claude Opus for implementation tasks, unless the user names
another model. Do not hardcode a model ID. In T3 Code, resolve it with
`orchestrator_capabilities`. If Opus or a named model is unavailable, say so
instead of substituting.

## 4. Check each result

Do not wait idle, and do not poll. When a result arrives, check it at once
while others run:

- Read the actual diff, not only the report.
- Run the checks yourself.
- Revert edits outside the task's files, and extras the goal does not need.

If a result is wrong or incomplete, start a new delegate with the original
brief, the current diff, and your findings. Do not fix it yourself.

## 5. Integrate

Merge the work, resolve conflicts, and run the full checks on the combined
result. Verify the real behavior, not only mocked tests. If integration
breaks something, send a focused fix task to a delegate.

If the user asked for review, use `sol-loop` or `council` on the combined
diff. If the user asked for a PR, use `file-pr`.

## 6. Report

Report the tasks, who did each one, how you verified the result, what you
reverted or sent back, and what remains open.

Fight scope creep at every step. Delegates add things. Your job is to keep
the change to the goal.
