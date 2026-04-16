defmodule OCSF.Severity do
  @moduledoc "OCSF severity levels."

  @values [
    {:"Unknown", 0},
    {:"Informational", 1},
    {:"Low", 2},
    {:"Medium", 3},
    {:"High", 4},
    {:"Critical", 5},
    {:"Fatal", 6},
    {:"Other", 99}
  ]

  @by_uid Map.new(@values)
  @by_name Map.new(@values, fn {name, uid} -> {uid, name} end)

  @spec values() :: [{atom, integer}]
  def values, do: @values

  @spec ecto_values() :: keyword
  def ecto_values, do: @values

  @spec uid(atom) :: integer | nil
  def uid(name), do: Map.get(@by_uid, name)

  @spec name(integer) :: atom | nil
  def name(uid), do: Map.get(@by_name, uid)

  @spec valid?(atom | integer) :: boolean
  def valid?(name) when is_atom(name), do: Map.has_key?(@by_uid, name)
  def valid?(uid) when is_integer(uid), do: Map.has_key?(@by_name, uid)
end
