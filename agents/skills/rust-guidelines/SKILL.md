---
name: rust-guidelines
description: Project-level Rust guidelines — crate/workspace layout, Cargo.toml lints and MSRV, justfile done-gate (fmt, clippy -D warnings, nextest), cargo-deny/machete, thiserror/anyhow, insta/proptest/cargo-mutants, plus the failure patterns agents actually hit in these repos (guessed crate APIs, borrow fights, recurring clippy lints). Trigger on "new rust project", "Cargo.toml", "cargo workspace", "clippy", "rust best practices", setting up tests/lint/CI in a Rust repo, or writing Rust that calls external crates (polars, ratatui, clap, tokio).
---

# Rust Project Guidelines

Project-level conventions: layout, tooling, and the mistakes that recur. Not a language tutorial. Repo-wide harness (AGENTS.md, aux hooks, LLM-test guardrails): `repo-harness`.

## Known failure patterns (mined from these repos' sessions)

Fix these before anything else — they account for most failed `cargo` runs.

1. **Guessed crate APIs** — `E0599` no method, `E0061` wrong arg count, `E0624` private method, `E0063` missing struct fields, `E0308` mismatched types; mostly polars. Before calling a crate API: read the version from `Cargo.lock`, then confirm the signature with LSP hover/go-to-definition or the source in `~/.cargo/registry/src/*/<crate>-<version>/`. Never write fast-moving APIs (polars, ratatui, clap, tokio) from memory.
2. **Borrow fights** — `E0596`, `E0716`, `E0521`. Restructure ownership instead of adding lifetimes: clone small data, split the borrow, return owned values, bind temporaries with `let`. Compile after each step, don't stack fixes.
3. **Recurring clippy lints** — `needless_range_loop`: iterate `.iter().enumerate()` / `.zip()`, not `for i in 0..v.len()`. `should_implement_trait`: an inherent `from_str`/`add`/`next`/`default` means implement the std trait instead.
4. **Unformatted code** — rustfmt diffs failed `cargo fmt --check` dozens of times. The post-edit hook runs rustfmt; run `cargo fmt` if editing outside it.
5. **Golden/replay test failures** — when a snapshot changes, show the diff and say why; never regenerate snapshots to make a test pass without review.

## Layout

- Single crate: logic in `src/lib.rs`, thin `src/main.rs` that parses args and calls the lib — integration tests in `tests/` can only reach a lib target.
- Workspace only once there are 2+ crates: virtual root manifest, members under `crates/`. Share settings via `[workspace.package]` (`edition`, `rust-version`), `[workspace.dependencies]`, `[workspace.lints]`; members inherit with `edition.workspace = true`, `lints.workspace = true`.
- New crates: `edition = "2024"`, explicit `rust-version`. Commit `Cargo.lock` (binaries and libraries).
- `rust-version` is a claim: this machine has pacman `rust`, not rustup, so test the MSRV in CI (`dtolnay/rust-toolchain@<msrv>`), not locally.

## Lints — in Cargo.toml, not CLI flags

```toml
[lints.rust]
unsafe_code = "forbid"

[lints.clippy]
all = { level = "warn", priority = -1 }
unwrap_used = "warn"
expect_used = "warn"
```

```toml
# clippy.toml
allow-unwrap-in-tests = true
allow-expect-in-tests = true
```

- Silence with `#[expect(clippy::lint_name, reason = "...")]`, not `#[allow]`: `expect` warns once the lint no longer fires, so stale suppressions surface. (Rule from apollographql/skills `rust-best-practices`, MIT.)
- `pedantic` only per-lint, after the codebase is clean; never blanket-enable on an existing repo.

## justfile — the done-gate

```just
default:
    @just --list --unsorted

build:
    cargo build --locked

# nextest skips doctests, so run them separately (drop the line for bin-only crates)
test *ARGS:
    cargo nextest run --locked {{ARGS}}
    cargo test --doc --locked

lint:
    cargo fmt --check
    cargo clippy --all-targets --all-features --locked -- -D warnings

deps:
    cargo deny check
    cargo machete

# Done-gate for humans, agents (Stop hook), and CI
check: lint test
```

- `cargo deny init` once to create `deny.toml` (advisories, licenses, duplicate versions). Keep `deps` out of `check` if it's slow or network-bound; run it in CI.
- `cargo machete` finds unused dependencies — run after removing code.

## Dependencies

- Ladder: std → existing dep → well-known crate. Each crate costs compile time and supply-chain surface.
- Errors: `thiserror` for library error enums, `anyhow` (with `.context(...)`) in binaries. No `unwrap`/`expect` on non-test paths (the lints above enforce it).
- CLI: `clap` derive. Async only when there is real I/O concurrency; otherwise plain threads/`rayon`.
- Before adding a feature flag to a dependency, check it's not already pulled in transitively (`cargo tree -e features -i <crate>`).

## Testing

- `cargo nextest run` for speed and terse failure output; doctests via `cargo test --doc`.
- Snapshots: `insta` — `cargo insta review`, accept only reviewed changes (see failure pattern 5).
- Property tests: `proptest` for parsers and anything with invariants.
- Fuzzing: `cargo fuzz` for untrusted-input parsers.
- Mutation testing: `cargo mutants`, periodic (slow), to catch tests that assert nothing.
- End-to-end: `assert_cmd` against the built binary, not internal functions.

## Further reference

`leonardomso/rust-skills` (MIT) — 265 language-level rules (ownership, async, API design). Large (~10k tokens); consult a specific rule file when needed instead of installing it.
