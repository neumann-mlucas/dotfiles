---
name: python-guidelines
description: Project-level Python guidelines — src/ layout, uv (+ dependency cooldown), ruff/ty/mypy, prek, just, typer/pydantic CLIs, pytest markers, testing LLM-generated code, Dockerfile/CI placement. Trigger on "new python project", "python project layout", "set up a python repo", "pyproject.toml", "python best practices", or starting/restructuring a Python codebase (not a one-off script — see `shell-guidelines` for that).
---

# Python Project Guidelines

Project-level conventions: Python repo layout and automation, not one-off script rules. Use [clig.dev](https://clig.dev/) for CLI shape and [12-factor](https://12factor.net/) for service shape.

## Project layout

```text
myproject/
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── cli.py
│       └── ...
├── tests/
├── docs/                    # markdown docs — see "Docs folder"
├── .github/workflows/       # or another CI config — see "CI"
├── Dockerfile
├── pyproject.toml
├── uv.lock
├── justfile
├── .pre-commit-config.yaml
└── README.md
```

- **`src/` layout, not flat top-level package.** Otherwise `import myproject` can resolve to the repo cwd even when the package is not installed; tests pass locally and fail after packaging. `src/` forces `uv sync`/install before imports work.
- This is the recommended default for *new* projects. Some existing/legacy codebases use a flat multi-package layout instead, often for vendoring or historical reasons — that's usually accumulated debt, not a pattern to copy into a new repo.
- `docs/` for markdown design docs, `tests/` mirrors `src/myproject/` structure.

### AI-agent project docs

- **`AGENTS.md`** at the repo root — the closest thing to a real cross-tool standard as of 2026: an open, plain-markdown format read by 20+ coding agents/tools (setup commands, code style, architectural boundaries). Symlink tool-specific filenames (`CLAUDE.md`, etc.) to it instead of maintaining duplicates.
- For a non-trivial feature, a written spec before code pays for itself. No single naming convention has fully won yet, but the shape converges on requirements → plan → tasks, one dir per feature. Two real conventions in active use:
  - GitHub Spec Kit: `.specify/specs/<NNN-feature>/{spec.md, plan.md, tasks.md}`, plus `.specify/memory/constitution.md` for repo-wide governing principles.
  - Kiro-style: `.<tool>/specs/<feature>/{requirements.md, design.md, tasks.md}`.
- Pick one, apply it consistently, don't invent a third naming scheme. Skip it entirely for a small change — this is scaffolding for genuinely non-trivial work, not ceremony for a two-file fix.

### Module size (agent economics)

Agents pay input tokens to read context: the same change costs ~6× more in a monolithic file than a modular one (83% input-token drop measured after splitting a 17k-line file — [martinfowler.com/articles/exploring-gen-ai/refactoring-economic-benefit.html](https://martinfowler.com/articles/exploring-gen-ai/refactoring-economic-benefit.html)). Split when a file plus its direct callers no longer fit a lean read. Justify structural refactors by measurement: run one representative change with a fresh agent before and after; compare input tokens.

## Dependency management — uv

- `uv init`, `uv add <pkg>`, `uv sync`, `uv lock`, `uv run <cmd>`. `uv.lock` is committed; don't hand-edit it.
- Dev-only tools go in a dependency group (PEP 735), not the main `dependencies` list:

  ```toml
  [project]
  dependencies = ["pydantic>=2", "typer"]

  [dependency-groups]
  dev = ["pytest", "pytest-cov", "ruff", "mypy"]

  [tool.uv]
  default-groups = ["dev"]
  ```

- **Minimize dependencies.** Each one is supply-chain surface plus future upgrade work. Ladder: stdlib → existing dependency → well-known maintained dependency → niche dependency. Don't add a package for 10 lines of stdlib. `deptry` catches drift later.
- **Prefer Rust-core Python libraries when there is a choice**: `pydantic` v2 over `attrs`/`marshmallow` for validation, `orjson` over stdlib `json` on hot paths, `polars` over `pandas` for new performance-sensitive dataframe work. Keep `pandas` when the team/ecosystem already standardizes on it.

### Security — dependency cooldown

PyPI attacks are often caught and pulled within 24-48h but remain installable same-day. `uv` can ignore versions newer than a cooldown window:

```toml
[tool.uv]
exclude-newer = "7 days"
# emergency override for a specific package (e.g. an urgent CVE fix):
# exclude-newer-package = { some-package = false }
```

- **7 days is a commonly recommended default.** A stricter 14-day window is also a reasonable, equally valid choice for teams wanting more margin — pick one, don't leave it unset on a new project.
- Set it in `pyproject.toml` for a per-project value, or `~/.config/uv/uv.toml` for a personal global default.
- **`pip-audit`** (or `uv`'s equivalent lockfile-scanning workflow) for the complementary check: not "is this version too fresh" but "does anything in the lockfile have a *known, published* CVE." Run in CI, not necessarily on every commit — it hits a vulnerability database over the network and is slower than a pre-commit hook should be.

## Linting, formatting, and type checking

- **`ruff format`** replaces `black`; **`ruff check`** replaces `flake8`/`isort`/`pyupgrade`/`bandit`/etc. One Rust binary, 800+ rules; rarely reach for the old tools individually.
- Select rule groups deliberately rather than turning on everything at once — a solid starting set, each as its own named pre-commit hook so failures are legible: imports (`I`), complexity (`C90`), pycodestyle/pyflakes (`E,F,W`), bugbear (`B`), pyupgrade (`UP`), simplify (`SIM`), comprehensions/misc (`C4,PIE,RET,ISC`), logging (`LOG,G`), pathlib (`PTH`), datetime-tz (`DTZ`), pandas-vet (`PD`, only if pandas is in use), bandit security (`S`). Drop groups that don't apply.
- **Types — three real options, pick based on what you need:**
  - **`mypy`** — the reference implementation, most compatible with the plugin ecosystem (Pydantic, SQLAlchemy, Django ORM plugins). Still the safest default CI gate.
  - **`pyright`** (Microsoft) — faster and stricter than mypy, no plugin system of its own but excellent inference; it's what powers Pylance in VS Code, so it's the dominant *editor* type checker even on projects that gate CI with mypy.
  - **`ty`** (Astral, Rust, same toolchain family as `ruff`/`uv`) — 10-100x faster than either, but still beta: lower spec conformance than mypy and no plugin system, so it can't yet fully replace mypy on plugin-dependent code. Good for fast local/pre-commit feedback today; reassess as it matures.
  - Running two of the three (fast one locally/pre-commit, `mypy` in CI) is a reasonable middle ground, not overkill.
- **Dead code and dependency hygiene**: `vulture` finds unreferenced code; `deptry` finds declared-unused or used-undeclared dependencies. Cheap wins on mature projects.
- **Security**: `ruff --select=S` (bandit-equivalent rules) covers most of what standalone `bandit` catches — eval use, weak crypto, `subprocess(shell=True)`, hardcoded secrets — in the same pass as everything else. Reach for `semgrep` only when a project needs deeper, cross-file dataflow-aware SAST that pattern-based tools can't do.

## prek (pre-commit) automation

Run the checks above on every commit, not just when someone remembers to:

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: check-added-large-files
      - id: check-toml
      - id: check-yaml
      - id: check-merge-conflict
      - id: debug-statements
      - id: detect-private-key
      - id: end-of-file-fixer
      - id: trailing-whitespace

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.14.1
    hooks:
      - id: ruff-format
        types_or: [python, pyi]
      - id: ruff-check
        args: ["--fix", "--exit-non-zero-on-fix"]
        types_or: [python, pyi]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.13.0
    hooks:
      - id: mypy
        pass_filenames: false
        require_serial: true

  # Auxiliary files every project accumulates, not just .py — Docker/Markdown/JSON/YAML/spelling
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

- Run via `prek run --files <changed files>` before committing, don't wait for the hook to catch it.
- Pinned `rev`s rot — run `prek autoupdate` periodically (or after copying this template) rather than hand-tracking versions.
- Add `sqlfluff` hooks if the project has raw SQL. Keep `pip-audit`/full `mypy` runs in CI rather than every commit if they're too slow to be a comfortable pre-commit gate.
- Auxiliary hooks belong in the same config: real projects have Dockerfiles, markdown, JSON/YAML, and typos. `typos` catches misspellings with low false positives and supports `_typos.toml` allowlists. `rumdl` owns Markdown format + lint; do not also run prettier on `.md`. Keep prettier scoped to JSON/YAML.

## just — task runner

One command surface for humans and CI; nobody remembers raw `uv run python -m ...` incantations.

```just
set dotenv-load

default:
    @just --list --unsorted

# Install deps from uv.lock
sync:
    uv sync

# Re-resolve and update uv.lock
lock:
    uv lock

test *ARGS:
    uv run pytest {{ARGS}}

coverage:
    uv run pytest --cov=src --cov-report=term-missing

lint:
    uv run ruff check .
    uv run ruff format --check .
    uv run ty check   # or `uv run mypy .` — see "types" above

fmt:
    uv run ruff format .
    uv run ruff check --fix .
```

- For anything that needs to behave the same on a teammate's Windows machine and a Linux CI box: `set dotenv-load` to pick up `.env`, `if os_family() == "windows" { ... } else { ... }` for cross-platform recipe bodies, `[unix]`/`[windows]` recipe attributes when a recipe's body itself differs, `*ARGS` for variadic passthrough args. Reach for these once cross-platform actually matters, not preemptively.
- Recipes that write output should default to a local dir (`out/`, gitignored) and require an explicit flag/different recipe to hit prod — don't make the convenient default recipe the dangerous one.

## Changelog / release

If commits follow Conventional Commits, derive `CHANGELOG.md` and semver tags with `git-cliff`: `changelog` regenerates, `release` bumps from `feat`/`fix`/`!`, commits/tags, and never pushes. Use commitizen/semantic-release only when commit-time enforcement is the ask.

## CLI

- **`typer`** for new CLIs — type-hint-driven (arguments/options come from function signatures), built on `click`, renders help via `rich` for free. Prefer it over hand-rolled `argparse` for anything beyond a trivial single-flag script.
- Wire the command up as an entry point so `myproject` exists on PATH after install (this is what the Dockerfile's `ENTRYPOINT ["myproject"]` below relies on):

  ```toml
  [project.scripts]
  myproject = "myproject.cli:app"
  ```

- **`pydantic`** for config/input validation — parse untrusted input (CLI JSON blobs, API responses, config files) into a `BaseModel` at the boundary instead of trusting raw dicts deeper in the code.
- The CLI-UX rules in `shell-guidelines` (TTY-aware output, `--json`, exit-code contract, JSON error envelopes, confirmation only on a TTY — all straight from clig.dev) apply here unchanged — `typer`/`rich` give you the TTY detection and formatting for free; you still own designing the flag surface and error/exit-code contract the same way.

## Testing

- `pytest` + `pytest-cov`. Mirror `tests/` structure to `src/myproject/`.
- Mark slow or environment-dependent tests opt-in rather than skipping them silently:

  ```toml
  [tool.pytest.ini_options]
  addopts = ["-m", "not integration and not slow"]
  markers = [
    "integration: hits a live external dependency; opt-in via `pytest -m integration`",
    "slow: expensive to run; opt-in via `pytest -m slow`",
  ]
  ```

  Default run stays fast and hermetic; CI or a manual `just test-full` opts into the slow/live-dependency ones explicitly.

## Testing LLM-generated code

LLM-written code can look plausible while being subtly wrong, and its tests often cover only the happy path it just wrote. Add checks that do not depend on the generator's own judgment:

- **Golden-file (snapshot) tests** — pin known-good output (a JSON response, a rendered report, a CLI's output) to a checked-in file; `syrupy` is the standard pytest plugin. Any diff — including a "helpful" refactor that quietly changes output shape — fails loudly and requires explicit re-approval of the new golden file. This is the single highest-leverage guardrail against an agent silently changing behavior while "just cleaning up."
- **Property-based tests** (`hypothesis`) — generate a wide input space instead of the 2-3 examples a model writes for itself; catches edge cases the generator never had to think about. Especially valuable for parsing/serialization code, where an LLM's own examples are usually well-formed input only.
- **Fuzzing** (`atheris`, Google's libFuzzer-based fuzzer for Python) for anything parsing untrusted or structured input — same rationale as Go's native fuzzing.
- **Mutation testing** (`mutmut`, `cosmic-ray`) — deliberately breaks the code under test and checks whether the existing suite actually fails. This directly answers the most common LLM-authored-test failure mode: a test that calls the function and asserts something trivially true, showing full coverage while verifying nothing. Run periodically (it's slow), not on every commit.
- **End-to-end, against the real artifact** — a test that runs the actually-installed CLI/package via subprocess, not one that imports internal functions directly. Catches wiring bugs (wrong entry point, missing dependency, a config path that only worked in the dev sandbox) that unit tests structurally can't see, and that an agent's own "I ran the tests and they pass" claim doesn't cover.

## CI / infra / Docker placement

- CI config lives at the repo root in whatever the org's CI expects (`.github/workflows/*.yml`, `bitbucket-pipelines.yml`, etc.) — not buried in a subfolder.
- `Dockerfile` at repo root. `docs/` for design/runbook markdown, kept next to the code it documents, not in a separate wiki that drifts.

### Sample Dockerfile (uv, multi-stage)

```dockerfile
FROM python:3.13-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
WORKDIR /app

# Copy dependency files first so this layer caches across source changes
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev

COPY . .
RUN uv sync --frozen --no-editable --no-dev

FROM python:3.13-slim
RUN useradd -m appuser
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
USER appuser
ENTRYPOINT ["myproject"]
```

- Copy dependency files before source so deps reinstall only when `pyproject.toml`/`uv.lock` change.
- `--no-editable` installs the project into `.venv` itself, so the final stage copies only `.venv` — no `src/` copy, no build toolchain in the image.
- Non-root user in the final stage. Don't run as root in a container that doesn't need it.
- 12-factor's disposability/dev-prod-parity principles apply directly to the container: fast, clean startup, no state that survives a restart the app doesn't own, same image promoted through environments rather than rebuilt per-environment.
