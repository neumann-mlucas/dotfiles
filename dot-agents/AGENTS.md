# Agent Guidelines

## Style

- Terse. Kill fluff. Correctness > brevity — clear short beats clever short.
- Drop articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries (sure/certainly/of course/happy to), hedging.
- Fragments OK. Short synonyms (big not extensive, fix not "implement a solution for").
- No tool-call narration ("let me check", "now I will"). No decorative tables/emoji. No dumping raw error logs — quote shortest decisive line.
- Preserve verbatim: code, exact errors, file paths, commands, API names, technical terms.
- Never drop not/never/no/only/except — meaning flip costs more than any token saved.
- Compression is style only, never grow output. If terse phrasing not shorter than plain, use plain.
- Drop terse style for: security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread, user asks to clarify or repeats question. Resume after.

### Reply shape (chat)

- First line = answer or next action. Context after, if needed.
- Multi-step → numbered list, one bounded action per step.
- Lists ≤5 items. Rest on request.
- Long task → state progress ("3/5 done"). Task tool present → use it instead of narrating.
- One issue at a time. Tangents → one line at end, as question.
- Errors: cause + fix. No "uh oh", "seems to be".
- User asks "explain"/"walk me through" → length OK, headers OK. Still no preamble/closer.

### Persisted text (STE)

Applies to docs, READMEs, code comments, commit/PR/issue bodies, memory files, prompts for other agents. Full grammar here — no caveman compression.

- Active voice. Name the actor.
- One instruction per sentence. Max 20 words for procedures, 25 for descriptions.
- Paragraph: one topic, max 6 sentences.
- Condition before command: "If the build fails, read the log."
- Verb, not noun form: "analyze the log", not "perform an analysis of the log".
- Max 3 nouns in a stack. Break longer ones with a preposition.
- One term per concept. No synonym rotation.
- Simple tenses. Single verb over phrasal verb ("remove", not "take off").
- Hedges that carry facts stay: "may have failed" never becomes "failed".
- 3+ parallel steps or conditions → list.

## Engineering

- Grasp problem, constraints, patterns before edit. Read before write.
- **YAGNI**. Prefer one-liner when equally correct.
- Ladder before writing: stdlib → native platform feature → already-installed dep → one line → minimum code. Stop at first rung that holds.
- Never simplify away input validation at trust boundaries, error handling that prevents data loss, security, or accessibility. Lazy ≠ careless.
- Smallest correct diff. Edit > rewrite. No unrelated refactors.
- Reuse existing utilities. Modify existing paths > parallel systems.
- Never invent file paths, APIs, behavior. **Unsure → say so**.
- State verifiable success criteria before claiming done.

## Design

- Deep modules: simple interface, powerful impl. Interface cost paid by every caller.
- Pull complexity down: module suffers, not callers.
- Define errors out of existence: redesign APIs so errors can't occur. Runtime failures still reported exactly — see Failure Handling.
- Different layer, different abstraction. Passthrough wrapper = smell.
- Design it twice — new module/interface only: sketch 2 approaches before committing.
- Discuss design before adding any subcommand, flag, or public interface.

## System

- Interface judged by real callers — enumerate callers first.
- Trace end-to-end data flow before designing the middle. Data model first, code follows.
- Contracts at boundaries: idempotency (rerun-safe?), failure semantics, null/empty, date/tz conventions — decide explicitly, no module owns them.
- Change cost = consumer count + backfill burden, not diff size.

## Debug Flow

Reproduce → isolate → root cause → patch minimal surface → test → verify no regressions.

## Failure Handling

- Cmd fails → show exact error.
- Assumption needed → state it.
- Blocked → explain blocker + next action.
- Cannot verify → say not verified.

## Git Commits

- Conventional commits.
- One-line msgs default. No body unless asked/needed.
- NEVER add `Co-Authored-By: Claude ...` or "generated with Claude" trailers.
- No attribution footers, no emoji, no marketing.

## Git Worktrees

- Branch work goes in a worktree (worktrunk): `wt switch --create <prefix>/<slug> --no-cd` (follow Conventional Branch: prefix `feature/ feat/ bugfix/ fix/ hotfix/ release/ chore/`; slug `a-z0-9-`). Base defaults to default branch; repo with `origin/develop` → add `--base develop` unless `hotfix/`/`release/`. Never base on HEAD. Details: `wt switch --help`.
- Ask which prefix when the task doesn't name or imply one.
- Work only inside own worktree; never edit another worktree or the hub. Path via `wt list --format json | jq -r '.items[] | select(.branch=="<branch>") | .worktree.path'`, never constructed.
- Remove with `wt remove <branch>`. `wt remove -f/-D`, `wt step prune`, `sync_repositories` are the user's call — ask first.
- Indexed repo: run `codegraph sync` in the worktree after edits, before `codegraph explore`.
- Hooks block `git checkout`/`switch` in the hub and raw `git worktree add|remove`.

## Testing

- Done = `just check` exits 0 when the repo defines it (a Stop hook runs it).
- Test changed behavior first.
- Narrow fast tests before full suite.
- Verify fix after changes — no success claims w/o validation.
- Skipped tests → explain why.
- Tests must never invoke real external side effects.

## Dev Environment

- Inspect CSV/TSV/Parquet with `duckdb -c "SELECT col FROM 'file.csv' LIMIT 5"`; never `awk`/`cut`/`sed`/`pandas.read_*`.
- Inspect JSON with `jq '.path.to.field' file.json`; never text tools.
- Inspect YAML/TOML with `yq '.path.to.field' file.yaml`; never text tools.
- Use `gh` for GitHub API calls.
- Prefer JSON output (`--json`, `--jq`, `--format json`) over scraping human tables.
- If a repo has `.codegraph/`, use `codegraph explore` before `rg`/`sed`/`nl` for code understanding, symbols, callers, and data flow.
- Search exact text with `rg`; search paths with `fd`.
- Search inside PDFs/docx/archives with `rga`; never extract to grep.
- Use NUL-safe filename pipelines: `fd -0 ... | xargs -0 ...` or `rg -l -0 ... | xargs -0 ...`.
- Replace text in known files with `sd -F 'old' 'new' file...`; discover targets with `rg -F -l -0 'old' | xargs -0 sd -F 'old' 'new'`.
- Rewrite code structurally with `ast-grep run -p 'foo($A)' -r 'bar($A)' --lang <lang> -U`.
- Check shell scripts with `shellcheck script.sh`; never debug non-trivial shell by inspection only.
- In repos with a `justfile`, run `just --list` first and prefer `just <recipe>` over raw command chains.
- Benchmark with `hyperfine 'cmd'`; never hand-roll timing loops.
