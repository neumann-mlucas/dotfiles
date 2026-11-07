---
name: shell-guidelines
description: Bash/POSIX shell scripting guidelines — script skeleton (set -Eeuo pipefail, traps, mktemp), arg parsing, env-vars-vs-flags, when shell should become Python/Go, injection safety, macOS-BSD vs Linux-GNU portability, CLI UX for human AND agent callers (TTY detection, JSON errors, exit codes), shellcheck. Trigger on "write a shell script", "bash script", "shellcheck this", "shell script best practices", "os agnostic script", "cli args vs env vars", or any .sh/.bash file work.
---

# Shell Scripting Guidelines

## Script skeleton

Canonical start: copy this whole, adapt `usage`/flags/`main`, don't rebuild it rule-by-rule.

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
PROG=$(basename "$0")
readonly PROG

# cleanup + signals — see "Signal handling"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
trap 'echo "$PROG: failed at line $LINENO" >&2' ERR
trap 'echo "$PROG: interrupted" >&2; exit 130' INT
trap 'echo "$PROG: terminated" >&2; exit 143' TERM

# output mode — see "CLI UX": human on a TTY, JSON/plain when piped
json=false
[[ -t 1 ]] || json=true

usage() {
  cat <<EOF
usage: $PROG [-v|--verbose] [--json] <target>

  -v, --verbose   verbose output
      --json      force JSON output (default when stdout isn't a TTY)
  -h, --help      show this help
EOF
}

# arg parsing — see "Argument parsing" for the getopts-only alternative
verbose=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -v | --verbose) verbose=true; shift ;;
    --json) json=true; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "$PROG: unknown flag: $1" >&2; usage >&2; exit 2 ;;
    *) break ;;
  esac
done

main() {
  local target="${1:?usage: $PROG <target>}"
  : # ... implementation goes here, using $target/$verbose/$json ...
}

main "$@"
```

`shellcheck` flags `verbose`/`json`/`target` as SC2034 here because `main()` is a stub. It clears once `main()` uses them; don't silence it in the template.

- Shebang: `#!/usr/bin/env bash` by default. Need POSIX `sh` portability (no arrays, no `[[`, no `local` guarantees) → `#!/bin/sh`, lint with `shellcheck -s sh`, avoid bashisms.
- **macOS gotcha**: `/bin/bash` is stuck at 3.2 (no `${var,,}`, no `wait -n`, weak associative arrays). `#!/usr/bin/env bash` may find Homebrew bash interactively, but cron/launchd/CI often hit `/bin/bash`. If Bash ≥4 is required, check `${BASH_VERSINFO[0]}` or use a known absolute bash.
- `set -Eeuo pipefail` — `-e` exits on errors, `-u` errors on unset vars, `pipefail` propagates pipe failures, `-E` lets `ERR` traps fire in functions/subshells/command substitutions. Still handle commands expected to fail (`cmd || true`, explicit `if`).
- `IFS=$'\n\t'` avoids word-splitting on spaces in filenames/args. Skip only if you deliberately rely on default IFS splitting.
- Quote every expansion — `"$var"`, `"${arr[@]}"`. Bare `$var` is shellcheck SC2086.
- `$(cmd)` for command substitution, never backticks — nests cleanly, shellcheck SC2006 flags backticks.
- Constants set once → `readonly NAME=value` (or `declare -r`) right after assignment. Catches accidental reassignment at parse time instead of silently clobbering.
- Functions: `local` every var declared inside. No global mutation from a function unless intentional and documented.
- `main "$@"` at the bottom — script stays sourceable/testable without top-level side effects.

## Signal handling

The skeleton above wires all three; the rules for _why_:

- `EXIT` — cleanup that must always run (temp files, locks). Fires on normal exit, `exit N`, and uncaught errors under `set -e`.
- `INT`/`TERM` — only needed as a separate trap if a long-running/interactive script wants a different message or partial-result handling on Ctrl-C vs. a clean finish. `EXIT` still fires after, so don't duplicate cleanup in both.
- `ERR` — needs `set -E` (already in the skeleton) to reach into functions/subshells/command substitutions; without it the trap silently no-ops there.

## Argument parsing

The skeleton's `while [[ $# -gt 0 ]]; case $1 in ... esac` loop is the default: short + long flags, same shape everywhere. Use something else only when:

- **Flags are short-only** (`-v`, `-o file`, no `--long` forms ever) → builtin `getopts` (`while getopts ":o:v" opt; do case $opt in ... esac; done`) is less code and also runs under POSIX `sh`, not just bash.
- **Need GNU-style long-option parsing off the shelf** → `getopt -o ... -l ...` exists, but macOS ships BSD `getopt` with no long-option support at all — don't depend on it unless GNU getopt is confirmed on `$PATH`. The hand-rolled loop avoids this trap entirely, which is why it's the default.
- Unknown flag or missing required arg → exit `2` with usage to stderr (the skeleton does this), not a silent fallthrough.

## Design decisions

### Env vars vs CLI args

Rule: **flags for per-run choices, env vars for ambient session config, secrets never as args.** Same spirit as [12-factor config](https://12factor.net/config): config should not be hardcoded, committed, or require code changes.

- A value chosen each run (which table, which file, `--json`) → CLI flag/arg. It is in `--help`, shell history, and easy for an agent to vary.
- A value reused across many calls (target DB, `--env dev|prod`, base URL) → env var, with a flag override. Common split: secret in env (`API_TOKEN`), variable target as flag (`--env dev|prod`).
- Secrets/tokens/passwords → env var or a file path, **never** a CLI arg. Args are visible in `ps aux`, `/proc/*/cmdline`, and shell history; env vars set via `export` in a parent shell aren't (though still visible to anything reading `/proc/*/environ` on Linux — a secrets manager, not a bare env var, is the real fix, but it's still strictly better than an arg).
- Precedence when both exist: flag > env var > config file > built-in default. Document that order once, don't make the caller guess.
- Don't invent an env var when a flag works: env vars are invisible to `--help`, harder to test, and leak to child processes. Secrets are the exception: env var or `--token-file PATH`, never `--token VALUE`.

### Argument granularity

- One flag = one concern, no dual-purpose flags whose meaning changes with value type (sometimes a bool, sometimes a string) — shellcheck won't catch that ambiguity, humans and agents both will misuse it.
- Mutually exclusive states → one flag with an enum value (`--format json|csv|table`), not N booleans (`--json --csv` both set is now a bug you have to detect). Independent toggles (`--verbose`, `--dry-run`, `--no-color`) → separate booleans, they compose freely.
- The 1-2 required "what am I operating on" values → positional args (`tool describe table mydb mytable`). Everything optional or modifying behavior → flags. Don't make a required value a flag (`--table=x` when there's only ever one table arg) or an optional modifier positional (ordering becomes a hazard).
- Always give a long form (`--verbose`) even when there's a short one (`-v`) — short-only flags aren't memorable or greppable in a script, and an agent reading `--help` output pattern-matches long names far more reliably.
- Repeated values → a repeatable flag (`--filter x --filter y`), not a comma-joined string (`--filter x,y`). Repeatable composes with `xargs`/loops and needs no custom splitting logic on either side.

### CLI shape — flags-only vs subcommands

- Script does one job → flags only, no subcommands. Don't add `verb noun` structure for something that only ever does one verb.
- Tool does several distinct operations on related nouns (describe/list/sample) → verb-noun subcommands (`tool describe table`, `tool list schemas`), and document the whole tree in one place (a "command tree" block in the README/help) rather than scattering it across `--help` output only.
- Keep flag names consistent across every subcommand — `--json`, `--quiet`, `-v` should mean the same thing everywhere in the tool, not shift meaning subcommand to subcommand. An agent (or you, in six months) is pattern-matching flags across calls, not re-reading `--help` every time.

### How big should a script get?

- Shell is glue: orchestrate programs, move data, branch on exit codes. It has weak data structures, weak error handling, and weak test tooling.
- Rough ceiling: one file, one job, about 100-150 lines. If you need nested data, heavy string parsing, or unit-tested business logic, write Python or Go.
- Prefer `xargs -P` for simple parallel work. Move to Python/Go when you need queues, retries, shared state, or structured results.
- If several scripts share logic, source a small `lib.sh` rather than copy-pasting functions — but only once there are actually two callers, not preemptively.

### OS portability — macOS (BSD) vs Linux (GNU)

macOS ships BSD userland; Linux ships GNU coreutils. Same command, different flags, sometimes silent wrong behavior. Many macOS machines lack GNU coreutils; `sed`/`date`/`stat`/`readlink` are BSD unless GNU variants are installed as `gsed`, `gdate`, etc.

| Command              | BSD (macOS default)                       | GNU (Linux default)                   | Portable fix                                                                            |
| -------------------- | ----------------------------------------- | ------------------------------------- | --------------------------------------------------------------------------------------- |
| `sed -i`             | requires `-i ''` (empty arg mandatory)    | `-i` alone works, `-i.bak` for backup | use `sd` instead (same flags everywhere) — already the standing recommendation          |
| `date`               | `-v-1d` for "yesterday", `-j -f` to parse | `-d "1 day ago"` (GNU extension)      | avoid date arithmetic in shell; do it in `duckdb`/a real language, or branch on `uname` |
| `stat`               | `stat -f %z file` (size)                  | `stat -c %s file` (size)              | avoid `stat`; use `wc -c < file` for size where possible                                |
| `readlink -f`        | not supported on stock BSD readlink       | resolves symlinks                     | `realpath` is present on both macOS (since Big Sur) and Linux — use it instead          |
| `grep -P` (PCRE)     | unsupported                               | supported                             | use `rg` — identical flags on both platforms                                            |
| `timeout`            | not installed by default                  | ships in coreutils                    | no portable one-liner; skip it or gate behind `command -v timeout`                      |
| `md5sum`/`sha256sum` | `md5`/`shasum -a 256`                     | `md5sum`/`sha256sum`                  | branch on `uname`, or use a portable tool if hashing matters                            |

The recommended tools (`rg`, `fd`, `jq`, `yq`, `sd`, `duckdb`, `ast-grep`) have stable macOS/Linux flags, which is another reason to prefer them over raw coreutils. If no portable equivalent exists, branch explicitly:

```bash
case "$(uname -s)" in
  Darwin) : ;;  # ... macOS-specific command ...
  Linux)  : ;;  # ... Linux-specific command ...
  *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
```

`shellcheck` does not catch BSD-vs-GNU flag mismatches — it checks shell syntax, not the target platform's coreutils. If you claim a script is portable, actually run it on both, don't just assume.

## Security

- Never `eval` on anything derived from user input, a file, or an API response — that's arbitrary code execution, not a shortcut.
- Building a command from external input (a filename, an argument) → keep it as an array (`cmd=(prog "$arg")`; `"${cmd[@]}"`) instead of a single interpolated string; a string gets word-split and glob-expanded, an array element doesn't.
- Never parse `ls` output — filenames can contain spaces, newlines, glob chars. Use a glob (`for f in ./*.csv`) or `find ... -print0 | xargs -0 ...` for filenames that might contain anything.
- Never `for f in $(...)`; command substitution splits on whitespace. Use NUL pipelines: `fd -0 ... | while IFS= read -r -d '' f; do ...; done`.
- Prefer `printf '%s\n' "$var"` over `echo "$var"` when the content isn't a fixed literal — `echo`'s handling of `-n`/`-e`/backslashes differs across bash/dash/zsh; `printf` is consistent.

## Temp files

- `mktemp -d` for dirs, `mktemp` for files. Never hardcode `/tmp/foo` — collision risk, no cleanup, race condition. Pair with the `EXIT` trap in the skeleton, set immediately after creation so cleanup runs on error paths too, not just the happy exit.
- Inside an agent session with a provided scratchpad path, prefer that over `/tmp`.

## Linting

- `shellcheck script.sh` before calling anything done. Fix every warning or justify inline: `# shellcheck disable=SC2086  # word-splitting intentional here` — the directive needs its own line or a `#`-separated trailing comment; `--` after the code (`disable=SC2086 -- reason`) is invalid directive syntax and shellcheck will error on it. No blanket disables.
- Wire `shellcheck` into pre-commit/`prek` so it runs on every commit rather than relying on someone remembering to run it by hand — pair with `check-executables-have-shebangs`/`check-shebang-scripts-are-executable` from `pre-commit-hooks` (catches a script missing its shebang or its `chmod +x`). Run `prek run --files <script>` locally before committing, don't wait on the hook to find out.
- `shfmt` for formatting.

## CLI UX — design for human AND agent callers

A shell script's callers include humans and agents piping output through `jq` and branching on exit codes. Follow [clig.dev](https://clig.dev/) for human CLI shape, plus agent-facing contracts: compact actions, concise feedback, machine-readable errors, and guardrails against error propagation.

- **`--help`/`-h`** always works. Missing required arg → short usage + "see --help", never a raw stack trace/`set -x` dump.
- **TTY-detect output format instead of requiring a flag**: `[[ -t 1 ]]` → human formatting (color, tables) on a real terminal; non-TTY (piped) → plain text or `--json` automatically. Still accept explicit `--json` / `--no-color` to force either mode.
- **stdout = data only.** Logs, warnings, progress go to stderr. Never interleave.
- **Exit codes are a contract, keep them consistent and documented in `--help`**: `0` ok, `1` real failure (don't blind-retry), `2` usage/not-found (fixable — caller can correct and retry), `130` on SIGINT.
- **Machine-parseable errors when not on a TTY**: emit a small JSON envelope on stderr, matched to the exit code, so a caller does `jq -r .code` instead of regexing prose:

  ```bash
  die() {
    local code=$1 msg=$2
    if $json; then
      printf '{"error": %s, "code": "%s"}\n' "$(jq -Rn --arg m "$msg" '$m')" "$code" >&2
    else
      echo "$PROG: $msg" >&2
    fi
    case $code in
      usage) exit 2 ;;
      not_found) exit 2 ;;
      *) exit 1 ;;
    esac
  }
  # die usage "missing required <target>"
  ```

- **"Not found" → suggest, don't just fail**: fuzzy/substring-match the bad input against valid values and return ranked `suggestions` in the error payload; an agent should retry the top suggestion, not have to ask the user.
- **Confirmation prompts only fire when `[[ -t 0 ]]`** (stdin is a TTY). Piped/scripted runs must never block — always provide `--yes`/`--force`/`--no-input`. For destructive ops, require typing the resource name back, not a bare y/n.
- **`--dry-run`** for anything destructive or with side effects.
- **Idempotent where the operation allows it** — safe to rerun beats "surprising on retry."
- Shell may call `curl`, but API parsing means `jq`; multi-step API clients should become Python/Go.
- **Token economy: cap enumerable output by default.** `list`/`search`/`fetch` commands need a default cap plus `--limit`/`-n`; large logs/files should keep the tail under a byte/line cap because errors live at the bottom.
- **Truncation must steer, not just clip.** When output is capped, say so machine-visibly (`"truncated": true` in JSON, not a stderr-only warning), give the total if known (`"total_entries"`), and suggest the narrowing option (`--limit`, a filter flag). An agent that can't tell "12 rows returned" from "table has exactly 12 rows" will confidently report a wrong answer.
- **Ship `schema` or `--describe` for non-trivial flag surfaces**, emitting the command tree as JSON: subcommands, flags, positional enums. `--help` is prose; schemas avoid scrape/retry loops.
- **One flag spelling per concept across an entire tool family**, not `--max-rows` on one command and `--max-results` on another. An agent guesses flags from priors learned on other tools in the same family; spelling drift turns a would-be first-try success into an error → discovery-call → retry loop.

## Interactive prompts

- Picking from a list → `fzf`, not a hand-rolled `select`/numbered-menu loop. `select` is fine only for a trivial 2-3 option case where pulling in fzf is overkill.
- Secret input → `read -rs`, never echoed.

## Prefer existing tools over hand-rolled parsing

| Need                               | Use                             | Not                               |
| ---------------------------------- | ------------------------------- | --------------------------------- |
| CSV/TSV/Parquet query              | `duckdb -c "SELECT ..."`        | `awk`/`cut` field-splitting       |
| JSON field extraction              | `jq`                            | `grep`/`sed` on JSON              |
| YAML/TOML field extraction         | `yq` (mikefarah; Arch `go-yq`)  | `grep`/`sed`                      |
| Interactive picker                 | `fzf`                           | hand-rolled menu loop             |
| Literal/regex replace across files | `sd -F 'x' 'y' file...`; discover with `rg -F -l -0 'x' \| xargs -0 sd -F 'x' 'y'` | `sed -i` |
| Structural code rewrite            | `ast-grep`                      | multi-line `sed`/regex            |
| Code/text search                   | `rg`                            | `grep -r`                         |
| File search                        | `fd`                            | `find`                            |

Check `command -v <tool>` before depending on non-core tools; fall back and say so if one is missing.

## Testing

- No shell test framework (`bats`) assumed installed. For non-trivial logic (arg parsing, a loop, a destructive/money path) leave one runnable self-check — a `--self-test` branch or small function of `[[ ... ]] || { echo "FAIL: ..."; exit 1; }` assertions. Trivial scripts need none.
- For a script whose job is producing a specific output shape (a report, a formatted table, a JSON blob), pin it with a golden file: `diff <(./script.sh --json) testdata/expected.json`. Catches an accidental output-shape change (including one a coding agent makes while "just" refactoring) that a `[[ ... ]]` assertion wouldn't.
