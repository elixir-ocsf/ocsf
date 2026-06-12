defmodule OCSF.Sink do
  @moduledoc """
  Behaviour for OCSF event sinks.

  A **sink** is a write-only destination for OCSF events. Implementations
  handle the persistence or transport of events — typical examples are
  Postgres (`ocsf_ecto`), ClickHouse (`ocsf_clickhouse`), or SIEM
  exporters.

  Every sink declares a `policy/0` that governs which `OCSF.Classification`
  data classes it accepts. Denied fields are nilled out before insert
  via `OCSF.Policy.apply/2`.

  ## Callbacks

  - `write/1` — persist a batch of events.
  - `row_for/1` — project a single event to the sink-specific row shape.
  - `policy/0` — return the sink's redaction policy.
  - `health/0` — report sink health for liveness checks.

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

  @doc "Project a single event to the sink-specific row shape."
  @callback row_for(OCSF.Event.t()) :: map

  @doc "Return the sink's redaction policy."
  @callback policy() :: OCSF.Policy.t()

  @doc "Return the sink's current health status."
  @callback health() :: health
end
