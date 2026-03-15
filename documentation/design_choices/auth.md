# Authentication — Design Choices

## No Devise

Devise was designed for server-rendered Rails applications using sessions and cookies. This project is a pure JSON API with a separate mobile frontend. Using Devise would mean working against the grain of the framework — configuring it to ignore its core purpose (session-based authentication) and layering JWT on top via a secondary gem (`devise-jwt`).

The custom implementation covers the full scope of our auth requirements in under 150 lines of code that we wrote and fully understand. Each future auth feature (confirmable, password reset, lockable) is straightforward to add as a standalone service — none require Devise's machinery.

## JWT for Access Tokens, Not Sessions

Access tokens are stateless JWTs signed with HS256. The server does not store them. Every protected request is authenticated purely by verifying the token's signature and expiry — no database lookup required for access token validation.

This scales horizontally without session affinity concerns. It also eliminates a class of attack surface (session fixation, session hijacking via cookies).

## Access Token TTL: 1 Hour

The standard web recommendation is 15 minutes. For a mobile API, 15-minute access tokens cause friction: when a token expires while the app is backgrounded, the foreground event must trigger a silent refresh before the user's intended action can proceed. 1 hour reduces this friction while keeping the exposure window short enough to contain damage from a stolen token.

## Refresh Token Design

Refresh tokens are `SecureRandom.hex(32)` — 64 hex characters of cryptographic randomness. They are stored as SHA256 hex digests in the database. The raw token is returned to the client once at issue time only.

**Why SHA256 and not bcrypt?** Refresh tokens are already high-entropy random values (not user-chosen passwords). Bcrypt's slow hashing is designed to resist offline dictionary attacks against low-entropy inputs — that threat does not apply here. SHA256 allows direct database lookup by digest without iterating and comparing records.

## Refresh Token Rotation

Every call to `POST /auth/refresh` revokes the current refresh token and issues a new one. This limits the useful lifetime of a stolen refresh token to the window between compromise and next legitimate use. The operation is wrapped in a database transaction to prevent issuing a new token if revocation fails.

## Rolling 90-Day Expiry

Refresh tokens are issued with `expires_at = 90.days.from_now`. Because rotation always issues a new token with a fresh 90-day window, an active user's session never expires. An inactive user's last token expires 90 days after their last activity. This matches expected mobile app behaviour: active users stay logged in indefinitely; dormant accounts are cleaned up automatically.

## Service Architecture

Business logic lives entirely in service objects, not models or controllers.

- **Controllers** receive requests and render responses. No logic.
- **Models** define data structure, associations, and simple validations. No logic.
- **Services** own all business logic.

Each service is single-purpose and exposes one public class method: `.call`. The name of the class is the verb; the method is always `.call`.

## Service Naming Conventions

### Plural namespaces for services that mirror model names

A Ruby constant collision occurs if a service namespace shares the exact constant path with an ActiveRecord model. `User` is both a model class and, in naive namespacing, the prefix for `User::CreateService`. Ruby raises `TypeError: User is not a module` when resolving `User::` because the constant is already defined as a class.

**Convention: service namespaces that mirror model names are pluralized.**

```
Users::CreateService    ✓  (no collision — Users is not a model)
User::CreateService     ✗  (TypeError: User is not a module)
```

This applies even within nested namespaces if a collision could occur through lexical scope resolution.

### Technology-agnostic naming

Service namespaces describe domain concepts, not implementation details.

```
Auth::AccessTokens::EncodeService    ✓  (concept: access tokens)
Auth::Jwt::EncodeService             ✗  (implementation detail)
```

If the JWT implementation were replaced, `Auth::AccessTokens::` would remain valid. `Auth::Jwt::` would not.

## Rate Limiting with rack-attack

Rack::Attack throttles at the Rack middleware layer — before the request reaches Rails, the router, or the database. This is more efficient than application-level throttling and provides protection even if Rails is slow to respond.

Three rules are applied:
- Login by IP: 5 requests per 20 seconds
- Login by username: 5 requests per 20 seconds (prevents distributed brute force across multiple IPs)
- Signup by IP: 3 requests per minute

## CORS

Allowed origins are configured via `Rails.application.credentials.cors.allowed_origins`. In development this defaults to `"*"` for convenience. Production should set explicit allowed origins in credentials.

## Algorithm: HS256

HS256 (HMAC-SHA256) uses a single shared secret for both signing and verification. RS256 (RSA) uses a private key to sign and a public key to verify — appropriate when multiple independent services need to verify tokens without holding the signing secret.

This project has one API. HS256 is correct. If the architecture grows to include independent microservices that need to verify tokens, migrating to RS256 is straightforward.
