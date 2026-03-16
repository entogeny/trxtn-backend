# API Versioning — Design Choices

## Path Versioning

All API endpoints are namespaced under `/api/rest/v1/`. Versioning is expressed
in the URL path rather than via request headers.

Header-based versioning (`Accept: application/vnd.app.v1+json`) is theoretically
cleaner — the URL identifies a resource, the header identifies a representation.
In practice it is painful: harder to test in a browser, invisible in server logs
by default, poorly supported by HTTP clients and documentation tools, and a source
of constant friction for API consumers.

Path versioning is explicit, cacheable, loggable, and universally understood.
Stripe, GitHub, and Shopify all use it.

## The `/api/rest/v1` Shape

The `/api` prefix separates application endpoints from infrastructure endpoints
(`/up`). Infrastructure endpoints are consumed by load balancers and deployment
tooling — they are not part of the versioned API contract.

The `/rest` segment reserves space for sibling API types at the same level
(`/api/graphql`, `/api/grpc`). These are not planned but the structure costs
nothing and avoids a disruptive reorganisation if they are added later.

The `/v1` segment is the version identifier that will increment.

## Controller Namespace Structure

```
app/controllers/
  application_controller.rb            # authentication, current_user
  api/
    base_controller.rb                 # shared API concerns
    rest/
      base_controller.rb               # REST-specific concerns
      v1/
        base_controller.rb             # v1 hook (empty until needed)
        auth_controller.rb
        test_controller.rb
```

Each layer inherits from the one above it. `ApplicationController` handles
authentication because all future API types (REST, GraphQL) need it.
`Api::BaseController` is the place for shared error rendering and `rescue_from`
blocks. `Api::Rest::BaseController` is for REST idioms.
`Api::Rest::V1::BaseController` is intentionally empty — it exists as a seam
in case V1 ever needs to diverge from V2 without affecting other versions.

## Services Are Not Versioned

The version boundary lives at the controller layer. Services are business logic
and are version-agnostic. Both a current and a future `V2::AuthController` call
the same `Auth::RefreshTokens::RotateService`.

If a service's behaviour genuinely needs to change between versions, a new
service is created or an option is added — driven by the business logic change,
not by the API version number.

## Adding V2

When V2 is needed:

1. Add `app/controllers/api/rest/v2/` with its own `base_controller.rb`
2. Add the `namespace :v2` block in `routes.rb`
3. Controllers that are unchanged in V2 can inherit from their V1 counterparts.
   Controllers that diverge should be written fresh to avoid coupling.

V1 remains live until all consumers have migrated and a deprecation window has
passed. Both versions run concurrently.
