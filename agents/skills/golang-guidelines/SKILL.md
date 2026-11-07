---
name: golang-guidelines
description: Project-level Go guidelines — idiomatic layout (start flat, grow into cmd/internal, not golang-standards/project-layout), justfile, golangci-lint/govulncheck, prek, cobra+viper CLIs, charmbracelet TUIs, pgx, modernc.org/sqlite, table-driven/fuzz/benchmark tests, testing LLM-generated code, multi-stage Dockerfile. Trigger on "new go project", "go project layout", "set up a go repo", "go.mod", "go best practices", starting/restructuring a Go codebase, or adding tests/lint/pre-commit config to one (not a one-off script).
---

# Go Project Guidelines

Project-level conventions for Go repos: layout and tooling, not language syntax. Use [clig.dev](https://clig.dev/) for CLI shape and [12-factor](https://12factor.net/) for service shape.

## Project layout

There is no official mega-layout. The 50k-star `golang-standards/project-layout` repo is **not** endorsed by the Go team; most real Go repos are simpler and do not need top-level `pkg/`. Official guidance is to grow into structure:

1. **One package at the module root** is enough for a real program. Start here.
2. Add **`internal/`** once you have implementation detail to hide from other modules that might import this one.
3. Add **`cmd/<binary>/`** only once you have more than one binary, or you're shipping both a library and a binary.

```text
myproject/
├── cmd/
│   └── myproject/
│       └── main.go
├── internal/            # implementation not meant to be imported elsewhere
├── docs/                # markdown docs — see "Docs folder"
├── go.mod
├── go.sum
├── justfile
├── .pre-commit-config.yaml
├── Dockerfile
└── README.md
```

For a **monorepo of related CLIs/services**, a production-friendly pattern:

- **One `go.mod` at the repo root, one root justfile** — don't split into multiple modules just because there are multiple binaries; that multiplies version-pinning and CI surface for no benefit until the binaries genuinely need independent release cadences. No per-subdirectory justfiles duplicating the same build logic.
- Each binary gets its own top-level dir with `<name>/cmd/<name>/main.go` plus whatever feature packages it needs.
- A shared **`libs/`** (or `shared/`) dir for packages used by more than one binary — the monorepo's answer to "does this go in `internal/` or `pkg/`": genuinely shared code lives there, importable by everything else in the module, not exported outside it.
- A dedicated `tools/` or `smoke/` dir for harnesses that exercise the *compiled* binaries end-to-end, not just `go test` — see "Testing".

Repo-wide harness — `AGENTS.md`, spec dirs, module size, `just check` done-gate, auxiliary prek hooks, changelog, guardrails for LLM-written code: see `repo-harness`.

## Toolchain versioning

- Pin a minimum `go` version in `go.mod` and let `GOTOOLCHAIN` (automatic since Go 1.21) fetch the matching toolchain for contributors — don't make people manually install the right compiler version.
- Track dev tools as **tool directives in `go.mod`** (Go 1.24+): `go get -tool golang.org/x/vuln/cmd/govulncheck`. Replaces the old blank-imports-in-`tools.go` workaround — migrate if a codebase still has one.
- Pin to the team's actual minimum supported version; treat newer language features as available once you raise that floor, not before.

## Build / lint / format — justfile

`just` is the automation surface (same as the Python and shell repos): one command, same local/CI behavior. Baseline:

```just
version := `git describe --tags --always --dirty 2>/dev/null || echo dev`
ldflags := "-X main.version=" + version

default:
    @just --list --unsorted

build:
    go build -ldflags "{{ldflags}}" ./...

install:
    go install -ldflags "{{ldflags}}" ./...

test *ARGS:
    go test -race ./... {{ARGS}}

# fmt --diff exits 1 on unformatted code, so lint gates formatting too
lint:
    golangci-lint run
    golangci-lint fmt --diff

fmt:
    golangci-lint fmt

tidy:
    go mod tidy

vuln:
    govulncheck ./...

# Done-gate for humans, agents, and CI
check: lint test vuln
```

- Once you're actually shipping cross-platform release artifacts, add `package`/`package-all` recipes that cross-compile per `GOOS`/`GOARCH` and bundle any vendored third-party binaries the tool needs — not needed for an internal-only build.
- A `smoke` recipe (wired into `check`) that runs the *compiled* binary against a small integration harness (see "Testing") catches classes of bug unit tests structurally can't.

## The lint/vuln tool landscape

Go linting is one aggregator plus a few specialists:

- **`golangci-lint`** — standard aggregator. It runs `go vet`, `staticcheck` (v2 folds in `gosimple`/`unused`), `ineffassign`, `errcheck`, `revive`, `gosec`, and more in parallel with caching. Baseline `.golangci.yml`:

  ```yaml
  version: "2"
  linters:
    enable:
      - errcheck
      - govet
      - ineffassign
      - revive
      - staticcheck   # includes the old gosimple/unused checks in golangci-lint v2
      - gosec
  formatters:
    enable:
      - gofumpt
      - goimports
  ```

- **`staticcheck`** — the gold standard of Go static analysis on its own; `golangci-lint` bundles it, so you rarely run it standalone.
- **`gosec`** — security-focused: SQL/command injection, weak crypto, path traversal. Bundled by `golangci-lint`; run standalone only if you want it gating something `golangci-lint` isn't covering yet.
- **`errcheck`** / **`errorlint`** / **`nilerr`** — verify every returned error is actually checked, and checked correctly (no swallowed errors, no `errors.Is`/`errors.As` misuse). All bundleable via `golangci-lint`.
- **`revive`** — a faster, more configurable replacement for the deprecated `golint`.
- **`gofumpt`** — a stricter superset of `gofmt` (same output style, more opinionated on things plain `gofmt` leaves alone). Run it via `golangci-lint fmt` (the `formatters:` block above) so lint and format share one config.
- **`govulncheck`** — the official Go team's vulnerability scanner (`go install golang.org/x/vuln/cmd/govulncheck@latest`, or track it as a Go 1.24+ tool dependency in `go.mod`). Unlike the linters above, this checks your actual call graph against the Go vulnerability database — it flags a vulnerable function only if your code path can actually reach it, which cuts a lot of the noise generic dependency-CVE scanners produce. Run it in CI at minimum; `just vuln` locally before a release.

## prek (pre-commit) automation

Point pre-commit at the justfile; do not redeclare `lint`/`fmt` twice.

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: check-added-large-files
      - id: check-yaml
      - id: check-merge-conflict
      - id: end-of-file-fixer
      - id: trailing-whitespace

  - repo: local
    hooks:
      - id: go-fmt
        name: go fmt
        entry: just fmt
        language: system
        pass_filenames: false
        types: [go]
      - id: go-lint
        name: go lint
        entry: just lint
        language: system
        pass_filenames: false
        types: [go]
      - id: go-mod-tidy
        name: go mod tidy
        entry: just tidy
        language: system
        pass_filenames: false
        files: 'go\.(mod|sum)$'

  # + auxiliary hooks (typos, rumdl, prettier, hadolint, gitleaks, actionlint, zizmor): copy the block from `repo-harness`
```

Pinned `rev`s rot — run `prek autoupdate` periodically (or after copying this template) rather than hand-tracking versions. Keep `go test ./...` and `govulncheck` out of the commit hook if they're slow (fuzz/integration tests, a network call to the vuln database) — run them in CI or a pre-push hook instead, so commits stay fast.

## CLI + config — cobra, viper, pflag

- **stdlib `flag` first** for a single-command tool. Reach for cobra/viper only once there are subcommands *and* layered config (flag > env > file).
- **`cobra`** for the command tree (`rootCmd`, subcommands via `AddCommand`), **`pflag`** for POSIX/GNU-style flags (cobra uses it under the hood), **`viper`** to resolve config from flags/env vars/config files with one precedence order instead of hand-rolling it.
- Standard viper wiring — env vars override config file, flags override both:

  ```go
  viper.SetEnvPrefix("MYTOOL")
  viper.AutomaticEnv()
  viper.BindPFlag("env", rootCmd.PersistentFlags().Lookup("env"))
  ```

- The CLI-UX rules in `shell-guidelines` (env-vars-vs-flags, TTY-aware output, JSON error envelope, exit-code contract, confirmation only on a TTY — all from clig.dev) apply the same way here — cobra/viper give you the flag/env plumbing, you still own the contract. For TTY detection use **`github.com/mattn/go-isatty`** (`isatty.IsTerminal(os.Stdout.Fd())`) — a small, direct, purpose-built dependency, rather than pulling in `golang.org/x/term` just for the terminal check.

## TUI — charmbracelet

Only when the tool genuinely needs interactive UI (pickers, live status, full-screen views) — plain stdout plus `fzf` covers most CLIs. Then use Charm instead of hand-rolled ANSI:

- **`bubbletea`** — Elm-architecture TUI framework (`Model`/`Update`/`View`), the base for anything interactive.
- **`bubbles`** — ready-made components (list, table, spinner, text input) so you're not rebuilding a list widget from scratch.
- **`lipgloss`** — styling/layout (borders, padding, color) for terminal output, TUI or not.
- **`muesli/reflow`** — text wrapping/word-wrap for terminal-width-aware output.
- **`huh`** — charm's form/prompt library, for multi-field interactive prompts without hand-rolling a `bubbles.textinput` flow.
- **`glamour`** — markdown rendering to a terminal (this is what the `glow` CLI mentioned in `shell-guidelines` is built on — reach for `glamour` directly when a Go program itself needs to render markdown, not just shell out to `glow`).
- **`gum`** — charm's shell-callable TUI helper, for adding a picker/spinner/confirm to a *shell script* without writing Go (the `fzf` recommendation in `shell-guidelines` covers the same job for the interactive-picker case specifically).

## Database — pgx

- **`jackc/pgx/v5`** for Postgres, used directly (not wrapped in `database/sql`) to get pgx's native type mapping and better performance — only drop to the `database/sql` compatibility shim if something in the stack specifically needs a `sql.DB`. Use `pgxpool` for connection pooling in anything long-running.

## Embedded storage — sqlite

- **`modernc.org/sqlite`**, not `mattn/go-sqlite3`, when static/cross-compiled builds matter. `mattn/go-sqlite3` requires cgo and breaks `CGO_ENABLED=0`; `modernc.org/sqlite` is pure Go with the same `database/sql` driver shape.
- Good use case: local cache/state for a CLI tool or single-instance service, not a shared multi-writer store — that's still Postgres's job.

## Testing — more than unit tests

- stdlib `testing` plus `github.com/google/go-cmp/cmp` for diffs is enough; add **`testify`** (`assert`/`require`) only if the codebase already uses it. Hand-written fakes over mock frameworks.
- **Table-driven tests** are the idiomatic default for anything with more than one input case — a `[]struct{ name string; in ...; want ... }` slice looped with `t.Run(tt.name, ...)`, not N copy-pasted test functions.
- **Fuzz tests** (`func FuzzXxx(f *testing.F)`, native since Go 1.18, run via `go test -fuzz=FuzzXxx`) for anything parsing untrusted or structured input — a parser, a config-file loader, anything touching user-supplied strings. Seed corpus lives in `testdata/fuzz/FuzzXxx/`.
- **Benchmarks** (`func BenchmarkXxx(b *testing.B)`, run via `go test -bench=.`) for anything with an actual performance budget — track results over time, don't just run them once and forget.
- **Smoke/integration harnesses beyond `go test`** for end-to-end checks against the actual built binary — a small program (or `go test` in a separate build-tagged package) that runs the compiled binary and asserts on its real output/exit codes. Wire this into the justfile's `smoke`/`check` recipes so it's part of the routine, not a manual step someone forgets.
- Don't rely on unit tests alone for anything that parses external input, has a performance budget, or is distributed as a binary someone else runs — pick the test type that actually exercises the risk.

## Testing LLM-generated code

Why and when: `repo-harness`. Go tools:

- golden files: `testdata/*.golden` compared with `go-cmp` (or `goldie`)
- property-based: `pgregory.net/rapid`
- fuzzing: native `go test -fuzz`
- mutation: `gremlins` (periodic, slow)
- e2e: run the compiled binary via `os/exec`, not internal functions

## Docs folder

- `docs/*.md` for architecture and design docs, next to the code they document. Update these when the design changes; don't let them fossilize as the code moves on.

## Sample Dockerfile (multi-stage, static binary)

```dockerfile
FROM golang:1.26 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/myproject ./cmd/myproject

FROM gcr.io/distroless/static-debian12
COPY --from=builder /out/myproject /myproject
USER nonroot:nonroot
ENTRYPOINT ["/myproject"]
```

- `CGO_ENABLED=0` gives a fully static binary — this is exactly why `modernc.org/sqlite` (cgo-free) matters if the program touches sqlite; `mattn/go-sqlite3` would break this build.
- `distroless/static` over `scratch` when the binary makes outbound HTTPS calls — it ships CA certs and `/etc/passwd` (for the `nonroot` user); `scratch` has neither. Use `scratch` only for binaries that need nothing else.
- Copying dependency files (`go.mod`/`go.sum`) before the rest of the source is the same caching trick as the Python Dockerfile in `python-guidelines` — `go mod download` only reruns when dependencies actually change.
- Same 12-factor disposability/parity principles apply: static Go binaries in minimal images start fast and carry no leftover state.
