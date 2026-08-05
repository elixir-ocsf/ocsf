# OCSF

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Elixir library modelling the [Open Cybersecurity Schema Framework (OCSF 1.9)](https://schema.ocsf.io/1.9.0/).

Build, validate, and serialize security events that are OCSF-compliant
out of the box. Persistence-agnostic core with optional companion
libraries for Postgres and ClickHouse sinks.

## Why

- **Normalized audit / security events** -- one struct shape across
  auth flows, provisioning, access control, and API activity.
- **SIEM-ready JSON** -- `Jason.encode!/1` produces a schema-valid
  OCSF payload. No post-processing.
- **Compliance-aware** -- fields carry PII classification from day 1.
  Sink policies enforce deny-by-default redaction before events reach
  storage.
- **Persistence-agnostic** -- the core library has zero database deps.
  Consumers choose `ocsf_ecto` (Postgres) and/or `ocsf_clickhouse`
  (ClickHouse) as needed.

## Installation

```elixir
# mix.exs
def deps do
  [
    {:ocsf, path: "../ocsf"}
  ]
end
```

When published to hex.pm:

```elixir
{:ocsf, "~> 0.1"}
```

## Quick start

### Check the OCSF version

```elixir
OCSF.version()
#=> "1.9.0"
```

### Explore enums

```elixir
OCSF.Category.name(3)
#=> :"Identity & Access Management"

OCSF.Class.name(3002)
#=> :Authentication

OCSF.Activity.label(3002, 1)
#=> :Logon

OCSF.Severity.name(1)
#=> :Informational
```

### Build an Authentication event (M1 -- coming soon)

```elixir
{:ok, event} =
  OCSF.Events.Authentication.logon(
    user: %{
      uid:        "018f19fe-6d4c-71c2-a84b-5d2d8c7f1e90",
      email_addr: "jane@example.com",
      org:        %{uid: "communitiz-app"}
    },
    http_request: %{url: "/oauth/token", http_method: "POST"},
    src_endpoint: %{ip: {10, 0, 0, 1}},
    status:        :Success,
    auth_protocol: :"OAUTH 2.0",
    severity:      :Informational,
    event_code_format: :default
  )

# Serialize to OCSF-compliant JSON
Jason.encode!(event)
```

### Correlation across a flow

```elixir
correlation_uid = OCSF.UUID.v7_string()

OCSF.Correlation.with(correlation_uid, fn ->
  # Every event created here gets the same correlation_uid
  emit_challenge_created(...)
  emit_challenge_answered(...)
  emit_logon_success(...)
end)
```

### PII classification

```elixir
OCSF.Classification.pii?(:contact)
#=> true

OCSF.Classification.default_policy(:contact)
#=> :deny

OCSF.User.__ocsf_fields__()
#=> [
#     uid:        [class: :identifier, erasable: false],
#     name:       [class: :identity,   erasable: true],
#     email_addr: [class: :contact,    erasable: true],
#     org:        [class: :tenant,     erasable: false],
#     type_id:    [class: :taxonomic,  erasable: false]
#   ]
```

## Emitting & persisting events

`ocsf` is the modelling core — it builds and validates events but does not
write them anywhere. To emit events from a running app and persist them, add a
**sink** and (for buffered, batched, back-pressured emission on a hot path) the
**ingestion pipeline**:

| Package | Role | Use it to |
|---------|------|-----------|
| [`ocsf_ingest`](https://hex.pm/packages/ocsf_ingest) | ingestion pipeline | dispatch events non-blocking; buffer, batch, and back-pressure writes into any sink |
| [`ocsf_ecto`](https://hex.pm/packages/ocsf_ecto) | Postgres sink | persist events to Postgres (encrypted PII, idempotent writes) |
| `ocsf_clickhouse` | ClickHouse sink | high-volume columnar storage *(planned)* |

The end-to-end adoption guide (deps, config, supervision, dispatch, DB-load
tuning) lives in the [`ocsf_ingest` README](https://hex.pm/packages/ocsf_ingest).
For low-volume or one-off writes you can call a sink directly
(`OCSF.Ecto.Sink.write/1`) without the pipeline.

## Architecture

```
ocsf              structs, enums, validation, serialization, PII classification
                  runtime dep: jason, uuid_v7

ocsf_ecto         Ecto schema + Ecto.Type shims for Postgres
(optional)        deps: ecto_sql, postgrex

ocsf_clickhouse   Ecto schema + DDL helpers for ClickHouse
(optional)        deps: ecto_sql, ecto_ch
```

Events flow through three stages:

```
Emit              Build an %OCSF.Event{} via a class builder
    |
Redact            Apply sink policy: deny PII, transform network fields
    |
Write             Project to flat columns, bulk-insert via sink adapter
```

## Core modules

| Module                | Purpose                                          |
|-----------------------|--------------------------------------------------|
| `OCSF`                | Facade -- `version/0`                            |
| `OCSF.Category`       | Category UID <-> name lookup                     |
| `OCSF.Class`          | Class UID <-> name lookup + `category/1`         |
| `OCSF.Activity`       | Per-class activity ID <-> label                  |
| `OCSF.Severity`       | Severity ID <-> name                             |
| `OCSF.Status`         | Status ID <-> name                               |
| `OCSF.StatusDetail`   | Well-known `status_detail` strings per class     |
| `OCSF.AuthProtocol`   | Auth protocol ID <-> name                        |
| `OCSF.UUID`           | UUIDv7 generation (delegates to `uuid_v7`)       |
| `OCSF.Correlation`    | Process-dict correlation scope                   |
| `OCSF.Classification` | Data class taxonomy + PII helpers                |

### Nested object structs

| Struct                 | OCSF object                                                                                   |
|------------------------|-----------------------------------------------------------------------------------------------|
| `OCSF.Metadata`       | [Metadata](https://schema.ocsf.io/1.9.0/objects/metadata)                                     |
| `OCSF.User`           | [User](https://schema.ocsf.io/1.9.0/objects/user)                                             |
| `OCSF.Organization`   | [Organization](https://schema.ocsf.io/1.9.0/objects/organization)                             |
| `OCSF.Product`        | [Product](https://schema.ocsf.io/1.9.0/objects/product)                                       |
| `OCSF.Feature`        | [Feature](https://schema.ocsf.io/1.9.0/objects/feature)                                       |
| `OCSF.HttpRequest`    | [HTTP Request](https://schema.ocsf.io/1.9.0/objects/http_request)                             |
| `OCSF.NetworkEndpoint`| [Network Endpoint](https://schema.ocsf.io/1.9.0/objects/network_endpoint)                     |
| `OCSF.Actor`          | [Actor](https://schema.ocsf.io/1.9.0/objects/actor)                                           |
| `OCSF.Service`        | [Service](https://schema.ocsf.io/1.9.0/objects/service)                                       |

Every struct exposes `__ocsf_fields__/0` for PII classification metadata.

## Supported OCSF classes

| Class            | UID  | Category                        | Status         |
|------------------|------|---------------------------------|----------------|
| Authentication   | 3002 | Identity & Access Management    | v0 (current)   |
| Account Change   | 3001 | Identity & Access Management    | v1 (planned)   |
| Authorization    | 3003 | Identity & Access Management    | v1 (planned)   |
| API Activity     | 6003 | Application Activity            | v1 (planned)   |

## Compliance model

Every field on every struct is tagged with a **data class** (`:contact`,
`:identity`, `:network`, `:credential`, etc.). Sinks declare
**policies** -- allow/deny rules per class with optional **transforms**
(`:truncate_v4_24`, `:hash_salted`, `:ua_parse_only`).

- `:contact` and `:identity` fields are **denied by default** on all
  sinks. Postgres stores them AES-encrypted; ClickHouse never receives
  them.
- `:network` fields (IP, user agent) are **denied by default** -- sinks
  must explicitly opt in with a transform.
- `:credential` fields are **always denied** -- not configurable.

Right-to-erasure (GDPR Art. 17): Postgres crypto-shreds via per-user AES
key rotation. ClickHouse never stores erasable PII.

See `OCSF.Classification` for the full taxonomy.

## OCSF version policy

One library release targets one OCSF version:

- `ocsf 0.x.y` targets OCSF 1.9
- `ocsf 1.x.y` will target OCSF 1.9 when it ships

`OCSF.version/0` returns the pinned version. Every emitted event carries
`metadata.version` so stored rows identify which schema they conform to.

## Naming conventions

The library uses `__` (double underscore) as the universal segment
separator for flat-projected column names, table prefixes, and index
names:

| Context          | Example                          |
|------------------|----------------------------------|
| Table            | `ocsf_event__logs`               |
| Column           | `user__email_addr`               |
| Nested column    | `user__org__uid`                 |
| Index            | `ocsf_event__logs__class__idx`   |

Single `_` only appears inside OCSF leaf segment names (`email_addr`,
`user_agent`, `class_uid`).

## Glossary

Authoritative definitions. All project documentation uses these terms
verbatim.

| Term                | Definition                                                                                          |
|---------------------|-----------------------------------------------------------------------------------------------------|
| **Event**           | One OCSF-compliant record (`%OCSF.Event{}`).                                                        |
| **Class**           | OCSF event class (e.g. `3002 = Authentication`).                                                     |
| **Category**        | OCSF top-level grouping (e.g. `3 = Identity & Access Management`).                                   |
| **Activity**        | Class-scoped sub-type (e.g. `Logon` inside Authentication).                                          |
| **Metadata**        | OCSF object carrying `uid`, `version`, `product`, `event_code`.                                      |
| **Nested object**   | Structured sub-record (`user`, `http_request`, `src_endpoint`).                                      |
| **Flat projection** | `__`-joined column form (`user.email_addr` -> `user__email_addr`).                                   |
| **Sink**            | Write-only event destination. Implements `OCSF.Sink` behaviour.                                      |
| **Policy**          | Sink's allow/deny rules per data class + transforms.                                                 |
| **Redaction**       | Applying a policy to an event before writing.                                                        |
| **Data class**      | Semantic tag on a field (`:identifier`, `:contact`, `:network`, etc.).                                |
| **PII**             | Personally identifiable information; derived from data class.                                        |
| **Erasable**        | Field subject to GDPR right-to-erasure (crypto-shreddable in Postgres).                              |
| **Transform**       | Function applied to a field before it reaches a sink.                                                |
| **Table prefix**    | Configurable prefix for sink tables (default: `ocsf_event__`).                                       |
| **Table base**      | Configurable suffix after prefix (default: `logs`). Full: `ocsf_event__logs`.                        |
| **Correlation UID** | `metadata.correlation_uid` -- ties events in one business flow.                                      |
| **Trace UID**       | `metadata.trace_uid` -- W3C/OTel distributed trace ID.                                              |
| **Observable**      | OCSF typed reference in `observables[]` for SIEM pivoting.                                           |
| **Enrichment**      | OCSF extension slot in `enrichments[]` for downstream processors.                                    |

## Links

- [OCSF 1.9 Schema](https://schema.ocsf.io/1.9.0/)
- [OCSF GitHub](https://github.com/ocsf)
- [ecto_ch](https://hex.pm/packages/ecto_ch) -- ClickHouse Ecto adapter
- [uuid_v7](https://hex.pm/packages/uuid_v7) -- UUIDv7 generation

## License

Apache-2.0
