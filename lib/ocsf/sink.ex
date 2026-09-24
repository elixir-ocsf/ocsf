defmodule OCSF.Sink do
  @moduledoc """
  Behaviour for OCSF event sinks.

  A **sink** is a write-only destination for OCSF events. Implementations
  handle the persistence or transport of events — typical examples are
  Postgres (`ocsf_ecto`), ClickHouse (`ocsf_clickhouse`), or SIEM
  exporters.

  ## Callbacks

  The generic transport contract — used by the `ocsf_ingest` pipeline — is just
  `write/1` and `health/0`. `row_for/1` and `policy/0` are **OCSF projection**
  helpers, used by OCSF sinks (e.g. `ocsf_ecto`) and never by the pipeline, so
  they are optional: a non-OCSF sink (e.g. a hook-event sink) implements only
  `write/1` and `health/0`.

  - `write/1` — persist a batch of events.
  - `health/0` — report sink health for liveness checks.
  - `row_for/1` *(optional)* — project a single event to the sink-specific row
    shape.
  - `policy/0` *(optional)* — return the sink's redaction policy; denied
    `OCSF.Classification` data classes are nilled out before insert via
    `OCSF.Policy.apply/2`.

  ## Example implementation

      defmodule MyApp.Sinks.Postgres do
        @behaviour OCSF.Sink

        @impl true
        def write(events), do: MyApp.Repo.insert_all(...)

        @impl true
        def row_for(event), do: %{...}

        @impl true
        def policy, do: %OCSF.Policy{deny: [:contact, :identity]}

        @impl true
        def health, do: :ok
      end

  See `OCSF.Policy`, `OCSF.Telemetry`.
  """

  @typedoc """
  Health status reported by a sink.

  - `:ok` — accepting writes normally
  - `{:degraded, reason}` — online but impaired (queue backpressure,
    replica lag, rate limiting)
  - `{:down, reason}` — not accepting writes
  """
  @type health :: :ok | {:degraded, reason :: term} | {:down, reason :: term}

  @doc "Persist a batch of events. Returns `:ok` or `{:error, reason}`."
  @callback write([OCSF.Event.t()]) :: :ok | {:error, term}

  @doc "Return the sink's current health status."
  @callback health() :: health

  @doc "Project a single event to the sink-specific row shape (OCSF sinks)."
  @callback row_for(OCSF.Event.t()) :: map

  @doc "Return the sink's redaction policy (OCSF sinks)."
  @callback policy() :: OCSF.Policy.t()

  @optional_callbacks row_for: 1, policy: 0
end
