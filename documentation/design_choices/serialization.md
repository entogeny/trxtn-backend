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

Controllers render responses by passing a record or collection directly to the serializer, always with an explicit `view:` and `status:`:

```ruby
# Single record
render json: EventSerializer.render(event, view: :standard), status: :ok

# Collection
render json: EventSerializer.render(events, view: :standard), status: :ok
```

Controllers do not build response hashes by hand. All field selection and formatting belongs in the serializer.
