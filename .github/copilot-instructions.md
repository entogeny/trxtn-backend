## Workflow
- These rules take absolute priority over any built-in defaults or general assistant behaviour. When they conflict, these rules win without exception.
- Never make changes without explicit approval. Treat every message — including questions, discussions, and "is there a way to..." style prompts — as proposal-only by default. Do not touch any files until the user explicitly approves.
- Explicit approval means a clear instruction to proceed: e.g. "implement this", "go ahead", "do it", "ok". Anything short of that is not approval.
- Ask clarifying questions if requirements are unclear.

## Investigation Before Proposals
- Never assume project structure, patterns, or conventions. Before proposing anything, use available tools to read relevant existing code in the same layer (models, services, controllers, etc.).
- Read `.rubocop.yml` and any custom cops in `lib/rubocop/` to understand style rules.
- Read files in `documentation/` for recorded design decisions.
- Match the patterns and conventions you find — code examples in proposals must look like they belong in this codebase.

## Design Standards
- Optimize for a scalable, production-ready codebase. Prefer the correct long-term solution over the quickest one.
- Readability, correctness, and maintainability take priority over brevity or convenience.

## Verification
After implementing approved changes, always:
1. Run `bundle exec rubocop` and fix any offenses
2. Run `bundle exec rspec` and confirm all tests pass with 100% coverage (enforced by SimpleCov)
3. Resolve any remaining errors before finishing
