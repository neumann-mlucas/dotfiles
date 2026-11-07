#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): format the edited file with the language's
# standard formatter, then report remaining lint findings to Claude (exit 2).
# Python only when the project opted into ruff, so foreign repos aren't reformatted.
set -uo pipefail

f=$(jq -r '.tool_input.file_path // empty')
[[ -n $f && -f $f ]] || exit 0
dir=$(dirname "$f")

# Nearest ancestor (up to the git root) containing any of the given names.
up() {
  local d=$dir stop
  stop=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo /)
  while :; do
    for n in "$@"; do [[ -e $d/$n ]] && { printf '%s/%s\n' "$d" "$n"; return 0; }; done
    [[ $d == "$stop" || $d == / ]] && return 1
    d=$(dirname "$d")
  done
}

report() {
  [[ -n $2 ]] || return 0
  printf '%s findings in %s (fix them):\n%s\n' "$1" "$f" "$(head -30 <<<"$2")" >&2
  exit 2
}

case $f in
  *.rs)
    ed=2021
    if cargo_toml=$(up Cargo.toml); then
      e=$(yq -p toml -oy '.package.edition // .workspace.package.edition // ""' "$cargo_toml" 2>/dev/null)
      [[ $e =~ ^20[0-9]{2}$ ]] && ed=$e
    fi
    command -v rustfmt >/dev/null && rustfmt --edition "$ed" "$f" 2>/dev/null
    ;;
  *.go)
    command -v gofmt >/dev/null && gofmt -w "$f"
    ;;
  *.py | *.pyi)
    cfg=$(up ruff.toml .ruff.toml pyproject.toml) || exit 0
    [[ $cfg == */pyproject.toml ]] && ! rg -q '^\[tool\.ruff' "$cfg" && exit 0
    command -v ruff >/dev/null || exit 0
    ruff format -q "$f"
    # no --fix, and skip unused-* rules: mid-edit an import may be used by the next edit
    report ruff "$(ruff check -q --ignore F401,F841 --output-format concise "$f" 2>&1)"
    ;;
  *)
    if [[ $f == *.sh || $f == *.bash ]] || head -1 "$f" | rg -q '^#!.*\b(bash|sh)\b'; then
      command -v shellcheck >/dev/null && report shellcheck "$(shellcheck -f gcc "$f" 2>&1)"
    fi
    ;;
esac
exit 0
