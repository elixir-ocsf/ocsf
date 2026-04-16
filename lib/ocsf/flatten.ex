defmodule OCSF.Flatten do
  @moduledoc """
  Flatten nested OCSF maps to `__`-joined column maps.

  Converts the nested map shape produced by `OCSF.to_map/1` into a
  flat map suitable for columnar storage. Uses `__` (double underscore)
  as the segment separator per the naming convention (SPEC §6).

  ## Example

      nested = %{user: %{org: %{uid: "acme"}}, severity_id: 1}
      OCSF.Flatten.flatten(nested)
      #=> %{"user__org__uid" => "acme", "severity_id" => 1}

  See `OCSF.Serializer`, `OCSF.Classification`.
  """

  @separator "__"

  @doc """
  Flatten a nested map into a `__`-joined flat map.

  Top-level keys that are not maps pass through as-is. Nested maps
  are recursively joined with `__`. List and nil values are preserved
  without flattening.

  ## Examples

      iex> OCSF.Flatten.flatten(%{a: 1, b: %{c: 2, d: %{e: 3}}})
      %{"a" => 1, "b__c" => 2, "b__d__e" => 3}

      iex> OCSF.Flatten.flatten(%{x: nil})
      %{"x" => nil}
  """
  @spec flatten(map) :: map
  def flatten(map) when is_map(map) do
    do_flatten(map, "")
  end

  defp do_flatten(map, prefix) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      full_key = join_key(prefix, to_string(key))

      case value do
        %{} = nested when map_size(nested) > 0 ->
          Map.merge(acc, do_flatten(nested, full_key))

        _ ->
          Map.put(acc, full_key, value)
      end
    end)
  end

  defp join_key("", key), do: key
  defp join_key(prefix, key), do: prefix <> @separator <> key
end
