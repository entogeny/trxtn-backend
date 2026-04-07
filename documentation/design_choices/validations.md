# Validations

## Model vs service

Models own record-internal invariants — constraints that depend only on the record's own fields, hold true in any context, and must be enforced on every save regardless of who is doing it or why. Examples: `end_at > start_at`, presence of required fields.

Services own operation-scoped or context-dependent rules — anything that references external state, or that only applies to one operation type. Example: `start_at` must be in the future on create, but not on update.

The practical test: does this rule depend on anything outside the record's own fields? If no → model. If yes → service.

`Base::SaveService` is the bridge: it calls `record.save`, which triggers all AR model validations automatically. Model-level errors surface as service errors with no extra code. Services should not duplicate model-level checks.
