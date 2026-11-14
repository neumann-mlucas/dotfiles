#!/usr/bin/env bash
# shellcheck disable=SC2016  # fixtures are literal shell source
# Self-check for the Claude Code hooks in this dir. Run: ./test-hooks.sh
set -uo pipefail
H=$(dirname "$(realpath "$0")")
# under `git commit` (prek), GIT_INDEX_FILE etc. leak in and redirect fixture repos
# shellcheck disable=SC2046
unset $(git rev-parse --local-env-vars)
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
git() { command git -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@t "$@"; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0

check() { # check <name> <expected> <got>
  if [[ $2 == "$3" ]]; then printf 'PASS %s\n' "$1"; else printf 'FAIL %s: want %s got %s\n' "$1" "$2" "$3"; fail=1; fi
}

# --- guard-bash -----------------------------------------------------------
git -C "$tmp" init -q hub && git -C "$tmp/hub" commit -q --allow-empty -m init
git -C "$tmp/hub" worktree add -q "$tmp/wt" -b wt 2>/dev/null
guard() { # guard <cwd> <command> -> 0 | 2 | ask
  local out rc
  out=$(jq -n --arg c "$2" --arg d "$1" '{tool_input:{command:$c},cwd:$d}' | "$H/guard-bash.sh" 2>&1)
  rc=$?
  [[ $out == *'"ask"'* ]] && rc=ask
  printf '%s' "$rc"
}
while IFS='|' read -r want where c; do
  [[ -z $want ]] && continue
  d=$tmp/hub; [[ $where == wt ]] && d=$tmp/wt
  check "guard: $c" "$want" "$(guard "$d" "$c")"
done <<'EOF'
2|hub|git checkout main
0|wt|git checkout main
0|hub|git checkout -- README.md
2|hub|cd x && git switch -c foo
2|hub|git worktree add ../x
0|hub|wt switch --create chore/x --no-cd
ask|hub|wt remove --force chore/x
ask|hub|wt remove -D chore/x
ask|hub|wt remove chore/x --force-delete
ask|hub|wt step prune
0|hub|wt remove chore/x
0|hub|wt remove --foreground chore/x
2|hub|git commit --no-verify -m x
2|hub|sed -i s/a/b/ f
0|hub|sed -n 1,5p f
2|hub|curl -s https://api.github.com/repos/x
0|hub|gh api repos/x
2|hub|git commit -m "x  Co-Authored-By: Claude <x>"
2|hub|cat ~/.ssh/id_ed25519
0|hub|ls ~/.ssh
0|hub|rg -n 'git checkout' README.md
EOF

# --- post-edit ------------------------------------------------------------
edit() { jq -n --arg f "$1" '{tool_input:{file_path:$f}}' | "$H/post-edit.sh" >/dev/null 2>&1; printf '%s' $?; }

mkdir -p "$tmp/rs/src" && printf '[package]\nname="x"\nversion="0.1.0"\nedition="2024"\n' >"$tmp/rs/Cargo.toml"
printf 'fn  main( ){let x=1;}\n' >"$tmp/rs/src/main.rs"
edit "$tmp/rs/src/main.rs" >/dev/null
check 'post-edit: rustfmt formats' 'fn main() {' "$(head -1 "$tmp/rs/src/main.rs")"

mkdir -p "$tmp/py" && printf '[tool.ruff]\n' >"$tmp/py/pyproject.toml"
printf 'import os\nx=1\nprint(y)\n' >"$tmp/py/a.py"
check 'post-edit: ruff reports undefined name' 2 "$(edit "$tmp/py/a.py")"
check 'post-edit: ruff formats, keeps unused import' 2 "$(rg -cx 'import os|x = 1' "$tmp/py/a.py")"

mkdir -p "$tmp/foreign" && printf 'x=1\n' >"$tmp/foreign/b.py"
check 'post-edit: no ruff config -> untouched' 0 "$(edit "$tmp/foreign/b.py")"
check 'post-edit: no ruff config -> not reformatted' 'x=1' "$(cat "$tmp/foreign/b.py")"

printf '#!/usr/bin/env bash\necho $1\n' >"$tmp/s"
check 'post-edit: shellcheck via shebang' 2 "$(edit "$tmp/s")"
printf '#!/usr/bin/env bash\necho "$1"\n' >"$tmp/ok.sh"
check 'post-edit: clean shell passes' 0 "$(edit "$tmp/ok.sh")"

# --- stop-check -----------------------------------------------------------
git -C "$tmp" init -q proj
printf 'check:\n    exit 1\n' >"$tmp/proj/justfile"
stop() { jq -n --arg d "$1" --argjson a "$2" '{cwd:$d,stop_hook_active:$a}' | "$H/stop-check.sh" >/dev/null 2>&1; printf '%s' $?; }
check 'stop: failing check blocks' 2 "$(stop "$tmp/proj" false)"
check 'stop: second attempt allowed' 0 "$(stop "$tmp/proj" true)"
printf 'check:\n    true\n' >"$tmp/proj/justfile"
check 'stop: passing check allows' 0 "$(stop "$tmp/proj" false)"
check 'stop: no justfile -> skip' 0 "$(stop "$tmp/foreign" false)"

exit "$fail"
