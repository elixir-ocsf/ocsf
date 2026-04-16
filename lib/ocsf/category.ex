defmodule OCSF.Category do
  @moduledoc "OCSF event categories (top-level grouping)."

  @values [
    {:"Identity & Access Management", 3},
    {:"Application Activity", 6}
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
