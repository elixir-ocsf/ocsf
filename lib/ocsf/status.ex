defmodule OCSF.Status do
  @moduledoc """
  OCSF event status.

  Maps event outcome status names to their OCSF 1.8 numeric identifiers.
  Used by event builders to resolve the `:status` keyword into the
  `status_id` field.

  See the OCSF
  [status_id](https://schema.ocsf.io/1.8.0/data_types/integer?caption=status_id)
  definition.

  ## Values

  | Name       | ID |
  |------------|----|
  | `:Unknown` | 0  |
  | `:Success` | 1  |
  | `:Failure` | 2  |
  | `:Other`   | 99 |

  See `OCSF.StatusDetail` for well-known `status_detail` string constants
  and `OCSF.Severity` for severity levels.
  """

  @values [
    {:Unknown, 0},
    {:Success, 1},
    {:Failure, 2},
    {:Other, 99}
  ]

  @by_uid Map.new(@values)
  @by_name Map.new(@values, fn {name, uid} -> {uid, name} end)

  @doc """
  Return all values as a keyword list.

  ## Examples

      iex> OCSF.Status.values()
      [Unknown: 0, Success: 1, Failure: 2, Other: 99]
  """
  @spec values() :: [{atom, integer}]
  def values, do: @values

  @doc """
  Return values formatted for `Ecto.Enum`.

  ## Examples

      iex> OCSF.Status.ecto_values()
      [Unknown: 0, Success: 1, Failure: 2, Other: 99]
  """
  @spec ecto_values() :: keyword
  def ecto_values, do: @values

  @doc """
  Return the numeric identifier for the given name atom.

  ## Examples

      iex> OCSF.Status.uid(:Success)
      1

      iex> OCSF.Status.uid(:NonExistent)
      nil
  """
  @spec uid(atom) :: integer | nil
  def uid(name), do: Map.get(@by_uid, name)

  @doc """
  Return the name atom for the given numeric identifier.

  ## Examples

      iex> OCSF.Status.name(1)
      :Success

      iex> OCSF.Status.name(42)
      nil
  """
  @spec name(integer) :: atom | nil
  def name(uid), do: Map.get(@by_name, uid)

  @doc """
  Return true if the given name or identifier is valid.

  ## Examples

      iex> OCSF.Status.valid?(:Success)
      true

      iex> OCSF.Status.valid?(1)
      true

      iex> OCSF.Status.valid?(:NonExistent)
      false
  """
  @spec valid?(atom | integer) :: boolean
  def valid?(name) when is_atom(name), do: Map.has_key?(@by_uid, name)
  def valid?(uid) when is_integer(uid), do: Map.has_key?(@by_name, uid)
end
