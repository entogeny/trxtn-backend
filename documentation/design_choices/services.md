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

## ApplicationService

All services inherit from `ApplicationService`. It provides a consistent I/O contract and centralised error handling so individual services only have to express their logic.

`ApplicationService` exposes:
- `input` — the hash passed to `initialize`
- `output` — a hash the service writes its result into
- `errors` — an array of `{ message: }` hashes accumulated during `call`
- `call` — yields a block, catches `ServiceError`, returns `true` on success and `false` on failure
- `success?` — `true` if `call` has been called and no errors were collected

Every service follows the same structure:

```ruby
class MyService < ApplicationService
  def initialize(input = {})
    super
  end

  def call
    super do
      # business logic here
      self.output = { result: computed_value }
    end
  end
end
```

Callers instantiate and call the service, then branch on the return value:

```ruby
service = Auth::RefreshTokens::IssueService.new(user: user)
if service.call
  service.output[:raw_token]
else
  service.errors
end
```

**Why an instance, not a class method?**

Instance-based services allow `output` and `errors` to live as clean instance state rather than being threaded through return values and exceptions. The caller always knows where to find the result (`service.output`) and any failures (`service.errors`) without coupling to the service's internal branching logic.

## The `.call` Convention

Services expose a single public instance method: `#call`.

**Why `.call` and not a descriptive method name?**

The class name is the verb. `Auth::RefreshTokens::IssueService#call` reads as "call the issue service". Adding `#issue` would be redundant: `Auth::RefreshTokens::IssueService.new(...).issue`.

`#call` is also the Ruby convention for callable objects. It works with procs, lambdas, and service objects uniformly, which makes services easy to compose and pass as arguments.

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

## Constant References

Within a service file, use the shortest unambiguous reference permitted by the lexical scope established by the surrounding `module` declarations. Do not repeat namespace segments that Ruby can already resolve from context.

```ruby
# Inside module Auth; module RefreshTokens:
IssueService.new(user: record.user)                    # ✓ Same namespace
AccessTokens::EncodeService.new(payload: { sub: id })  # ✓ Sibling namespace under Auth
```

The `module` declarations at the top of each file are the authoritative source of what is in lexical scope. References inside the file should reflect that scope.

External callers — controllers, jobs, rake tasks, the console — always use fully qualified paths, since they have no `Auth` module nesting:

```ruby
# In a controller:
Auth::AccessTokens::DecodeService.new(token: token)
Auth::RefreshTokens::RotateService.new(raw_token: params[:refresh_token])
```

This means two reference styles coexist intentionally: short inside the namespace, fully qualified outside it.

## Error Handling

Services own their error handling. Callers never rescue from a service call — they check the boolean return value of `call` (or `success?`) and read `service.errors`.

When a failure condition is encountered inside a service, raise `ServiceError` with a message. `ApplicationService#call` catches it and appends `{ message: }` to `errors`:

```ruby
def call
  super do
    if record.nil?
      raise ServiceError.new("Token not found")
    end

    # happy path
    self.output = { result: value }
  end
end
```

For errors originating from external gems (e.g. `JWT::ExpiredSignature`), rescue inside the `call` block and call `add_error` directly:

```ruby
def call
  super do
    decoded = JWT.decode(input[:token], secret, true, algorithm: "HS256")
    self.output = { payload: decoded.first.with_indifferent_access }
  rescue JWT::ExpiredSignature
    add_error("Token has expired")
  rescue JWT::DecodeError
    add_error("Invalid token")
  end
end
```

Domain-specific error classes (subclasses of `StandardError`) are not used. They added ceremony — raised immediately only to be caught and re-expressed as a string message — without adding value. `ServiceError` with a message is sufficient.

## Memoization

Instance methods that compute a stable value should be memoized with `@var ||=`:

```ruby
def secret
  @secret ||= Rails.application.credentials.jwt_secret_key!
end
```

This signals intent: the value is deterministic and will not change for the lifetime of the object. The absence of memoization signals the opposite — that a value may differ between calls. Used consistently, this convention makes the code more expressive without requiring comments to explain it.
