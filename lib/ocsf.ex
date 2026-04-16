defmodule OCSF do
  @moduledoc """
  Elixir library modelling the Open Cybersecurity Schema Framework (OCSF 1.8).

  Provides structs, enums, and helpers that map to the
  [OCSF 1.8.0](https://schema.ocsf.io/1.8.0/) specification. Use this
  module as the top-level entry point for schema version information.
  Persistence-agnostic core with optional Postgres (`ocsf_ecto`) and
  ClickHouse (`ocsf_clickhouse`) sinks.

  ## Examples

      iex> OCSF.version()
      "1.8.0"

  See `OCSF.Category`, `OCSF.Class`, `OCSF.Activity`, `OCSF.Severity`,
  `OCSF.Status`, and `OCSF.Classification` for the core enums and taxonomy.
  """

  @ocsf_version "1.8.0"

  @doc """
  Return the OCSF schema version this library targets.

  ## Examples

      iex> OCSF.version()
      "1.8.0"
  """
  @spec version() :: String.t()
  def version, do: @ocsf_version
end
