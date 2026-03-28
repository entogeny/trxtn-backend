# Soft Delete — Design Choices

## What Soft Delete Is

Soft delete is a deletion strategy where a record is marked as deleted by setting a `deleted_at` timestamp rather than being permanently removed from the database. The record remains in the database but is excluded from normal queries.

Hard delete (`record.destroy`) permanently removes the row. Soft delete (`record.soft_delete`) retains it.

## Why Soft Delete

At production scale, permanently destroying data by default creates problems that are expensive to fix after the fact:

- **Accident recovery** — accidental deletions happen. Soft delete provides a recovery path without restoring from backups.
- **Audit trails** — many compliance contexts (SOC 2, GDPR-adjacent) require knowing what happened to data. A hard-deleted row leaves no trace.
- **Referential integrity** — foreign keys pointing to hard-deleted records break. Soft delete keeps the row alive so related records remain coherent.
- **Historical reporting** — deleted entities often still need to appear in historical data (e.g. a deleted user's past activity).

## Why Not a Gem

Two gems are commonly used for soft delete in Rails: `paranoia` and `discard`.

**`paranoia` was rejected** because it overrides `destroy` silently. After including it, `record.destroy` no longer destroys — it sets `deleted_at`. This breaks the expectations of any code that calls `destroy` directly, causes surprising behaviour with `dependent: :destroy` associations, and makes the codebase harder to reason about. It is also in maintenance-only mode.

**`discard` is better designed** — it does not pollute `destroy` — but it introduces its own vocabulary (`kept`, `discarded`, `discard`, `undiscard`) that has no natural relationship to how we talk about deletion in this codebase.

The custom `SoftDeletable` concern is approximately the same amount of code as either gem, is fully understood by the team, carries no external dependency risk, and uses naming that is consistent with the rest of the codebase.

## Why `SoftDeletable` Is a Concern, Not in `ApplicationRecord`

Including `SoftDeletable` in `ApplicationRecord` would mean every table in the database needs a `deleted_at` column — including join tables, internal Rails tables, queue tables, and cable tables. Most of these should never be soft-deleted.

`SoftDeletable` is instead included explicitly per model. This makes soft delete capability visible at the model definition and prevents unintentional scope pollution on tables that don't need it.

## No Default Scope

`default_scope` was explicitly rejected. While it would automatically filter soft-deleted records from all queries, the consequences are harmful:

- `User.count` silently excludes soft-deleted records, making basic queries misleading
- The `.soft_deleted` scope produces contradictory SQL when combined with the default scope (`WHERE deleted_at IS NULL AND deleted_at IS NOT NULL`)
- Joins and eager loads silently inherit the scope, causing subtle and hard-to-trace bugs
- Overriding it requires `.unscoped`, which strips all scopes — a blunt instrument

Filtering soft-deleted records is instead applied explicitly in the service layer via `base_scope`, which checks whether the model includes `SoftDeletable` and applies `.not_soft_deleted` accordingly. The filter is visible at the point it is applied.

## Naming: `not_deleted` / `deleted`

Several naming options were considered for the scopes and predicate methods:

- **`kept` / `discarded`** — rejected. This is vocabulary borrowed from the `discard` gem. It introduces unfamiliar terminology without any meaning advantage.
- **`active` / `deleted`** — rejected. `active` is reserved for a potential future deactivation feature, where a record is suspended rather than deleted. Conflating "not deleted" with "active" would cause a naming collision and blur two distinct product concepts.
- **`active` / `deactivated`** — appropriate for a deactivation feature, where a record can be suspended and reactivated. Distinct from deletion.
- **`not_deleted` / `deleted`** — chosen. Unambiguous, no domain collision, directly describes the state without introducing new vocabulary.

## Naming: `soft_delete` / `soft_undelete`

The instance methods on the concern follow the same logic:

- **`discard` / `undiscard`** — gem vocabulary, rejected
- **`soft_delete` / `restore`** — `restore` was rejected because it is ambiguous. "Restore" could describe restoring a backup, reactivating a suspended account, or other domain-specific recovery operations. It does not clearly mean "reverse a soft deletion."
- **`soft_delete` / `soft_undelete`** — chosen. The `soft_` prefix is consistent on both sides, and `undelete` unambiguously means "reverse a deletion." There is no confusion with any other feature.

## No Bang Variants on the Concern

The concern does not expose `soft_delete!` or `soft_undelete!`. These methods are called exclusively from the service layer (`DeleteService`, `UndeleteService`), which handles failure through its own error accumulation mechanism. The service layer does not need the model to raise exceptions on failure — it reads the return value and accumulates errors itself. Adding bang variants would create unused surface area.

## The `strategy:` Input on `DeleteService`

`DeleteService` accepts a `strategy:` input with values `:soft` (default) and `:hard`.

- **`:soft` is the default.** This reflects the product-level commitment that soft delete is the norm. Callers never need to pass `strategy:` for standard deletions. Hard delete requires an explicit, intentional declaration.
- **`:hard` is the escape hatch.** Used for GDPR erasure, background purge jobs, and other system-level operations that require permanent destruction. It is never passed from REST controllers.
- **`strategy:` over `force: true`.** A boolean `force: true` is not self-documenting — `force` what? `strategy: :hard` reads clearly at the call site and is consistent with Rails naming conventions for option hashes.

## `UndeleteService` Is a Standalone Service

Undelete could have been implemented as a parameter on `DeleteService` (e.g. `action: :undelete`). It was instead built as a separate `Base::UndeleteService` for these reasons:

- **Single responsibility.** `DeleteService` deletes. `UndeleteService` restores. Each has a clear, singular purpose consistent with how all other base services are named and scoped.
- **Distinct failure modes.** `UndeleteService` must validate that the model supports soft delete, that the record is currently deleted, and crucially, it must bypass `FindService` — because `FindService` explicitly excludes deleted records, `UndeleteService` cannot use it to locate a record it needs to restore.
- **Symmetry.** The service layer gains a symmetrical pair: `DeleteService` / `UndeleteService`, mirroring `CreateService` / `DeleteService` as inverse operations.

## `UndeleteService` Bypasses `FindService`

`FindService` scopes queries to `.not_soft_deleted` for soft-deletable models. This is correct behaviour for all normal lookups. However, `UndeleteService` needs to find a record that is, by definition, deleted. It therefore queries the model directly (`model.find_by(id:)`) rather than delegating to `FindService`. This is intentional and documented in the service.

## `FindService` and `IndexService` Scope to `.not_soft_deleted`

Both services use a `base_scope` method that checks whether the model includes `SoftDeletable`. If it does, the query is scoped to `.not_soft_deleted`. If not, it falls back to `model.all`.

This means: a `FindService` call with the ID of a soft-deleted record behaves as "not found" — correctly, from the perspective of any API consumer. Soft-deleted records are invisible to normal lookups.
