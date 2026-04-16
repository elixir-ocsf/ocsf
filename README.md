# OCSF

Elixir library modelling the [Open Cybersecurity Schema Framework (OCSF 1.8)](https://schema.ocsf.io/1.8.0/). Persistence-agnostic core with optional Postgres and ClickHouse sinks.

## Installation

```elixir
def deps do
  [
    {:ocsf, path: "../ocsf"}
  ]
end
```

## Quick start

```elixir
# Build an Authentication event
{:ok, event} =
  OCSF.Events.Authentication.logon(
    user: %{uid: "018f19fe-...", email_addr: "jane@example.com",
            org: %{uid: "communitiz-app"}},
    http_request: %{url: "/oauth/token", http_method: "POST"},
    src_endpoint: %{ip: {10, 0, 0, 1}},
    status: :success,
    auth_protocol: :oauth_2,
    event_code_format: :default
  )

# Serialize to OCSF-compliant JSON
Jason.encode!(event)
```

## Architecture

```
ocsf            (pure)      structs, enums, validation, serialization/deserialization, PII classification
ocsf_ecto       (optional)  Ecto schema + Ecto.Type shims for Postgres (postgrex)
ocsf_clickhouse (optional)  Ecto schema + DDL helpers for ClickHouse  (ecto_ch)
```

## Glossary

Authoritative definitions. SPEC.md and PLAN.md use these terms verbatim.

- **OCSF** -- Open Cybersecurity Schema Framework. This library targets version 1.8.
- **Event** -- one OCSF-compliant record (`%OCSF.Event{}`).
- **Class / Class UID** -- OCSF event class (e.g. `3002 = Authentication`).
- **Category** -- OCSF top-level grouping (e.g. `3 = Identity & Access Management`).
- **Activity** -- class-scoped sub-type (e.g. `Logon` inside Authentication).
- **Metadata** -- OCSF object carrying `uid`, `version`, `product`, `event_code`, etc.
- **Attribute / field** -- a single named value on an event or nested object.
- **Nested object** -- structured sub-record (`user`, `http_request`, `src_endpoint`, ...).
- **Flat projection** -- the `__`-joined column form used by both sinks (`user.email_addr` -> `user__email_addr`).
- **Sink** -- a write-only destination for events (DB, SIEM, queue). Implements `OCSF.Sink` behaviour.
- **Source** -- producer of events (auth flow, API handler). Defined by the consumer, not this library.
- **Adapter / companion lib** -- `ocsf_ecto` / `ocsf_clickhouse` -- glue between core and a specific sink.
- **Policy** -- a sink's allow/deny rules for field data classes + transforms.
- **Redaction** -- applying a policy to an event before writing it.
- **Data class** -- semantic tag on a field (`:identifier`, `:contact`, `:identity`, `:network`, `:tenant`, `:credential`, `:geolocation`, `:taxonomic`, `:temporal`).
- **PII** -- personally identifiable information; derived from data class.
- **Erasable** -- field subject to GDPR right-to-erasure (crypto-shreddable in Postgres, never written to ClickHouse by default).
- **Transform** -- function applied to a field before it reaches a sink (`:truncate_v4_24`, `:hash_salted`, `:ua_parse_only`, `:drop`).
- **Table prefix** -- configurable string prefixed to all sink tables (default: `ocsf_event__`).
- **Table base** -- configurable logical name appended after the prefix (default: `logs`). Prefix + base = default table `ocsf_event__logs`.
- **Flatten separator** -- `__` (double underscore), used to project nested paths to flat column names.
- **Metadata version** -- the OCSF schema version a row was written under (`metadata__version`, e.g. `"1.8.0"`).
- **Correlation UID** -- `metadata.correlation_uid`. Business-flow identifier shared across all events in one logical flow.
- **Trace UID** -- `metadata.trace_uid`. W3C trace-context / OpenTelemetry trace ID (32-char hex).
- **Observable** -- OCSF typed reference embedded in `observables[]`. Lets a SIEM pivot across events.
- **Enrichment** -- OCSF extension slot (`enrichments[]`) for data added by downstream processors.

## Supported OCSF classes

| Class | UID | Status |
|---|---|---|
| Authentication | 3002 | v0 |
| Account Change | 3001 | v1 (planned) |
| Authorization | 3003 | v1 (planned) |
| API Activity | 6003 | v1 (planned) |

## Compliance model

Fields are tagged with data classes (`:contact`, `:identity`, `:network`, etc.). Sinks declare allow/deny policies per class. PII fields are denied by default -- sinks must explicitly opt in with a transform. See SPEC sections 4-5 for details.

## OCSF version policy

One library release targets one OCSF version. `OCSF.version/0` returns the pinned version. Stored events carry `metadata.version` so queries can filter by schema version.

## Links

- [OCSF 1.8 Schema](https://schema.ocsf.io/1.8.0/)
- [ecto_ch](https://hex.pm/packages/ecto_ch) (ClickHouse adapter)

## License

Apache-2.0
