defmodule OCSF do
  @moduledoc """
  Elixir library modelling the Open Cybersecurity Schema Framework (OCSF 1.8).

  Persistence-agnostic core with optional Postgres (`ocsf_ecto`) and
  ClickHouse (`ocsf_clickhouse`) sinks.
  """

  @ocsf_version "1.8.0"

  @doc "Returns the OCSF schema version this library targets."
  @spec version() :: String.t()
  def version, do: @ocsf_version
end
