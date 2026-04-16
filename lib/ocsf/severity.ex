defmodule OCSF.Severity do
  @moduledoc """
  OCSF severity levels.

  Maps human-readable severity names to their OCSF 1.8 numeric
  identifiers. Used by event builders to resolve the `:severity`
  keyword into the `severity_id` field.

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

  See `OCSF.Status` for event outcome status.
  """

  @values [
    {:Unknown, 0},
    {:Informational, 1},
    {:Low, 2},
    {:Medium, 3},
    {:High, 4},
    {:Critical, 5},
    {:Fatal, 6},
    {:Other, 99}
  ]

  @by_uid Map.new(@values)
  @by_name Map.new(@values, fn {name, uid} -> {uid, name} end)

  @doc """
  Return all values as a keyword list.

  ## Examples

      iex> OCSF.Severity.values()
      [Unknown: 0, Informational: 1, Low: 2, Medium: 3, High: 4, Critical: 5, Fatal: 6, Other: 99]
  """
  @spec values() :: [{atom, integer}]
  def values, do: @values

  @doc """
  Return values formatted for `Ecto.Enum`.

  ## Examples

      iex> OCSF.Severity.ecto_values()
      [Unknown: 0, Informational: 1, Low: 2, Medium: 3, High: 4, Critical: 5, Fatal: 6, Other: 99]
  """
  @spec ecto_values() :: keyword
  def ecto_values, do: @values

  @doc """
  Return the numeric identifier for the given name atom.

  ## Examples

      iex> OCSF.Severity.uid(:Informational)
      1

      iex> OCSF.Severity.uid(:NonExistent)
      nil
  """
  @spec uid(atom) :: integer | nil
  def uid(name), do: Map.get(@by_uid, name)

  @doc """
  Return the name atom for the given numeric identifier.

  ## Examples

      iex> OCSF.Severity.name(1)
      :Informational

      iex> OCSF.Severity.name(42)
      nil
  """
  @spec name(integer) :: atom | nil
  def name(uid), do: Map.get(@by_name, uid)

  @doc """
  Return true if the given name or identifier is valid.

  ## Examples

      iex> OCSF.Severity.valid?(:Informational)
      true

      iex> OCSF.Severity.valid?(1)
      true

      iex> OCSF.Severity.valid?(:NonExistent)
      false
  """
  @spec valid?(atom | integer) :: boolean
  def valid?(name) when is_atom(name), do: Map.has_key?(@by_uid, name)
  def valid?(uid) when is_integer(uid), do: Map.has_key?(@by_name, uid)
end
