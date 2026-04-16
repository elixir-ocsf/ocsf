defmodule OCSF.Category do
  @moduledoc """
  OCSF event categories (top-level grouping).

  Maps category names to their OCSF 1.8 numeric identifiers. Categories
  are the broadest classification of events and group related event
  classes together.

  See the OCSF
  [category_uid](https://schema.ocsf.io/1.8.0/categories) definition.

  ## Values

  | Name                              | ID |
  |-----------------------------------|----|
  | `:"Identity & Access Management"` | 3  |
  | `:"Application Activity"`         | 6  |

  See `OCSF.Class` for the event classes within each category.
  """

  @values [
    {:"Identity & Access Management", 3},
    {:"Application Activity", 6}
  ]

  @by_uid Map.new(@values)
  @by_name Map.new(@values, fn {name, uid} -> {uid, name} end)

  @doc """
  Return all values as a keyword list.

  ## Examples

      iex> OCSF.Category.values()
      [{:"Identity & Access Management", 3}, {:"Application Activity", 6}]
  """
  @spec values() :: [{atom, integer}]
  def values, do: @values

  @doc """
  Return values formatted for `Ecto.Enum`.

  ## Examples

      iex> OCSF.Category.ecto_values()
      [{:"Identity & Access Management", 3}, {:"Application Activity", 6}]
  """
  @spec ecto_values() :: keyword
  def ecto_values, do: @values

  @doc """
  Return the numeric identifier for the given name atom.

  ## Examples

      iex> OCSF.Category.uid(:"Identity & Access Management")
      3

      iex> OCSF.Category.uid(:NonExistent)
      nil
  """
  @spec uid(atom) :: integer | nil
  def uid(name), do: Map.get(@by_uid, name)

  @doc """
  Return the name atom for the given numeric identifier.

  ## Examples

      iex> OCSF.Category.name(3)
      :"Identity & Access Management"

      iex> OCSF.Category.name(42)
      nil
  """
  @spec name(integer) :: atom | nil
  def name(uid), do: Map.get(@by_name, uid)

  @doc """
  Return true if the given name or identifier is valid.

  ## Examples

      iex> OCSF.Category.valid?(:"Identity & Access Management")
      true

      iex> OCSF.Category.valid?(3)
      true

      iex> OCSF.Category.valid?(:NonExistent)
      false
  """
  @spec valid?(atom | integer) :: boolean
  def valid?(name) when is_atom(name), do: Map.has_key?(@by_uid, name)
  def valid?(uid) when is_integer(uid), do: Map.has_key?(@by_name, uid)
end
