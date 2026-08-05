defmodule OCSF.Class do
  @moduledoc """
  OCSF event classes.

  Maps event class names to their OCSF 1.8 numeric identifiers. Each
  class belongs to a `OCSF.Category` and defines the schema for a
  specific type of security event.

  See the OCSF
  [classes](https://schema.ocsf.io/1.8.0/classes) definition.

  ## Values

  | Name                        | ID   | Category |
  |-----------------------------|------|----------|
  | `:"Account Change"`          | 3001 | 3        |
  | `:Authentication`            | 3002 | 3        |
  | `:"Authorize Session"`       | 3003 | 3        |
  | `:"Entity Management"`       | 3004 | 3        |
  | `:"User Access Management"`  | 3005 | 3        |
  | `:"Group Management"`        | 3006 | 3        |
  | `:"API Activity"`            | 6003 | 6        |

  See `OCSF.Category` for category definitions and `OCSF.Activity` for
  per-class activity mappings.
  """

  @values [
    {:"Account Change", 3001},
    {:Authentication, 3002},
    {:"Authorize Session", 3003},
    {:"Entity Management", 3004},
    {:"User Access Management", 3005},
    {:"Group Management", 3006},
    {:"API Activity", 6003}
  ]

  @category_map %{
    3001 => 3,
    3002 => 3,
    3003 => 3,
    3004 => 3,
    3005 => 3,
    3006 => 3,
    6003 => 6
  }

  @by_uid Map.new(@values)
  @by_name Map.new(@values, fn {name, uid} -> {uid, name} end)

  @doc """
  Return all values as a keyword list.

  ## Examples

      iex> OCSF.Class.values()
      [{:"Account Change", 3001}, {:Authentication, 3002}, {:"Authorize Session", 3003}, {:"Entity Management", 3004}, {:"User Access Management", 3005}, {:"Group Management", 3006}, {:"API Activity", 6003}]
  """
  @spec values() :: [{atom, integer}]
  def values, do: @values

  @doc """
  Return values formatted for `Ecto.Enum`.

  ## Examples

      iex> OCSF.Class.ecto_values()
      [{:"Account Change", 3001}, {:Authentication, 3002}, {:"Authorize Session", 3003}, {:"Entity Management", 3004}, {:"User Access Management", 3005}, {:"Group Management", 3006}, {:"API Activity", 6003}]
  """
  @spec ecto_values() :: keyword
  def ecto_values, do: @values

  @doc """
  Return the numeric identifier for the given name atom.

  ## Examples

      iex> OCSF.Class.uid(:Authentication)
      3002

      iex> OCSF.Class.uid(:NonExistent)
      nil
  """
  @spec uid(atom) :: integer | nil
  def uid(name), do: Map.get(@by_uid, name)

  @doc """
  Return the name atom for the given numeric identifier.

  ## Examples

      iex> OCSF.Class.name(3002)
      :Authentication

      iex> OCSF.Class.name(9999)
      nil
  """
  @spec name(integer) :: atom | nil
  def name(uid), do: Map.get(@by_name, uid)

  @doc """
  Return true if the given name or identifier is valid.

  ## Examples

      iex> OCSF.Class.valid?(:Authentication)
      true

      iex> OCSF.Class.valid?(3002)
      true

      iex> OCSF.Class.valid?(:NonExistent)
      false
  """
  @spec valid?(atom | integer) :: boolean
  def valid?(name) when is_atom(name), do: Map.has_key?(@by_uid, name)
  def valid?(uid) when is_integer(uid), do: Map.has_key?(@by_name, uid)

  @doc """
  Return the `category_uid` for a given `class_uid`.

  ## Examples

      iex> OCSF.Class.category(3002)
      3

      iex> OCSF.Class.category(9999)
      nil
  """
  @spec category(integer) :: integer | nil
  def category(class_uid), do: Map.get(@category_map, class_uid)
end
