defmodule OCSF.Test.SchemaValidator do
  @moduledoc false

  @doc """
  Load the vendored OCSF compiled schema for a class.

  Returns the parsed JSON with attribute definitions, enum values,
  requirements, and constraints.
  """
  @spec load_class_schema(String.t()) :: map
  def load_class_schema(class_name) do
    path =
      Path.join([
        File.cwd!(),
        "test/fixtures/ocsf_schema/1.8",
        "#{class_name}.json"
      ])

    path
    |> File.read!()
    |> Jason.decode!()
  end

  @doc """
  Validate an event map (from `OCSF.to_map/1`) against the vendored
  OCSF schema.

  Returns `{:ok, []}` if valid, or `{:error, errors}` with a list of
  human-readable error strings.
  """
  @spec validate_event(map, map) :: {:ok, []} | {:error, [String.t()]}
  def validate_event(event_map, schema) do
    errors =
      []
      |> check_required_fields(event_map, schema)
      |> check_enum_values(event_map, schema)
      |> check_type_uid(event_map, schema)
      |> check_constraints(event_map, schema)

    case errors do
      [] -> {:ok, []}
      errors -> {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Extract enum values from the schema for a given attribute.

  Returns a MapSet of valid integer keys parsed from the schema's
  enum definition.
  """
  @spec enum_values(map, String.t()) :: MapSet.t()
  def enum_values(schema, attr_name) do
    schema
    |> get_in(["attributes", attr_name, "enum"])
    |> case do
      nil -> MapSet.new()
      enum_map -> enum_map |> Map.keys() |> Enum.map(&String.to_integer/1) |> MapSet.new()
    end
  end

  @doc """
  Extract the list of required attribute names from the schema.
  """
  @spec required_fields(map) :: [String.t()]
  def required_fields(schema) do
    schema
    |> Map.get("attributes", %{})
    |> Stream.filter(fn {_name, def} -> def["requirement"] == "required" end)
    |> Stream.map(fn {name, _} -> name end)
    |> Stream.reject(&profile_only?(schema, &1))
    |> Enum.sort()
  end

  # -- Private checks --

  defp check_required_fields(errors, event_map, schema) do
    required = required_fields(schema)

    Enum.reduce(required, errors, fn field, acc ->
      if Map.has_key?(event_map, String.to_atom(field)) or Map.has_key?(event_map, field) do
        acc
      else
        ["missing required field: #{field}" | acc]
      end
    end)
  end

  defp check_enum_values(errors, event_map, schema) do
    enum_fields = [
      "activity_id",
      "severity_id",
      "status_id",
      "category_uid",
      "class_uid",
      "auth_protocol_id"
    ]

    Enum.reduce(enum_fields, errors, fn field, acc ->
      value = get_field(event_map, field)
      valid_values = enum_values(schema, field)

      cond do
        value == nil ->
          acc

        MapSet.size(valid_values) == 0 ->
          acc

        MapSet.member?(valid_values, value) ->
          acc

        true ->
          [
            "invalid #{field} value: #{value}, expected one of #{inspect(MapSet.to_list(valid_values))}"
            | acc
          ]
      end
    end)
  end

  defp check_type_uid(errors, event_map, schema) do
    type_uid = get_field(event_map, "type_uid")
    valid_type_uids = enum_values(schema, "type_uid")

    cond do
      type_uid == nil -> ["missing required field: type_uid" | errors]
      MapSet.size(valid_type_uids) == 0 -> errors
      MapSet.member?(valid_type_uids, type_uid) -> errors
      true -> ["invalid type_uid: #{type_uid}" | errors]
    end
  end

  defp check_constraints(errors, event_map, schema) do
    case schema["constraints"] do
      %{"at_least_one" => fields} ->
        has_any =
          Enum.any?(fields, fn f ->
            val = get_field(event_map, f)
            val != nil
          end)

        if has_any do
          errors
        else
          ["constraint violated: at least one of #{inspect(fields)} must be present" | errors]
        end

      _ ->
        errors
    end
  end

  defp get_field(map, field) when is_binary(field) do
    Map.get(map, String.to_atom(field)) || Map.get(map, field)
  end

  defp profile_only?(schema, field_name) do
    case get_in(schema, ["attributes", field_name, "profiles"]) do
      nil -> false
      [] -> false
      _profiles -> true
    end
  end
end
