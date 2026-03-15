# Git Hooks

Git hooks are configured via `core.hooksPath = .github/hooks`, set automatically by `bin/setup`. This keeps hooks version-controlled and shared across all contributors.

## pre-push

Runs the full `bin/ci` suite before any push. This is the last line of defense before code reaches the remote.

## pre-commit

Runs all checks except environment bootstrap (`bin/setup`) before each commit:

- `bundle exec rspec` — full test suite
- `bin/rubocop` — style enforcement
- `bin/bundler-audit` — known CVEs in dependencies
- `bin/brakeman` — static security analysis

### Rationale

As AI-assisted development increases, so does the risk of subtle, AI-introduced regressions — logic errors, broken contracts, security gaps — that look syntactically correct. Catching these at commit time, rather than at push or CI, is intentional:

- **Context is live.** The AI agent that wrote the code still has full context to diagnose and fix the failure immediately, before the working set changes.
- **Faster feedback loop.** A failing commit surfaces the issue in seconds rather than minutes (push → CI pipeline → notification).
- **Cheap escape hatch.** `git commit --no-verify` remains available for mechanical commits (formatting, comments, documentation) where running the suite adds no value.

Environment setup steps (`bundle install`, `db:prepare`, etc.) are deliberately excluded. By commit time the environment is already running; bootstrapping on every commit adds noise without adding safety.
