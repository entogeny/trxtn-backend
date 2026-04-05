# Serialization — Design Choices

## What a Serializer Is

A serializer controls the shape of a JSON response for a given model. It is the single source of truth for which fields are exposed over the API for that model.

Serializers use [Blueprinter](https://github.com/procore-oss/blueprinter) and live in `app/serializers/`.

## BaseSerializer

All serializers inherit from `BaseSerializer`, which inherits from `Blueprinter::Base`:

```ruby
class BaseSerializer < Blueprinter::Base
  identifier :id

  view :base do
  end

  view :standard do
    include_view :base
  end

  view :extended do
    include_view :standard
  end
end
```

`identifier :id` is declared once in `BaseSerializer` so that every serializer automatically includes the `id` field without needing to repeat it.

## Views

Serializers define three standard views, declared as empty shells in `BaseSerializer` and overridden per-serializer:

- **`:base`** — the minimal representation of a record. Intended for embedded or nested associations where only identity and a label are needed.
- **`:standard`** — the default API response shape. Includes `:base` and adds all fields appropriate for normal endpoints.
- **`:extended`** — the full representation. Includes `:standard` and adds any fields too expensive or sensitive for everyday use (e.g. aggregates, private data).

Declaring all three views in `BaseSerializer` ensures every serializer has a consistent, composable surface. Individual serializers override only the views that add fields.

Controllers always specify an explicit view — never rely on Blueprinter's default view — so it is always clear which representation is being rendered.

## One Serializer Per Model

Each model that is rendered in an API response has exactly one serializer, named after the model:

```
app/serializers/
  base_serializer.rb     # BaseSerializer
  event_serializer.rb    # EventSerializer
```

## Field Ordering

Fields within a serializer must be alphabetized, with the exception of `id`, which is always first by virtue of being declared as `identifier` in `BaseSerializer`.

```ruby
class EventSerializer < BaseSerializer
  view :base do
  end

  view :standard do
    include_view :base

    field :description
    field :end_at
    field :name
    field :start_at
  end

  view :extended do
    include_view :standard
  end
end
```

This is a hard convention. Alphabetical ordering makes it trivially easy to scan what a serializer exposes and to spot duplicates or missing fields during code review.

## Usage in Controllers

Controllers render serialized responses through the `Serializable` and `Errorable` concerns rather than calling serializers or building response hashes directly:

```ruby
include Concerns::Errorable
include Concerns::Serializable
```

**`render_serialized_json(serializer, data, options = {}, status: DEFAULT_STATUS_CODE)`** — renders a JSON response. Responses are always root-wrapped under a `data` key. The `view:` defaults to `:standard`. `status:` defaults to `:ok`.

**`render_errors_json(errors = [], status: DEFAULT_STATUS)`** — renders an error response. `errors` should be an array of error hashes (matching the service `errors` output). `status:` defaults to `:internal_server_error`.

**Always pass `status:` explicitly at the call site**, even when the value matches the default:

```ruby
def index
  service = Events::IndexService.new
  if service.call
    render_serialized_json(EventSerializer, service.output[:records], {
      view: serialization_params[:view]
    }, status: :ok)
  else
    render_errors_json(service.errors, status: :internal_server_error)
  end
end
```

The defaults exist as a safety net for when a status is omitted — not as a substitute for expressing intent. An explicit status documents the action's contract at the call site and ensures a future change to the default cannot silently alter behaviour.

**`serialization_params`** — extracts and defaults serialization options from the request params. Clients may specify the view they want rendered:

```
GET /api/rest/v1/events?serialization[view]=extended
```

When no `serialization[view]` param is present, `serialization_params` defaults to `{ view: :standard }`.

Controllers do not build response hashes by hand. All field selection and formatting belongs in the serializer.
