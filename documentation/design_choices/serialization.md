# Serialization — Design Choices

## What a Serializer Is

A serializer controls the shape of a JSON response for a given model. It is the single source of truth for which fields are exposed over the API for that model.

Serializers use [Blueprinter](https://github.com/procore-oss/blueprinter) and live in `app/serializers/`.

## BaseSerializer

All serializers inherit from `BaseSerializer`, which inherits from `Blueprinter::Base`:

```ruby
class BaseSerializer < Blueprinter::Base
  identifier :id
end
```

`identifier :id` is declared once in `BaseSerializer` so that every serializer automatically includes the `id` field without needing to repeat it.

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
  fields :description, :end_at, :name, :start_at
end
```

This is a hard convention. Alphabetical ordering makes it trivially easy to scan what a serializer exposes and to spot duplicates or missing fields during code review.

## Usage in Controllers

Controllers render responses by passing a record or collection directly to the serializer:

```ruby
# Single record
render json: EventSerializer.render(event)

# Collection
render json: EventSerializer.render(events)
```

Controllers do not build response hashes by hand. All field selection and formatting belongs in the serializer.
