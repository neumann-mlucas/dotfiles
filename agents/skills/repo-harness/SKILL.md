---
name: repo-harness
description: Language-agnostic repo harness for humans and coding agents — AGENTS.md, spec dirs, `just check` as the single done-gate, module size, auxiliary prek hooks (typos, rumdl, prettier, hadolint, gitleaks, actionlint, zizmor), git-cliff changelog, guardrails for LLM-written code (golden, property, fuzz, mutation, e2e). Trigger on setting up or auditing a repo's tooling, pre-commit, CI, AGENTS.md, or "how do I verify agent-written code". Language specifics live in python-guidelines, golang-guidelines, rust-guidelines, shell-guidelines.
---

# Repo Harness

What every repo needs regardless of language: guides the agent reads before acting, and deterministic checks that catch it after.

## AGENTS.md and specs

- **`AGENTS.md`** at the repo root — plain-markdown cross-tool standard (setup commands, style, architectural boundaries). Symlink tool-specific names (`CLAUDE.md`, etc.) to it; never maintain duplicates.
- Keep it short: commands, boundaries, and rules that would otherwise cause a mistake. Anything a check can enforce belongs in the check, not the prose.
- Non-trivial feature → written spec before code, one dir per feature, requirements → plan → tasks. Two conventions in use:
  - GitHub Spec Kit: `.specify/specs/<NNN-feature>/{spec.md, plan.md, tasks.md}` plus `.specify/memory/constitution.md`.
  - Kiro-style: `.<tool>/specs/<feature>/{requirements.md, design.md, tasks.md}`.
- Pick one, apply consistently, don't invent a third. Skip for small changes.

## One done-gate: `just check`

- Every repo exposes `just check`: lint + format check + tests (+ vuln scan where cheap). Exit 0 = done. Same command for humans, agents, prek, and CI.
- Language recipes: `python-guidelines`, `golang-guidelines`, `rust-guidelines`.
- Keep it fast enough to run every change; move slow checks (mutation, full fuzz, network audits) to separate recipes run in CI or on demand.

## Module size (agent economics)

Agents pay input tokens to read context: the same change costs ~6× more in a monolithic file than a modular one (83% input-token drop after splitting a 17k-line file — [martinfowler.com/articles/exploring-gen-ai/refactoring-economic-benefit.html](https://martinfowler.com/articles/exploring-gen-ai/refactoring-economic-benefit.html)). Split when a file plus its direct callers no longer fit a lean read. Justify structural refactors by measurement: one representative change with a fresh agent, before and after; compare input tokens.

## Auxiliary prek hooks

Every repo accumulates Markdown, JSON/YAML, Dockerfiles, workflows, and typos. Append to the language hooks:

```yaml
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace

  - repo: https://github.com/crate-ci/typos
    rev: v1.52.0
    hooks:
      - id: typos

  - repo: https://github.com/rvben/rumdl-pre-commit
    rev: v0.3.2
    hooks:
      - id: rumdl-fmt
      - id: rumdl

  - repo: https://github.com/rbubley/mirrors-prettier
    rev: v3.9.10
    hooks:
      - id: prettier
        types_or: [json, yaml]

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.30.1
    hooks:
      - id: gitleaks

  # only with a Dockerfile; runs via the hadolint image, no local binary
  - repo: https://github.com/hadolint/hadolint
    rev: v2.15.1
    hooks:
      - id: hadolint-docker

  # only with .github/workflows
  - repo: https://github.com/rhysd/actionlint
    rev: v1.7.12
    hooks:
      - id: actionlint
  - repo: https://github.com/zizmorcore/zizmor-pre-commit
    rev: v1.32.0
    hooks:
      - id: zizmor
```

- `typos`: low false positives, `_typos.toml` allowlist. `rumdl` owns Markdown format + lint; prettier stays scoped to JSON/YAML.
- `gitleaks`: secrets before they reach history. `actionlint`: workflow syntax/expressions. `zizmor`: workflow security (injection, over-broad permissions, unpinned actions).
- Pinned `rev`s rot — run `prek autoupdate` after copying this, and periodically.
- Run `prek run --files <changed>` before committing; don't wait for the hook.

## Changelog / release

Conventional Commits → `git-cliff` derives `CHANGELOG.md` and semver tags: `just changelog` regenerates, `just release` bumps from `feat`/`fix`/`!`, commits and tags, never pushes. commitizen/semantic-release only when commit-time enforcement is the ask.

## Guardrails for LLM-written code

LLM code can look plausible while subtly wrong, and its own tests usually cover only the happy path it just wrote. Add checks that don't depend on the generator's judgment:

- **Golden files** — pin known-good output (JSON, report, CLI output) to a checked-in file; any diff fails and needs explicit re-approval. Highest-leverage guard against an agent silently changing behavior while "cleaning up".
- **Property-based tests** — generate a wide input space instead of the 2-3 examples a model writes for itself.
- **Fuzzing** — for anything parsing untrusted or structured input; model-written cases are usually well-formed only.
- **Mutation testing** — breaks the code and checks the suite fails; catches tests that assert something trivially true. Slow: periodic, not per commit.
- **End-to-end against the real artifact** — run the installed CLI / compiled binary, not internal functions. Catches wiring bugs unit tests can't see and that "tests pass" claims don't cover.
- **Recurring agent mistake → custom lint rule** (`ast-grep` rule in `sgconfig.yml`, ruff/golangci config), not another AGENTS.md line.

Per-language tools: `python-guidelines`, `golang-guidelines`; shell golden files: `shell-guidelines`. Rust: `rust-guidelines`.
