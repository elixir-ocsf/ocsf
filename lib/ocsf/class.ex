defmodule OCSF.Class do
  @moduledoc "OCSF event classes."

  @values [
    {:"Account Change", 3001},
    {:"Authentication", 3002},
    {:"Authorization", 3003},
    {:"API Activity", 6003}
  ]

  @category_map %{
    3001 => 3,
    3002 => 3,
    3003 => 3,
    6003 => 6
  }

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

  @doc "Returns the category_uid for a given class_uid."
  @spec category(integer) :: integer | nil
  def category(class_uid), do: Map.get(@category_map, class_uid)
end
