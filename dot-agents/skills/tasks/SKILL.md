---
name: tasks
description: Personal task manager and secretary on Taskwarrior 3. Use when the user mentions a todo, task, reminder, errand, call, deadline, "remind me", "add to my list", "what's on my plate", "what next", planning a week, a weekly review, or handing off unfinished work to a later session. Covers work, personal projects, and errands in one database.
---

# Tasks

Taskwarrior (`task`) is the single task store for work, personal projects, and errands. This skill sets the house conventions and the safe command form. For syntax beyond this page, run `man task` or `man taskrc`.

## Command form

Always call `task` with these overrides:

```bash
task rc.confirmation=off rc.verbose=new-uuid rc.context=none <filter> <command> <mods>
```

- `rc.context=none` stops the user's active context from filtering or tagging the agent's commands. Write the scope into the filter instead.
- `rc.confirmation=off` prevents prompts that hang a non-interactive shell.
- `rc.verbose=new-uuid` prints the UUID of each new task. Keep that UUID for later commands.

Rules:

- Read with `export` and parse with `jq`. Never parse report tables.
- Write to one task at a time, by UUID. Never use the short ID: it changes when other tasks change.
- Never run `task edit`. It opens an editor. Use `modify`, `annotate`, or `denotate`.
- Never run `task config`, `context`, `sync`, `import`, `purge`, or `undo` unless the user asks for that exact action.
- If a write touches 3 or more tasks, Taskwarrior asks for confirmation (`bulk=3`). Do not override `bulk`. Show the user the list and ask first.
- After a write, confirm it with `task <uuid> export`. Report what changed in one line, not the JSON.

## Conventions

| Field | Use |
|---|---|
| `project:work.<client>` | Paid work. The `work` context shows only this tree. |
| `project:dev.<repo>` | Personal code projects. |
| `project:home` | Household, admin, health, money. |
| `+in` | Captured, not triaged. Every task the agent adds without a clear project gets `+in`. |
| `+errand` | Must be done while out (shop, post office). |
| `+call` | A phone call or a message to send. |
| `+waiting` | Blocked on another person. Annotate who and since when. |
| `+next` | The user picked it for today. Add it only when the user asks. |
| `repo:<absolute path>` | The checkout a code task belongs to. |
| `due:` | Real deadlines only: a date with a cost if missed. |
| `scheduled:` | The earliest date to start. |
| `wait:` | Hide the task until that date. |
| `recur:` | Repeats (`recur:monthly due:1st`). Always set `due`. |
| `depends:<uuid>` | This task cannot start before the other is done. |

Never invent a deadline. If the user gives none, leave `due` empty.

## Workflows

### Capture

When the user mentions something to do, add it in the same turn:

```bash
task rc.confirmation=off rc.verbose=new-uuid rc.context=none add "Renew passport" project:home due:2026-12-15
```

- Write the description as a verb phrase: "Call dentist about crown", not "dentist".
- Add only the attributes the user stated or clearly implied. If the project is unclear, add `+in`.
- Confirm with one line: what, where, and when.

### What next

```bash
task rc.context=none rc.verbose=nothing status:pending +READY export \
  | jq -r 'sort_by(-.urgency) | .[:5][] | "\(.urgency|floor) \(.project // "-") \(.description)"'
```

- `+READY` excludes waiting, blocked, and future-scheduled tasks.
- Add a scope to the filter when the user names one: `project:work`, `project.not:work`, `+errand`.
- Show at most 5 tasks. Lead with overdue and due-today items.

### Errands

If the user is going out or asks what to do in town, list `+errand` and `+call` tasks that are `+READY`. Group them by place when the descriptions name one.

### Weekly review

Run the steps in this order and ask for a decision on each item. Never make the decision yourself.

1. Inbox: `+in`. For each task, set a project, set dates, or delete it.
2. Overdue: `+OVERDUE`. For each task, do it, give it a new date, or drop it.
3. Waiting: `+waiting`. Suggest a follow-up for items older than 7 days.
4. Stale: `status:pending modified.before:now-30d`. Ask if each task is still relevant.
5. Next week: `due.before:now+8d`. Show the list.

### Handoff for code work

When a coding session stops with work unfinished:

1. Find the task: `project:dev.<repo>` or `repo:<path>`. If there is no task, create one.
2. Run `start` on the task when work begins, and `stop` when the session ends.
3. Before stopping, annotate the state: `annotate "handoff: <done>; next: <step>; branch: <name>"`.
4. Split work that remains into tasks with `depends:` where order matters.

A new session reads the handoff with `task <uuid> export | jq -r '.[0].annotations[]?.description'`.

## Limits

- Taskwarrior does not send reminders. If the user asks to be reminded at a time, add the task with `due:`, and say that no alert fires.
- No calendar. Meetings and appointments belong in the user's calendar. A task can point to them.
- Tasks are local. They do not appear in git or PRs.
