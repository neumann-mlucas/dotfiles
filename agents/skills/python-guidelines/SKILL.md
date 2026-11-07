---
name: python-guidelines
description: Project-level Python guidelines — src/ layout, uv (+ dependency cooldown), ruff/ty/mypy, prek, just, typer/pydantic CLIs, pytest markers, testing LLM-generated code, Dockerfile/CI placement. Trigger on "new python project", "python project layout", "set up a python repo", "pyproject.toml", "python best practices", starting/restructuring a Python codebase, or adding tests/lint/type-check/pre-commit config to one (not a one-off script — see `shell-guidelines` for that).
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

Repo-wide harness — `AGENTS.md`, spec dirs, module size, `just check` done-gate, auxiliary prek hooks, changelog, guardrails for LLM-written code: see `repo-harness`.

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
- **`uv audit`** for the complementary check: not "is this version too fresh" but "does anything in the lockfile have a *known, published* CVE." Run in CI, not necessarily on every commit — it hits a vulnerability database over the network and is slower than a pre-commit hook should be.

## Linting, formatting, and type checking

- **`ruff format`** replaces `black`; **`ruff check`** replaces `flake8`/`isort`/`pyupgrade`/`bandit`/etc. One Rust binary, 800+ rules; rarely reach for the old tools individually.
- Select rule groups deliberately in `[tool.ruff.lint] select = [...]` rather than turning on everything at once — a solid starting set: imports (`I`), complexity (`C90`), pycodestyle/pyflakes (`E,F,W`), bugbear (`B`), pyupgrade (`UP`), simplify (`SIM`), comprehensions/misc (`C4,PIE,RET,ISC`), logging (`LOG,G`), pathlib (`PTH`), datetime-tz (`DTZ`), pandas-vet (`PD`, only if pandas is in use), bandit security (`S`). Drop groups that don't apply.
- **Types — three real options, pick based on what you need:**
  - **`mypy`** — the reference implementation, most compatible with the plugin ecosystem (Pydantic, SQLAlchemy, Django ORM plugins). Still the safest default CI gate.
  - **`pyright`** (Microsoft) — faster and stricter than mypy, no plugin system of its own but excellent inference; it's what powers Pylance in VS Code, so it's the dominant *editor* type checker even on projects that gate CI with mypy.
  - **`ty`** (Astral, Rust, same toolchain family as `ruff`/`uv`) — 10-100x faster than either, but still beta: lower spec conformance than mypy and no plugin system, so it can't yet fully replace mypy on plugin-dependent code. Good for fast local/pre-commit feedback today; reassess as it matures.
  - Running two of the three (fast one locally/pre-commit, `mypy` in CI) is a reasonable middle ground, not overkill.
- **Dead code and dependency hygiene**: `vulture` finds unreferenced code; `deptry` finds declared-unused or used-undeclared dependencies. Cheap wins on mature projects.
- **Security**: `ruff check --select S` (bandit-equivalent rules) covers most of what standalone `bandit` catches — eval use, weak crypto, `subprocess(shell=True)`, hardcoded secrets — in the same pass as everything else. Reach for `semgrep` only when a project needs deeper, cross-file dataflow-aware SAST that pattern-based tools can't do.

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
    rev: v0.17.4
    hooks:
      - id: ruff-format
        types_or: [python, pyi]
      - id: ruff-check
        args: ["--fix", "--exit-non-zero-on-fix"]
        types_or: [python, pyi]

  # local, not mirrors-mypy: the mirror runs in an isolated env and can't see project deps
  - repo: local
    hooks:
      - id: mypy
        name: mypy
        entry: uv run mypy .
        language: system
        types: [python]
        pass_filenames: false
        require_serial: true

  # + auxiliary hooks (typos, rumdl, prettier, hadolint, gitleaks, actionlint, zizmor): copy the block from `repo-harness`
```

- Run via `prek run --files <changed files>` before committing, don't wait for the hook to catch it.
- Pinned `rev`s rot — run `prek autoupdate` periodically (or after copying this template) rather than hand-tracking versions.
- Add `sqlfluff` hooks if the project has raw SQL. Keep `uv audit`/full `mypy` runs in CI rather than every commit if they're too slow to be a comfortable pre-commit gate.

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

# Include integration/slow tests (drops the default -m filter from addopts)
test-full:
    uv run pytest -o addopts=""

# Done-gate for humans, agents, and CI
check: lint test

lint:
    uv run ruff check .
    uv run ruff format --check .
    uv run mypy .   # same gate as the prek hook; `uvx ty check` for a faster local pass

fmt:
    uv run ruff format .
    uv run ruff check --fix .
```

- For anything that needs to behave the same on a teammate's Windows machine and a Linux CI box: `set dotenv-load` to pick up `.env`, `if os_family() == "windows" { ... } else { ... }` for cross-platform recipe bodies, `[unix]`/`[windows]` recipe attributes when a recipe's body itself differs, `*ARGS` for variadic passthrough args. Reach for these once cross-platform actually matters, not preemptively.
- Recipes that write output should default to a local dir (`out/`, gitignored) and require an explicit flag/different recipe to hit prod — don't make the convenient default recipe the dangerous one.

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

Why and when: `repo-harness`. Python tools:

- golden/snapshot: `syrupy`
- property-based: `hypothesis`
- fuzzing: `atheris`
- mutation: `mutmut` (periodic, slow)
- e2e: run the installed CLI via `subprocess`, not internal imports

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
