#!/usr/bin/env bash
# shellcheck disable=SC2016  # backticks are literal markdown in messages to Claude
# Stop: run the repo's done-gate (`just check`) before Claude may finish.
# Opt-in per repo: only when a justfile defines `check` and the tree is dirty.
# Failure -> exit 2, output goes back to Claude; second stop attempt is let through.
# ponytail: runs on any dirty tree, including the user's own edits; track
# Claude-touched files if that gets noisy.
set -uo pipefail

input=$(cat)
[[ $(jq -r '.stop_hook_active // false' <<<"$input") == true ]] && exit 0
cd "$(jq -r '.cwd // empty' <<<"$input")" 2>/dev/null || exit 0

just --summary 2>/dev/null | tr ' ' '\n' | rg -qx check || exit 0
[[ -n $(git status --porcelain 2>/dev/null) ]] || exit 0

if ! out=$(timeout 300 just check 2>&1); then
  printf '`just check` failed — fix before finishing:\n%s\n' "$(tail -40 <<<"$out")" >&2
  exit 2
fi
exit 0
