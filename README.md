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
bin/rails test
```
