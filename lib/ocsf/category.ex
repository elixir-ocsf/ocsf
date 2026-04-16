defmodule OCSF.Category do
  @moduledoc "OCSF event categories (top-level grouping)."

  @values [
    {:"Identity & Access Management", 3},
    {:"Application Activity", 6}
  ]

  @by_uid Map.new(@values)
  @by_name Map.new(@values, fn {name, uid} -> {uid, name} end)

  @doc "Returns all values as a keyword list."
  @spec values() :: [{atom, integer}]
  def values, do: @values

  @doc "Returns values formatted for `Ecto.Enum`."
  @spec ecto_values() :: keyword
  def ecto_values, do: @values

  @doc "Returns the numeric identifier for the given name atom."
  @spec uid(atom) :: integer | nil
  def uid(name), do: Map.get(@by_uid, name)

  @doc "Returns the name atom for the given numeric identifier."
  @spec name(integer) :: atom | nil
  def name(uid), do: Map.get(@by_name, uid)

  @doc "Returns true if the given name or identifier is valid."
  @spec valid?(atom | integer) :: boolean
  def valid?(name) when is_atom(name), do: Map.has_key?(@by_uid, name)
  def valid?(uid) when is_integer(uid), do: Map.has_key?(@by_name, uid)
end
