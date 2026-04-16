# Testing Guidelines

Testing conventions for the `ocsf` library, derived from Elixir
community best practices (Ecto, Broadway, ExUnit docs) and adapted
to this project's needs.

---

## 1. Principles

- **Tests are documentation.** A reader should understand what a
  module does by reading its tests alone. Test names describe
  behavior, not implementation.
- **Fast by default.** Every test module uses `async: true` unless
  it touches shared state (process dictionary, application config,
  telemetry handlers).
- **One assertion focus per test.** A test may have multiple
  `assert` lines to verify one logical outcome, but should not test
  two unrelated behaviors.
- **No test should depend on another.** Tests must pass in any
  order and in isolation. Use `setup` for shared state, not
  test-to-test dependency.
- **Coverage is a floor, not a goal.** 100% coverage is enforced
  by CI, but meaningful tests matter more than line-counting.
  Cover the behavior, not the syntax.

---

## 2. File organization

### 2.1 Directory structure

```
test/
  ocsf_test.exs                  # facade module tests
  ocsf/
    category_test.exs            # mirrors lib/ocsf/category.ex
    event_test.exs
    events/
      authentication_test.exs    # mirrors lib/ocsf/events/authentication.ex
    objects_test.exs             # shared test for all object structs
  support/
    telemetry_handler.ex         # module-based test helpers
  fixtures/
    ocsf_schema/1.8/             # vendored OCSF JSON schemas
    ocsf_examples/1.8/           # vendored official examples
    ocsf/1.8/                    # golden fixtures (Cryptr-specific)
```

### 2.2 File naming

- Test file path mirrors the source file:
  `lib/ocsf/events/authentication.ex` ->
  `test/ocsf/events/authentication_test.exs`.
- Test module name mirrors the source module with `Test` suffix:
  `OCSF.Events.Authentication` -> `OCSF.Events.AuthenticationTest`.

---

## 3. Test module structure

### 3.1 Template

```elixir
defmodule OCSF.SeverityTest do
  use ExUnit.Case, async: true

  alias OCSF.Severity

  # -- describe blocks group by function or feature --

  describe "uid/1" do
    test "returns the numeric identifier for a known name" do
      assert Severity.uid(:Informational) == 1
    end

    test "returns nil for an unknown name" do
      assert Severity.uid(:NonExistent) == nil
    end
  end
end
```

### 3.2 Rules

- **`use ExUnit.Case, async: true`** on every module unless it
  mutates shared state.
- **`alias`** frequently used modules at the top (one per line,
  alphabetical). Credo enforces this.
- **`describe` blocks** group tests by function/arity or feature.
  Name them `"function/arity"` or `"feature name"`:

  ```elixir
  describe "validate/1" do
  describe "logon/1" do
  describe "round-trip serialization" do
  ```

- **`test` names** use lowercase, describe the expected behavior,
  not the implementation:

  ```elixir
  # Good
  test "returns nil for an unknown UID"
  test "omits nil fields from the output"
  test "returns {:error, _} when user is missing"

  # Bad
  test "test_uid_nil"
  test "checks the Map.get call returns nil"
  ```

---

## 4. Setup and helpers

### 4.1 `setup` blocks

Use `setup` for shared state within a `describe` block. Return a
map or keyword list for the test context:

```elixir
describe "logon/1" do
  setup do
    {:ok, event} = Authentication.logon(user: %{uid: "u1"})
    %{event: event}
  end

  test "sets activity_id to 1", %{event: event} do
    assert event.activity_id == 1
  end
end
```

### 4.2 Private helpers

Use `defp` for test-local helpers. Name them descriptively:

```elixir
defp valid_event_attrs do
  [
    metadata: %OCSF.Metadata{
      uid: OCSF.UUID.v7_string(),
      version: "1.8.0",
      product: %OCSF.Product{name: "Test"}
    },
    time: DateTime.utc_now(),
    category_uid: 3,
    class_uid: 3002,
    type_uid: 300_201,
    activity_id: 1,
    severity_id: 1,
    status_id: 1,
    user: %OCSF.User{uid: "test-user"}
  ]
end
```

### 4.3 Shared test helpers

Place reusable helper modules in `test/support/`. They are compiled
via `elixirc_paths(:test)` in `mix.exs`:

```elixir
# test/support/telemetry_handler.ex
defmodule OCSF.TestTelemetryHandler do
  @moduledoc false

  def handle_event(event_name, measurements, metadata, %{pid: pid}) do
    send(pid, {:telemetry, event_name, measurements, metadata})
  end
end
```

### 4.4 Module-based telemetry handlers

**Never use anonymous functions** with `:telemetry.attach/4` in
tests. The telemetry library warns about performance. Always use a
module + function capture:

```elixir
# Good
:telemetry.attach(
  handler_id,
  [:ocsf, :event, :new],
  &OCSF.TestTelemetryHandler.handle_event/4,
  %{pid: self()}
)

# Bad — triggers telemetry performance warning
:telemetry.attach(
  handler_id,
  [:ocsf, :event, :new],
  fn name, m, meta, _ -> send(self(), {:telemetry, name, m, meta}) end,
  nil
)
```

---

## 5. Assertions

### 5.1 Prefer specific assertions

```elixir
# Good — clear intent, helpful failure message
assert event.class_uid == 3002
assert {:ok, %OCSF.Event{}} = Authentication.logon(opts)
assert {:error, %OCSF.Error{reason: :missing}} = OCSF.validate(event)

# Bad — opaque failure message
assert event
assert result != nil
```

### 5.2 Pattern match on tagged tuples

```elixir
# Good — extracts and validates in one step
assert {:ok, event} = Authentication.logon(user: %{uid: "u1"})
assert {:error, %OCSF.Error{path: "user"}} = Authentication.logon([])

# Bad — loses the error information
assert {:ok, _} = Authentication.logon(user: %{uid: "u1"})
```

### 5.3 Avoid weak assertions

Credo enforces this. Don't assert on type alone:

```elixir
# Bad — credo warning: weak assertion
assert is_list(fields)
assert is_binary(uuid)

# Good — assert something about the value
assert length(fields) == 5
assert byte_size(uuid) == 16
assert String.match?(uuid, ~r/^[0-9a-f-]+$/)
```

### 5.4 Non-empty list check

The Elixir type checker warns on `!= []` for lists known to be
non-empty. Credo warns on `length/1 > 0` as expensive. Use pattern
matching:

```elixir
# Good — satisfies both type checker and credo
[_ | _] = fields = Module.__ocsf_fields__()

# Bad — type checker warning (tautological comparison)
assert fields != []

# Bad — credo warning (expensive)
assert length(fields) > 0
```

### 5.5 Assertion count

Keep tests focused. Credo's `TooManyAssertions` check limits to
10 assertions per test. If you need more, split into multiple tests
or use a `for` comprehension:

```elixir
# Acceptable — one logical assertion repeated across data
for {name, uid} <- Severity.values() do
  assert Severity.uid(name) == uid
  assert Severity.name(uid) == name
end
```

---

## 6. Doctests

### 6.1 When to use

- Pure functions with small, predictable output.
- Enum lookups (`uid/1`, `name/1`, `valid?/1`).
- String transformations (`normalize/1`).

### 6.2 When NOT to use

- Functions with side effects (telemetry, process dictionary).
- Functions that produce large or non-deterministic output
  (UUIDv7 generation, DateTime.utc_now).
- Functions requiring setup (Application config, database).

### 6.3 Format

Use `iex>` for single-expression doctests. Use `...>` for
multi-line:

```elixir
@doc """
...

## Examples

    iex> OCSF.Severity.uid(:Informational)
    1

    iex> OCSF.Severity.uid(:NonExistent)
    nil
"""
```

For non-deterministic results, assert a property instead of an
exact value:

```elixir
@doc """
...

## Examples

    iex> uuid = OCSF.UUID.v7_string()
    iex> String.match?(uuid, ~r/^[0-9a-f]{8}-/)
    true
"""
```

---

## 7. Test categories

### 7.1 Unit tests (majority)

Test individual functions in isolation. No external dependencies.
Always `async: true`.

### 7.2 Round-trip tests

Verify serialization/deserialization fidelity:

```elixir
test "to_map -> from_map round-trip preserves the event" do
  {:ok, original} = Authentication.logon(user: %{uid: "u1"})
  {:ok, restored} = original |> OCSF.to_map() |> OCSF.Event.from_map()

  assert restored.class_uid == original.class_uid
  assert restored.user.uid == original.user.uid
  assert restored.metadata.uid == original.metadata.uid
end
```

### 7.3 Golden fixture tests (M1+)

Verify builder output matches expected JSON snapshots:

```elixir
test "logon event matches golden fixture" do
  {:ok, event} = Authentication.logon(
    user: %{uid: "fixture-uid"},
    time: ~U[2026-04-15 10:00:00Z],
    # ... deterministic attrs
  )

  expected = "test/fixtures/ocsf/1.8/authentication/logon_success.json"
    |> File.read!()
    |> Jason.decode!()

  actual = OCSF.to_map(event)
  assert actual == expected
end
```

### 7.4 Schema conformance tests (M1+)

Validate serialized output against OCSF JSON Schema:

```elixir
test "logon JSON validates against OCSF authentication schema" do
  {:ok, event} = Authentication.logon(user: %{uid: "u1"})
  json_map = OCSF.to_map(event)

  schema = "test/fixtures/ocsf_schema/1.8/authentication.json"
    |> File.read!()
    |> Jason.decode!()
    |> ExJsonSchema.Schema.resolve()

  assert ExJsonSchema.Validator.valid?(schema, json_map)
end
```

### 7.5 Property tests (future)

Use `stream_data` for fuzz testing on validators:

```elixir
property "validate/1 rejects events with invalid severity_id" do
  check all severity_id <- integer(),
            severity_id not in [0, 1, 2, 3, 4, 5, 6, 99] do
    event = %{valid_event() | severity_id: severity_id}
    assert {:error, %OCSF.Error{path: "severity_id"}} = OCSF.validate(event)
  end
end
```

---

## 8. Async rules

| Shared state touched     | `async:` | Reason                                  |
|--------------------------|----------|-----------------------------------------|
| None (pure functions)    | `true`   | Safe to parallelize                     |
| Process dictionary       | `true`   | Per-process, no cross-test leakage      |
| Application config       | `false`  | Global — concurrent tests see mutations |
| Telemetry handlers       | `false`  | Global registry — attach/detach races   |
| ETS tables               | `false`  | Shared state                            |
| Files on disk            | `false`  | Potential conflicts                     |

Always clean up in `on_exit/1` when mutating shared state:

```elixir
setup do
  Application.put_env(:ocsf, :event_code, [...])

  on_exit(fn ->
    Application.delete_env(:ocsf, :event_code)
  end)

  :ok
end
```

---

## 9. Coverage

- **Threshold**: 90% minimum, 100% target. Enforced by
  `mix test --cover`.
- **Don't game coverage.** A test that calls a function without
  asserting anything is worse than no test.
- **Cover behavior, not lines.** If a private helper is exercised
  through a public function, that's sufficient — don't test
  private functions directly.
- **Coverage gaps are bugs.** If a code path can't be reached by
  tests, question whether the code should exist.

---

## 10. CI expectations

On every PR:

- `mix test --cover --raise` — 0 failures, meets threshold, 0
  warnings.
- `mix audit` — credo strict, dialyzer, doctor, sobelow, deps
  audit all pass.
- `mix format --check-formatted` — no drift.

On merge:

- Full suite including schema conformance (when vendored schemas
  are present).

---

## 11. Recommended libraries

Beyond ExUnit and the deps already in `mix.exs`, these libraries
are recommended when test needs grow.

### Already included

| Library          | Purpose                             | When to use                                |
|------------------|-------------------------------------|--------------------------------------------|
| `stream_data`    | Property-based / generative testing | Fuzz validators, enum boundaries           |
| `ex_json_schema` | JSON Schema validation              | Schema conformance tests (OCSF compliance) |
| `benchee`        | Performance benchmarking            | `bench/` harness, capacity targets         |

### Recommended additions (add when needed)

| Library       | Hex                                                    | Purpose                         | When to add                                              |
|---------------|--------------------------------------------------------|---------------------------------|----------------------------------------------------------|
| `ex_machina`  | [hex](https://hex.pm/packages/ex_machina)              | Test data factories             | When `ocsf_ecto` lands (M2) and tests need persistent fixtures with associations. Overkill for pure struct tests. |
| `faker`       | [hex](https://hex.pm/packages/faker)                   | Realistic fake data             | When tests need realistic names, emails, IPs, UUIDs. Useful for golden fixtures and property tests. |
| `mox`         | [hex](https://hex.pm/packages/mox)                     | Behaviour-based mocks           | When sink companions need to mock DB calls in unit tests. Only behind behaviours — never mock concrete modules. |
| `bypass`      | [hex](https://hex.pm/packages/bypass)                  | HTTP request interception       | When `ocsf_siem_export` (deferred) needs to test HTTP sinks against a fake endpoint. |
| `hammox`      | [hex](https://hex.pm/packages/hammox)                  | Type-checking mocks             | Alternative to `mox` that validates mock calls match the behaviour's `@spec`. Stricter. |
| `mix_test_watch` | [hex](https://hex.pm/packages/mix_test_watch)       | Auto-run tests on file change   | Already in deps. Run with `mix test.watch` during development. |

### Usage guidance

**`ex_machina`** — define factories in `test/support/factory.ex`:

```elixir
defmodule OCSF.Factory do
  use ExMachina

  def event_factory do
    %OCSF.Event{
      metadata: build(:metadata),
      time: DateTime.utc_now(),
      category_uid: 3,
      class_uid: 3002,
      type_uid: 300_201,
      activity_id: 1,
      severity_id: 1,
      status_id: 1,
      user: build(:user)
    }
  end

  def metadata_factory do
    %OCSF.Metadata{
      uid: OCSF.UUID.v7_string(),
      version: "1.8.0",
      product: build(:product)
    }
  end

  def user_factory do
    %OCSF.User{
      uid: OCSF.UUID.v7_string(),
      name: Faker.Person.name(),
      email_addr: Faker.Internet.email(),
      org: %OCSF.Organization{uid: Faker.Company.bs()}
    }
  end

  def product_factory do
    %OCSF.Product{name: "Cryptr", vendor_name: "cryptr"}
  end
end
```

Use in tests:

```elixir
import OCSF.Factory

test "redacts PII from user" do
  event = build(:event, user: build(:user, name: "Alice"))
  redacted = OCSF.redact(event, deny_pii_policy())
  assert redacted.user.name == nil
end
```

**`faker`** — use for realistic but non-deterministic data. Always
seed for reproducibility when needed:

```elixir
# Realistic event attrs
user: %{
  uid: Faker.UUID.v4(),
  name: Faker.Person.name(),
  email_addr: Faker.Internet.email(),
  org: %{uid: Faker.Internet.domain_word()}
}
```

**`mox`** — only for behaviours, never for concrete modules. The
`OCSF.Sink` behaviour is the primary candidate:

```elixir
# test/support/mocks.ex
Mox.defmock(OCSF.MockSink, for: OCSF.Sink)

# in test
expect(OCSF.MockSink, :write, fn events -> :ok end)
```

### When NOT to add a library

- Don't add `faker` for tests that need deterministic output
  (golden fixtures). Use hardcoded values instead.
- Don't add `ex_machina` for the core `ocsf` library — `defp`
  helpers in test files are sufficient for struct-only tests.
  Factories shine when persistence is involved (M2+).
- Don't add `mox` unless you have a behaviour to mock. The core
  library has no external deps to mock.

---

## 12. Anti-patterns

- **Test names starting with "test"** — redundant (`test "test
  something"` reads as stuttering).
- **Magic numbers without context** — use module attributes or
  named helpers (`@class_uid 3002` or `valid_event_attrs()`).
- **Asserting on inspect output** — brittle across Elixir
  versions. Assert on struct fields instead.
- **sleep-based synchronization** — use `assert_receive` with
  timeouts for message-based tests.
- **Mocking external modules** — this library has no external
  dependencies to mock. If you find yourself wanting a mock, the
  design may need a behaviour or protocol instead.
- **Overly DRY tests** — some repetition in tests is fine if it
  makes each test self-contained and readable. Don't abstract away
  the setup to the point where reading a test requires jumping to
  three helper functions.

---

## 13. Checklist

Before merging, verify:

- [ ] Every new public function has at least one test.
- [ ] `mix test --cover --raise` passes with 0 warnings.
- [ ] `mix audit` passes (credo, dialyzer, doctor, sobelow).
- [ ] `mix format --check-formatted` passes.
- [ ] Test names describe behavior, not implementation.
- [ ] No `async: false` without a documented reason.
- [ ] No anonymous functions in telemetry handlers.
- [ ] Shared state is cleaned up in `on_exit/1`.
