# Documentation Guidelines

Documentation style for the `ocsf` library, inspired by
[Ecto](https://github.com/elixir-ecto/ecto)'s documentation patterns.

---

## 1. Principles

- **Documentation is part of the API.** Every public module and function
  must have `@moduledoc` / `@doc`. Doctor enforces 100% coverage.
- **Teach, don't just describe.** Explain *why* something exists, not
  just *what* it does. A reader coming from the OCSF spec should
  understand how the library maps to the standard.
- **Progressive disclosure.** Start with the simplest usage, then layer
  complexity. First paragraph answers "what does this do?", examples
  answer "how do I use it?", sections answer "what are the edge cases?".
- **One source of truth.** Don't duplicate information across modules.
  Cross-reference with backtick links instead.

---

## 2. Module documentation (`@moduledoc`)

### 2.1 Structure

Every `@moduledoc` follows this order:

1. **Opening summary** — one paragraph, plain language, no jargon.
   Answers: "What is this module and when do I use it?"
2. **Example** — minimal working code showing the primary use case.
   Appears before any deep-dive sections.
3. **Sections** — `##` headings for distinct topics (options, types,
   edge cases, OCSF mapping, etc.).
4. **Cross-references** — links to related modules at the end, not
   scattered throughout.

### 2.2 Opening summary examples

Good:

```elixir
@moduledoc """
OCSF severity levels.

Maps human-readable severity names to their OCSF 1.8 numeric
identifiers. Used by event builders to resolve the `:severity`
keyword into the `severity_id` field on `OCSF.Event`.
"""
```

Bad:

```elixir
@moduledoc """
This module provides severity functionality.
"""
```

### 2.3 Sections

Use `##` for top-level sections inside `@moduledoc`:

```elixir
@moduledoc """
...opening summary...

## OCSF mapping

This module corresponds to the OCSF
[Authentication](https://schema.ocsf.io/1.8.0/classes/authentication)
class (UID 3002).

## Activities

Each function maps to an OCSF activity:

| Function              | Activity ID | OCSF name            |
|-----------------------|-------------|----------------------|
| `logon/1`             | 1           | Logon                |
| `logoff/1`            | 2           | Logoff               |
| `preauth/1`           | 6           | Preauth              |

## Examples

    {:ok, event} = OCSF.Events.Authentication.logon(user: %{uid: "..."})
"""
```

### 2.4 Callouts

Use `>` blockquotes with a bold title for important notes:

```elixir
@moduledoc """
...

> **OCSF compliance note:** `user` is a required field for the
> Authentication class. The builder returns `{:error, _}` if omitted.
"""
```

For info-level callouts (non-critical):

```elixir
> **Note:** `status_detail` is a free-form string in OCSF, not an
> enum. See `OCSF.StatusDetail` for well-known constants.
```

---

## 3. Function documentation (`@doc`)

### 3.1 Structure

1. **First sentence** — what the function does, in imperative mood.
   This sentence appears in the function list on HexDocs.
2. **Details** — additional context, constraints, behavior on nil/edge
   cases. Keep it short.
3. **`## Options`** — if the function accepts a keyword list, document
   each key with type and default.
4. **`## Examples`** — at least one, using `iex>` for doctests or
   indented code blocks for non-doctest examples.

### 3.2 Example

```elixir
@doc """
Returns the human-readable label for a class and activity.

Returns `nil` if the class or activity is unknown.

## Examples

    iex> OCSF.Activity.label(3002, 1)
    :Logon

    iex> OCSF.Activity.label(3002, 42)
    nil
"""
@spec label(integer, integer) :: atom | nil
def label(class_uid, activity_id) do
```

### 3.3 Options sections

Use a definition list (bullet + bold key):

```elixir
@doc """
Builds a Logon authentication event.

## Options

- **`:user`** (required) — map with at least `:uid`. Cast to
  `%OCSF.User{}`.
- **`:status`** — atom from `OCSF.Status`. Defaults to `:Success`.
- **`:severity`** — atom from `OCSF.Severity`. Defaults to
  `:Informational`.
- **`:event_code_format`** — atom. Named format to derive
  `metadata.event_code`. See `OCSF.EventCodeFormat`.

## Examples

    {:ok, event} =
      OCSF.Events.Authentication.logon(
        user: %{uid: "018f...", org: %{uid: "acme"}},
        status: :Success,
        auth_protocol: :SAML
      )
"""
```

---

## 4. Code examples

### 4.1 Doctests (`iex>`)

Use for pure functions with small, predictable output:

```elixir
@doc """
Returns the OCSF schema version.

## Examples

    iex> OCSF.version()
    "1.8.0"
"""
```

### 4.2 Indented code blocks

Use for examples that produce complex output, have side effects, or
would make poor doctests:

```elixir
@doc """
...

## Examples

    {:ok, event} =
      OCSF.Events.Authentication.logon(
        user: %{uid: "018f19fe-..."},
        status: :Success
      )

    event.metadata.version
    #=> "1.8.0"
"""
```

Use `#=>` for inline expected-output comments (not `#`).

### 4.3 Progression

Show the simple case first, then edge cases:

```elixir
## Examples

    # Simple lookup
    iex> OCSF.Severity.name(1)
    :Informational

    # Unknown returns nil
    iex> OCSF.Severity.name(42)
    nil
```

---

## 5. Cross-references

### 5.1 Module links

Use backtick-wrapped module names. HexDocs auto-links them:

```elixir
See `OCSF.Classification` for the full list of data classes.
```

### 5.2 Function links

Use `module.function/arity` form:

```elixir
Delegates to `OCSF.Activity.label/2`.
```

### 5.3 External links

Link to the OCSF schema for every module that maps to an OCSF concept:

```elixir
Corresponds to the OCSF
[Metadata](https://schema.ocsf.io/1.8.0/objects/metadata) object.
```

### 5.4 SPEC cross-references

Reference the SPEC by section number when documenting design decisions:

```elixir
> Event code generation follows SPEC section 7.5. Formats are
> configured via `config :ocsf, event_code: [...]`.
```

---

## 6. Typespecs

- Every public function has `@spec`.
- Use custom `@type` definitions on structs.
- Prefer named types over inline unions for readability:

```elixir
@type data_class ::
        :identifier | :tenant | :contact | :identity |
        :network    | :credential | :geolocation | :temporal | :taxonomic
```

---

## 7. Struct modules (objects)

Every OCSF object struct module follows this template:

```elixir
defmodule OCSF.User do
  @moduledoc """
  OCSF User object.

  Represents a user identity in an OCSF event. Corresponds to the
  OCSF [User](https://schema.ocsf.io/1.8.0/objects/user) object.

  ## Fields

  - `:uid` — unique user identifier.
  - `:name` — display name. Classified as `:identity` (PII, erasable).
  - `:email_addr` — email address. Classified as `:contact` (PII,
    erasable).
  - `:org` — `%OCSF.Organization{}` or `nil`.

  ## PII classification

  See `OCSF.Classification` for data class definitions. Call
  `__ocsf_fields__/0` to inspect this module's field classifications.
  """

  @type t :: %__MODULE__{...}
  defstruct [...]

  @doc "Returns field classification metadata for PII policy enforcement."
  @spec __ocsf_fields__() :: keyword()
  def __ocsf_fields__ do
    [...]
  end
end
```

---

## 8. Enum modules

Every OCSF enum module follows this template:

```elixir
defmodule OCSF.Severity do
  @moduledoc """
  OCSF severity levels.

  Maps severity names to their OCSF 1.8 numeric identifiers (0-6, 99).
  Used by event builders to resolve the `:severity` keyword.

  See the OCSF
  [severity_id](https://schema.ocsf.io/1.8.0/data_types/integer?caption=severity_id)
  definition.

  ## Values

  | Name             | ID |
  |------------------|----|
  | `:Unknown`       | 0  |
  | `:Informational` | 1  |
  | `:Low`           | 2  |
  | `:Medium`        | 3  |
  | `:High`          | 4  |
  | `:Critical`      | 5  |
  | `:Fatal`         | 6  |
  | `:Other`         | 99 |
  """
```

---

## 9. Naming conventions in docs

- Use **OCSF field names** in prose (`activity_id`, not "activity
  identifier" or "activity UID").
- Use **backticks** for code references: `` `severity_id` ``,
  `` `OCSF.Event` ``, `` `to_map/1` ``.
- Use **bold** for emphasis on terms defined in the Glossary:
  **sink**, **policy**, **redaction**, **data class**.
- Use the `__` flat-column form when discussing persistence:
  `` `user__email_addr` ``, not "user.email_addr column".
- Say "OCSF 1.8" not "the OCSF standard" when the version matters.

---

## 10. What NOT to document

- Implementation details that may change (internal data structures,
  private function behavior).
- Information derivable from typespecs alone (don't restate the spec
  in prose if the types are self-explanatory).
- Git history or changelog entries in module docs.
- Planned/future features — document what exists now.

---

## 11. Checklist

Before merging, verify:

- [ ] Every public module has `@moduledoc`.
- [ ] Every public function has `@doc` and `@spec`.
- [ ] At least one example per public function.
- [ ] OCSF schema link in every module that maps to an OCSF concept.
- [ ] Cross-references use backtick module/function syntax.
- [ ] `mix doctor --raise` passes (100% doc + spec coverage).
- [ ] No `TODO` or `FIXME` in docs (use issues instead).
