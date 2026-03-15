# Testing Design Choices

## Gems

- **rspec-rails** — test framework
- **factory_bot_rails** — test data factories
- **faker** — realistic fake data for factories

`shoulda-matchers` was considered but not adopted. All assertions use plain `expect` style throughout for consistency and to keep tests explicit about what the user actually experiences (e.g. the exact error message), rather than testing only that a validation macro was declared.

## Directory Structure

```
spec/
  unit/         # isolated tests, collaborators stubbed where applicable
  integration/  # full-stack tests through HTTP, feature-organized
  factories/
  support/
```

Folder separation was chosen over RSpec tags (`:unit`, `:integration`). Folders are unambiguous — the directory tells you what kind of test you are reading or writing without needing to check metadata. Tests can be run selectively with:

```bash
rspec spec/unit          # fast feedback loop
rspec spec/integration   # full flows
rspec                    # everything
```

## Unit vs Integration

**Unit specs** (`spec/unit/`) test a single class in isolation. For service classes, collaborators are stubbed using RSpec mocks. A failure in a unit spec points directly at the class under test.

**Integration specs** (`spec/integration/`) test complete user-facing flows end-to-end through the HTTP stack: routing → controller → services → database → response. They are organized by feature (e.g. `spec/integration/auth/`) rather than by technical layer, reflecting what the tests are actually verifying.

There is no intermediate "service integration" layer. The unit specs cover each service class, and the integration request specs cover the full chain. A dedicated service-level integration test would overlap with both without adding meaningful coverage.

**When to add a new test:**
- New model validation or association → `spec/unit/models/`
- New service class → `spec/unit/services/` (stub collaborators)
- New controller action or auth flow → `spec/integration/` (feature folder)

## Service Stub Policy

In unit specs, all collaborators are stubbed. For example, `RotateService` calls both `IssueService` and `EncodeService`. In its unit spec, both are stubbed with `allow(...).to receive(:call).and_return(...)`. The test exercises only `RotateService`'s own logic: token lookup, error conditions, revocation, and transaction rollback.

The integration specs for the same flow (`spec/integration/auth/token_refresh_spec.rb`) run without any stubs.

## Module Wrapper Syntax

Service specs use Ruby `module` blocks to wrap `RSpec.describe`:

```ruby
module Auth
  module RefreshTokens
    RSpec.describe RotateService do
      ...
    end
  end
end
```

This mirrors the structure of the production service files, which are also defined using `module` blocks. It is a stylistic consistency choice.

Note: `describe` blocks alone do not change Ruby's `Module.nesting` — only real `module` blocks do. In practice, all cross-service references in this codebase use full constant paths (e.g. `Auth::RefreshTokens::IssueService`) even where shorter references would resolve, so the scoping benefit of module wrappers is secondary to the style consistency benefit.

## JWT Secret in Test Credentials

The JWT secret for tests lives in `config/credentials/test.yml.enc`, loaded automatically when `RAILS_ENV=test`. It has no overlap with the development or production credential files — each environment has its own encrypted file and its own key.

This approach was chosen over alternatives because:
- **vs. env variable fallback** — test credentials require no changes to the service code and are idiomatic Rails
- **vs. stubbing the credential call** — real credentials mean the services are exercised as they are in production

The key file (`config/credentials/test.key`) must be available on every development machine and CI environment. Keep it in a shared password manager. If it is lost, run `bin/rails credentials:edit --environment test` to regenerate the file with a new key.

## Database Isolation

RSpec's default transaction-based isolation is used (`config.use_transactional_fixtures = true`). Each example runs inside a transaction that is rolled back after the example completes, leaving the database clean. No additional gem (`database_cleaner`) is used. If isolation issues arise with request specs, `database_cleaner-active_record` can be introduced at that point.

## Support Helpers

**`spec/support/factory_bot.rb`** — includes `FactoryBot::Syntax::Methods` globally so `create`, `build`, `build_stubbed` etc. are available in all specs without a prefix.

**`spec/support/request_helpers.rb`** — provides two helpers included in all request specs (type `:request`):

- `json` — parses `response.body` as JSON with indifferent access
- `auth_headers(user)` — generates a valid `Authorization: Bearer <token>` header for a given user, useful for testing protected endpoints

All files in `spec/support/` are auto-required by `rails_helper.rb`.

## Bootstrapping on a New Machine

1. `bundle install`
2. Obtain `config/credentials/test.key` from the team password manager and place it in the project root
3. `bin/rails db:test:prepare`
4. `rspec` to verify everything passes
