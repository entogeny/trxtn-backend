# trxtn-backend

Rails 8 API backend.

## Requirements

- Ruby 3.4.1 ([asdf](https://asdf-vm.com/) recommended)
- Docker (for PostgreSQL)

## Setup

```bash
bin/setup
```

This will copy `.env.example` to `.env`, install gems, start PostgreSQL via Docker, and create/migrate the database. Update `.env` with your credentials if needed before running.

## Running

```bash
bin/rails server
```

## Database

```bash
bin/rails db:migrate          # run pending migrations
bin/rails db:reset            # drop, recreate, and migrate
```

## Tests

```bash
rspec spec/unit          # fast unit tests only
rspec spec/integration   # integration tests only
rspec                    # full suite
```

Unit specs test models and services in isolation. Integration specs test complete auth flows through the full HTTP stack.

See [documentation/design_choices/testing.md](documentation/design_choices/testing.md) for the full rationale.

## Test Credentials

The test JWT secret lives in `config/credentials/test.yml.enc`. To run tests on a new machine you will need `config/credentials/test.key`. Keep this key in a shared password manager — if it is lost, the test credentials file must be re-created.

To edit test credentials:

```bash
EDITOR="your_editor" bin/rails credentials:edit --environment test
```
