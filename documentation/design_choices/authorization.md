# Authorization — Design Choices

## Pundit for Policy Objects

Authorization logic lives in dedicated policy classes under `app/policies/`, using the [Pundit](https://github.com/varvet/pundit) gem. Each model has a corresponding policy (e.g. `EventPolicy` for `Event`) that defines which actions a given user may perform on a given record.

Policy objects are plain Ruby classes — no DSL, no macros. They are easy to read, easy to test in isolation, and have no implicit behavior.

## Principle of Least Access

`ApplicationPolicy` defaults every action (`index?`, `show?`, `create?`, `update?`, `destroy?`) to `false`. Subclasses explicitly opt in to the actions they permit. A policy that forgets to define a rule denies access — the safe default.

This prevents authorization gaps when new actions or policies are added. An uncovered action fails closed, not open.

## Authorization at the Controller Layer

`authorize` is called explicitly at the top of each controller action, before any service or business logic runs. This ensures that an unauthorized request is rejected immediately without performing unnecessary work.

```ruby
def index
  authorize Event, :index?

  service = Events::IndexService.new
  # ...
end
```

## Unauthorized Responses

`Pundit::NotAuthorizedError` is rescued in the `Errorable` concern and rendered as a `403 Forbidden` response with a consistent error body, matching the format of all other error responses in the API.

## No Record-Level Ownership Yet

The `events` table currently has no `user_id` or `creator_id` column. Ownership-based rules (e.g. "only the creator can update their event") will be added to `EventPolicy` once that association exists. The policy structure is in place and ready to receive those rules.
