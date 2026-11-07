#!/usr/bin/env bash
# shellcheck disable=SC2016  # backticks are literal markdown in messages to Claude
# PreToolUse(Bash): enforce AGENTS.md command rules.
# exit 2 + stderr = deny, reason goes back to Claude; JSON "ask" = prompt the user.
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

deny() { printf 'Blocked by guard-bash: %s\n' "$1" >&2; exit 2; }
ask() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "ask", permissionDecisionReason: $r}}'
  exit 0
}
has() { rg -q -- "$1" <<<"$cmd"; }

# start of a command: line start or after ; & | ( $( `
S='(^|[;&|(`]\s*|\$\(\s*)'

has "${S}git\s+worktree\s+(add|remove)\b" &&
  deny 'raw git worktree. Use `WT_NO_CD=1 wt <prefix>/<slug>` / `wt rm <branch>`.'

has "${S}wt\s+(rm\s+(.*\s)?(--force|-f)\b|cleanup\b)" &&
  ask 'wt rm --force / wt cleanup delete worktrees irrecoverably.'

has '\s--no-verify\b' &&
  deny '--no-verify skips hooks. Fix what the hook reports instead.'

has "${S}sed\s+(-[a-zA-Z]*i|--in-place)" &&
  deny 'sed -i. Use `sd -F old new file` or the Edit tool.'

has "${S}(curl|wget)\s.*\b(api\.)?github\.com\b" &&
  deny 'curl/wget to GitHub. Use `gh api ...`.'

has "${S}git\s+commit\b" && has '(?i)co-authored-by:' &&
  deny 'user rule: no Co-Authored-By / attribution trailers in commits.'

has '(\.ssh/id_[a-z0-9_]+|\.claude/\.credentials\.json|galaxy_token)\b' &&
  deny 'command touches a credential file.'

# Branch switching in a main checkout (the shared hub). Worktrees are fine;
# `git checkout -- <path>` (restore files) is fine.
# ponytail: judged by the hook's cwd, so `cd other && git checkout` is checked against cwd.
if has "${S}git\s+(checkout|switch)\b" && ! has 'git\s+checkout\s+--\s'; then
  if dirs=$(git -C "${cwd:-$PWD}" rev-parse --path-format=absolute --git-dir --git-common-dir 2>/dev/null); then
    { read -r gitdir; read -r common; } <<<"$dirs"
    [[ $gitdir == "$common" ]] &&
      deny 'git checkout/switch in a main checkout (shared hub). Use `WT_NO_CD=1 wt <prefix>/<slug>`.'
  fi
fi

exit 0
