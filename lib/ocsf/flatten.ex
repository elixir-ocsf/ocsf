defmodule OCSF.Flatten do
  @moduledoc """
  Flatten nested OCSF maps to and from `__`-joined column maps.

  `flatten/1` converts the nested map shape produced by `OCSF.to_map/1`
  into a flat map suitable for columnar storage; `unflatten/1` is its
  inverse, rebuilding the nested map from the flat one. Both use `__`
  (double underscore) as the segment separator per the naming
  convention (SPEC §6). A single `_` is a literal character inside a
  segment name (`email_addr`, `correlation_uid`) and is never a
  boundary, which keeps the round-trip unambiguous.

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

  @doc """
  Rebuild a nested map from a `__`-joined flat map — the inverse of `flatten/1`.

  Each key is split on the `__` separator and nested accordingly; keys
  without a separator pass through as-is. List, nil and (empty) map
  values are preserved untouched. Keys are strings on the way out, so
  for any nested map `m` of scalar/nil/list/empty-map leaves,
  `m |> flatten() |> unflatten()` equals `m` with its keys stringified.

  ## Examples

      iex> OCSF.Flatten.unflatten(%{"a" => 1, "b__c" => 2, "b__d__e" => 3})
      %{"a" => 1, "b" => %{"c" => 2, "d" => %{"e" => 3}}}

      iex> OCSF.Flatten.unflatten(%{"x" => nil})
      %{"x" => nil}
  """
  @spec unflatten(map) :: map
  def unflatten(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      segments = key |> to_string() |> String.split(@separator)
      put_nested(acc, segments, value)
    end)
  end

  defp put_nested(acc, [key], value), do: Map.put(acc, key, value)

  defp put_nested(acc, [key | rest], value) do
    child =
      case Map.get(acc, key) do
        %{} = existing -> existing
        _ -> %{}
      end

    Map.put(acc, key, put_nested(child, rest, value))
  end
end
