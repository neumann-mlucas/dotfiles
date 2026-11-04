---
name: golang-guidelines
description: Project-level Go guidelines — idiomatic layout (start flat, grow into cmd/internal, not golang-standards/project-layout), Makefile, golangci-lint/govulncheck, prek, cobra+viper CLIs, charmbracelet TUIs, pgx, modernc.org/sqlite, table-driven/fuzz/benchmark tests, testing LLM-generated code, multi-stage Dockerfile. Trigger on "new go project", "go project layout", "set up a go repo", "go.mod", "go best practices", or starting/restructuring a Go codebase (not a one-off script).
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
├── Makefile
├── .pre-commit-config.yaml
├── Dockerfile
└── README.md
```

For a **monorepo of related CLIs/services**, a production-friendly pattern:

- **One `go.mod` at the repo root, one root Makefile** — don't split into multiple modules just because there are multiple binaries; that multiplies version-pinning and CI surface for no benefit until the binaries genuinely need independent release cadences. No per-subdirectory Makefiles duplicating the same build logic.
- Each binary gets its own top-level dir with `<name>/cmd/<name>/main.go` plus whatever feature packages it needs.
- A shared **`libs/`** (or `shared/`) dir for packages used by more than one binary — the monorepo's answer to "does this go in `internal/` or `pkg/`": genuinely shared code lives there, importable by everything else in the module, not exported outside it.
- A dedicated `tools/` or `smoke/` dir for harnesses that exercise the *compiled* binaries end-to-end, not just `go test` — see "Testing".

### AI-agent project docs

- **`AGENTS.md`** at the repo root — the closest current cross-tool agent standard: plain markdown for setup, style, and architectural boundaries. Symlink tool-specific filenames (`CLAUDE.md`, etc.) instead of duplicating.
- For a non-trivial feature, a written spec before code pays for itself. No single naming convention has fully won yet, but the shape converges on requirements → plan → tasks, one dir per feature. Two real conventions in active use:
  - GitHub Spec Kit: `.specify/specs/<NNN-feature>/{spec.md, plan.md, tasks.md}`, plus `.specify/memory/constitution.md` for repo-wide governing principles.
  - Kiro-style: `.<tool>/specs/<feature>/{requirements.md, design.md, tasks.md}`.
- Pick one, apply it consistently, don't invent a third naming scheme. Skip it entirely for a small change — this is scaffolding for genuinely non-trivial work, not ceremony for a two-file fix.

### Module size (agent economics)

Agents pay input tokens to read context: the same change costs ~6× more in a monolithic file than a modular one (83% input-token drop measured after splitting a 17k-line file — [martinfowler.com/articles/exploring-gen-ai/refactoring-economic-benefit.html](https://martinfowler.com/articles/exploring-gen-ai/refactoring-economic-benefit.html)). Split when a file plus its direct callers no longer fit a lean read. Justify structural refactors by measurement: run one representative change with a fresh agent before and after; compare input tokens.

## Toolchain versioning

- Pin a minimum `go` version in `go.mod` and let `GOTOOLCHAIN` (automatic since Go 1.21) fetch the matching toolchain for contributors — don't make people manually install the right compiler version.
- Track dev tools as **tool directives in `go.mod`** (Go 1.24+): `go get -tool golang.org/x/vuln/cmd/govulncheck`. Replaces the old blank-imports-in-`tools.go` workaround — migrate if a codebase still has one.
- Pin to the team's actual minimum supported version; treat newer language features as available once you raise that floor, not before.

## Build / lint / format — Makefile

Make is the automation surface: one command, same local/CI behavior. Baseline:

```makefile
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
LDFLAGS := -X main.version=$(VERSION)

.PHONY: build install test lint fmt tidy vuln clean check

build:
	go build -ldflags "$(LDFLAGS)" ./...

install:
	go install -ldflags "$(LDFLAGS)" ./...

test:
	go test -race ./...

lint:
	golangci-lint run

fmt:
	gofumpt -l -w .

tidy:
	go mod tidy

vuln:
	govulncheck ./...

check: test lint vuln
	go build ./...

clean:
	rm -rf dist/
```

- Once you're actually shipping cross-platform release artifacts, add `package`/`package-all` targets that cross-compile per `GOOS`/`GOARCH` and bundle any vendored third-party binaries the tool needs — not needed for an internal-only build.
- A `smoke`/`check` target that runs the *compiled* binary against a small integration harness (see "Testing") catches classes of bug unit tests structurally can't.

## The lint/vuln tool landscape

Go linting is one aggregator plus a few specialists:

- **`golangci-lint`** — standard aggregator. It runs `go vet`, `staticcheck`, `gosimple`, `ineffassign`, `unused`, `errcheck`, `revive`, `gosec`, and more in parallel with caching. Baseline `.golangci.yml`:

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
  ```

- **`staticcheck`** — the gold standard of Go static analysis on its own; `golangci-lint` bundles it, so you rarely run it standalone.
- **`gosec`** — security-focused: SQL/command injection, weak crypto, path traversal. Bundled by `golangci-lint`; run standalone only if you want it gating something `golangci-lint` isn't covering yet.
- **`errcheck`** / **`errorlint`** / **`nilerr`** — verify every returned error is actually checked, and checked correctly (no swallowed errors, no `errors.Is`/`errors.As` misuse). All bundleable via `golangci-lint`.
- **`revive`** — a faster, more configurable replacement for the deprecated `golint`.
- **`gofumpt`** — a stricter superset of `gofmt` (same output style, more opinionated on things plain `gofmt` leaves alone). Use it as the formatter; it's a drop-in for `gofmt`.
- **`govulncheck`** — the official Go team's vulnerability scanner (`go install golang.org/x/vuln/cmd/govulncheck@latest`, or track it as a Go 1.24+ tool dependency in `go.mod`). Unlike the linters above, this checks your actual call graph against the Go vulnerability database — it flags a vulnerable function only if your code path can actually reach it, which cuts a lot of the noise generic dependency-CVE scanners produce. Run it in CI at minimum; `make vuln` locally before a release.

## prek (pre-commit) automation

Point pre-commit at the Makefile; do not redeclare `lint`/`fmt` twice.

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
        entry: make fmt
        language: system
        pass_filenames: false
        types: [go]
      - id: go-lint
        name: go lint
        entry: make lint
        language: system
        pass_filenames: false
        types: [go]
      - id: go-mod-tidy
        name: go mod tidy
        entry: make tidy
        language: system
        pass_filenames: false
        files: 'go\.(mod|sum)$'

  # Auxiliary files every project accumulates, not just .go — Docker/Markdown/JSON/YAML/spelling
  - repo: https://github.com/crate-ci/typos
    rev: v1.47.2
    hooks:
      - id: typos

  - repo: https://github.com/hadolint/hadolint
    rev: v2.14.0
    hooks:
      - id: hadolint-docker    # runs via the hadolint Docker image, no local binary needed

  - repo: https://github.com/rvben/rumdl-pre-commit
    rev: v0.1.22
    hooks:
      - id: rumdl-fmt
      - id: rumdl

  - repo: https://github.com/rbubley/mirrors-prettier
    rev: v3.9.5
    hooks:
      - id: prettier
        types_or: [json, yaml]
```

Pinned `rev`s rot — run `prek autoupdate` periodically (or after copying this template) rather than hand-tracking versions. Keep `go test ./...` and `govulncheck` out of the commit hook if they're slow (fuzz/integration tests, a network call to the vuln database) — run them in CI or a pre-push hook instead, so commits stay fast.

Auxiliary hooks belong here too: real projects have Dockerfiles, markdown, JSON/YAML, and typos. `typos` catches misspellings with low false positives and supports `_typos.toml` allowlists. `rumdl` owns Markdown format + lint; do not also run prettier on `.md`. Keep prettier scoped to JSON/YAML.

## Changelog / release

If commits follow Conventional Commits, derive `CHANGELOG.md` and semver tags with `git-cliff`: `make changelog` regenerates, `make release` bumps from `feat`/`fix`/`!`, commits/tags, and never pushes. Use commitizen/semantic-release only when commit-time enforcement is the ask.

## CLI + config — cobra, viper, pflag

- **`cobra`** for the command tree (`rootCmd`, subcommands via `AddCommand`), **`pflag`** for POSIX/GNU-style flags (cobra uses it under the hood), **`viper`** to resolve config from flags/env vars/config files with one precedence order instead of hand-rolling it.
- Standard viper wiring — env vars override config file, flags override both:

  ```go
  viper.SetEnvPrefix("MYTOOL")
  viper.AutomaticEnv()
  viper.BindPFlag("env", rootCmd.PersistentFlags().Lookup("env"))
  ```

- The CLI-UX rules in `shell-guidelines` (env-vars-vs-flags, TTY-aware output, JSON error envelope, exit-code contract, confirmation only on a TTY — all from clig.dev) apply the same way here — cobra/viper give you the flag/env plumbing, you still own the contract. For TTY detection use **`github.com/mattn/go-isatty`** (`isatty.IsTerminal(os.Stdout.Fd())`) — a small, direct, purpose-built dependency, rather than pulling in `golang.org/x/term` just for the terminal check.

## TUI — charmbracelet

For interactive pickers, live status, or full-screen views, use Charm instead of hand-rolled ANSI:

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

- **`testify`** (`assert`/`require`, and `mock` where a real interface needs a test double) for the unit-test layer.
- **Table-driven tests** are the idiomatic default for anything with more than one input case — a `[]struct{ name string; in ...; want ... }` slice looped with `t.Run(tt.name, ...)`, not N copy-pasted test functions.
- **Fuzz tests** (`func FuzzXxx(f *testing.F)`, native since Go 1.18, run via `go test -fuzz=FuzzXxx`) for anything parsing untrusted or structured input — a parser, a config-file loader, anything touching user-supplied strings. Seed corpus lives in `testdata/fuzz/FuzzXxx/`.
- **Benchmarks** (`func BenchmarkXxx(b *testing.B)`, run via `go test -bench=.`) for anything with an actual performance budget — track results over time, don't just run them once and forget.
- **Smoke/integration harnesses beyond `go test`** for end-to-end checks against the actual built binary — a small program (or `go test` in a separate build-tagged package) that runs the compiled binary and asserts on its real output/exit codes. Wire this into the Makefile's `smoke`/`check` targets so it's part of the routine, not a manual step someone forgets.
- Don't rely on unit tests alone for anything that parses external input, has a performance budget, or is distributed as a binary someone else runs — pick the test type that actually exercises the risk.

## Testing LLM-generated code

LLM-written code can look plausible while being subtly wrong, and its tests often cover only the happy path it just wrote. Add checks that do not depend on the generator's own judgment:

- **Golden-file tests** — pin known-good output to a checked-in `testdata/*.golden` file, compared with `go-cmp` or a small helper like `goldie`. Any diff — including a "helpful" refactor that quietly changes output shape — fails loudly and requires explicit re-approval. This is the single highest-leverage guardrail against an agent silently changing behavior while "just cleaning up."
- **Property-based tests** (`pgregory.net/rapid`, or `gopter`) — generate a wide input space instead of the handful of examples a model writes for itself in a table-driven test; catches edge cases the generator never had to think about.
- **Fuzz tests** — already the language's native answer to this (see "Testing — more than unit tests" above); worth calling out specifically for LLM-authored parsing/serialization code, where the model's own test cases are usually well-formed input only.
- **Mutation testing** (`go-mutesting`, `gremlins`) — deliberately breaks the code under test and checks whether the existing suite actually fails. Directly answers the most common LLM-authored-test failure mode: a test that calls the function and asserts something trivially true, showing full coverage while verifying nothing. Run periodically, not on every commit — it's slow.
- **End-to-end, against the compiled binary** — a smoke test that runs the actual built binary via `os/exec`, not one that calls internal functions directly. Catches wiring bugs (wrong entry point, a flag that only worked because of local state) that unit tests structurally can't see.

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
