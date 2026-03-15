# Services — Design Choices

## What a Service Is

A service object encapsulates a single unit of business logic. It is a plain Ruby class with no framework inheritance. It is not a model, not a controller, not a concern — it is the place where the work happens.

## Skinny Models, Skinny Controllers

Models define data structure, associations, and direct data validations. They do not contain business logic.

Controllers receive requests and render responses. They validate parameters, call the appropriate service, and render the result. They do not contain business logic.

All business logic lives in services.

This separation means:
- Logic is testable in isolation without loading the full request/response cycle
- Controllers and models remain readable — they describe structure and orchestration, not behaviour
- Logic is reusable — a service can be called from a controller, a background job, a rake task, or a console without duplication

## Single Purpose

Each service does exactly one thing. The name of the class fully describes that one thing.

If a service is doing two things, it should be two services. If you find yourself naming a service `ProcessAndNotifyService`, that is two services: `ProcessService` and `NotifyService`.

## The `.call` Convention

Services expose a single public class method: `.call`.

```ruby
Auth::AccessTokens::EncodeService.call({ sub: user.id })
Auth::RefreshTokens::IssueService.call(user)
```

**Why `.call` and not a descriptive method name?**

The class name is the verb. `Auth::RefreshTokens::IssueService.call` reads as "call the issue service". Adding `.issue` would be redundant: `Auth::RefreshTokens::IssueService.issue`.

`.call` is also the Ruby convention for callable objects. It works with procs, lambdas, and service objects uniformly, which makes services easy to compose and pass as arguments.

## Directory Structure

Services live at `app/services/`, organised by domain namespace.

```
app/services/
  auth/
    errors.rb
    access_tokens/
      encode_service.rb
      decode_service.rb
    refresh_tokens/
      issue_service.rb
      rotate_service.rb
      revoke_service.rb
```

Zeitwerk autoloads services automatically when the directory structure matches the module/class constant path. No `require` statements are needed.

## Naming Conventions

### File names use `_service` suffix

Every service file ends in `_service.rb`. This makes the purpose of the file unambiguous when browsing the codebase.

### Class names use `Service` suffix

Every service class ends in `Service`. This distinguishes service objects from models, value objects, and plain Ruby modules at a glance.

### Namespaces are singular domain concepts

A service namespace represents a domain model or domain concept, not a collection. The service name itself communicates scope.

```
Auth::RefreshTokens::RevokeService     ← revokes one refresh token
Auth::RefreshTokens::RevokeAllService  ← revokes all refresh tokens for a user
```

Both live under `Auth::RefreshTokens::` — the namespace does not change based on how many records the operation touches.

### Namespaces that mirror model names are pluralized

Ruby raises a `TypeError` if a namespace constant path exactly matches an ActiveRecord model constant path, because the model is a class and cannot be reopened as a module.

```ruby
# RefreshToken is an ActiveRecord model (a class)
# Auth::RefreshToken::IssueService would attempt to reopen RefreshToken as a module inside Auth::
# This is safe here because Auth::RefreshToken != RefreshToken
# But at the top level:

User::CreateService     # TypeError: User is not a module
Users::CreateService    # ✓ No collision — Users is not a defined constant
```

**Convention: any service namespace whose name matches a top-level model name is pluralized.**

This eliminates the collision structurally rather than relying on developer discipline with fully qualified paths.

### Namespaces describe concepts, not implementation details

```
Auth::AccessTokens::EncodeService    ✓
Auth::Jwt::EncodeService             ✗
```

If the underlying implementation changes (e.g. moving from JWT to a different token format), a concept-named namespace remains valid. An implementation-named namespace would require renaming the namespace and all its call sites.

## Error Handling

Services raise named error classes rather than returning error codes or nil. This keeps service code clean and puts error handling decisions in the caller.

```ruby
# In a service:
raise Auth::Errors::TokenExpired

# In the controller or before_action:
rescue Auth::Errors::TokenExpired
  render_unauthorized("Token has expired")
```

Domain-specific errors are defined as subclasses of `StandardError` and grouped by domain in an `errors.rb` file within the service namespace.
