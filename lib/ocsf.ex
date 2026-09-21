defmodule OCSF do
  @moduledoc """
  Elixir library modelling the Open Cybersecurity Schema Framework (OCSF 1.9).

  Provides structs, enums, and helpers that map to the
  [OCSF 1.9.0](https://schema.ocsf.io/1.9.0/) specification. Use this
  module as the top-level entry point for schema version information.
  Persistence-agnostic core with optional Postgres (`ocsf_ecto`) and
  ClickHouse (`ocsf_clickhouse`) sinks.

  See `OCSF.Category`, `OCSF.Class`, `OCSF.Activity`, `OCSF.Severity`,
  `OCSF.Status`, and `OCSF.Classification` for the core enums and taxonomy.
  """

  @ocsf_version "1.9.0"

  # Versions accepted on `metadata.version` by `validate/1`. OCSF minor
  # releases are additive, so events persisted under an earlier version
  # still deserialize; builders always emit `version/0`.
  @supported_versions ["1.8.0", @ocsf_version]

  @doc """
  Return the OCSF schema version this library targets.

  Every event built by the `OCSF.Events.*` builders carries this value
  in `metadata.version`. See `supported_versions/0` for the versions
  `validate/1` accepts when reading events back.

  ## Examples

      iex> OCSF.version()
      "1.9.0"
  """
  @spec version() :: String.t()
  def version, do: @ocsf_version

  @doc """
  Return the OCSF schema versions `validate/1` accepts in `metadata.version`.

  OCSF minor releases are additive, so an event persisted by an earlier
  release of this library (e.g. `"1.8.0"`) still validates and
  deserializes. The current `version/0` is always included.

  ## Examples

      iex> OCSF.supported_versions()
      ["1.8.0", "1.9.0"]

      iex> OCSF.version() in OCSF.supported_versions()
      true
  """
  @spec supported_versions() :: [String.t()]
  def supported_versions, do: @supported_versions

  @doc """
  Convert an `%OCSF.Event{}` to an OCSF-compliant nested map.

  Nil fields are omitted. Integer UIDs are emitted as-is; their
  corresponding `_name` labels are added alongside per OCSF convention.

  Delegates to `OCSF.Serializer.to_map/1`.

  ## Examples

      {:ok, event} =
        OCSF.Events.Authentication.logon(
          user: %{uid: "u1"},
          service: %{name: "Cryptr Auth"},
          status: :Success
        )

      map = OCSF.to_map(event)
      map.class_uid
      #=> 3002
      map.class_name
      #=> "Authentication"
      Map.has_key?(map, :dst_endpoint)
      #=> false
  """
  @spec to_map(OCSF.Event.t()) :: map
  def to_map(%OCSF.Event{} = event), do: OCSF.Serializer.to_map(event)

  @doc """
  Serialize an `%OCSF.Event{}` to OCSF-compliant JSON iodata.

  Equivalent to `event |> OCSF.to_map() |> Jason.encode_to_iodata!()`.

  ## Examples

      {:ok, event} =
        OCSF.Events.Authentication.logon(
          user: %{uid: "u1"},
          service: %{name: "Cryptr Auth"}
        )

      event |> OCSF.to_json() |> IO.iodata_to_binary() |> Jason.decode!()
      #=> %{"class_uid" => 3002, "class_name" => "Authentication", ...}
  """
  @spec to_json(OCSF.Event.t()) :: iodata
  def to_json(%OCSF.Event{} = event), do: event |> to_map() |> Jason.encode_to_iodata!()

  @doc """
  Reconstruct an `%OCSF.Event{}` from a nested OCSF map.

  Accepts atom- or string-keyed maps and runs `validate/1` on the
  result, so `event |> OCSF.to_map() |> OCSF.from_map()` round-trips.

  Delegates to `OCSF.Event.from_map/1`.

  ## Examples

      {:ok, event} =
        OCSF.Events.Authentication.logon(
          user: %{uid: "u1"},
          service: %{name: "Cryptr Auth"}
        )

      {:ok, ^event} = event |> OCSF.to_map() |> OCSF.from_map()

      OCSF.from_map(%{"class_uid" => 3002})
      #=> {:error, %OCSF.Error{reason: :missing, path: "metadata.uid", details: %{}}}
  """
  @spec from_map(map) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def from_map(map) when is_map(map), do: OCSF.Event.from_map(map)

  @doc """
  Apply a sink **policy** to an event, returning a **redacted** event.

  Delegates to `OCSF.Policy.apply/2`.

  ## Examples

      {:ok, event} =
        OCSF.Events.Authentication.logon(
          user: %{uid: "u1", name: "Jane", email_addr: "jane@example.com"},
          service: %{name: "Cryptr Auth"}
        )

      redacted = OCSF.redact(event, %OCSF.Policy{deny: [:contact, :identity]})
      redacted.user
      #=> %OCSF.User{uid: "u1", name: nil, email_addr: nil, org: nil, type_id: nil}
  """
  @spec redact(OCSF.Event.t(), OCSF.Policy.t()) :: OCSF.Event.t()
  def redact(%OCSF.Event{} = event, %OCSF.Policy{} = policy),
    do: OCSF.Policy.apply(policy, event)

  @doc """
  Validate an `%OCSF.Event{}` structurally.

  Runs the SPEC §10 checks in order: nested object types, metadata
  presence, supported version, product, category/class/type consistency,
  activity/status/severity validity, time format, class-specific
  required fields, and the class `at_least_one` constraints.

  Returns `{:ok, event}` on success or `{:error, %OCSF.Error{}}` on
  the first failure (reasons `:type_mismatch`, `:missing`, `:invalid`,
  `:constraint_violated`).

  The builders call this for you; call it directly on events assembled
  with `OCSF.Event.new/1`.

  ## Examples

      iex> {:ok, event} =
      ...>   OCSF.Event.new(
      ...>     metadata: %OCSF.Metadata{
      ...>       uid: "018f1a03-2a8f-7b40-9e12-b7aa47bd0c01",
      ...>       version: "1.9.0",
      ...>       product: %OCSF.Product{name: "Cryptr"}
      ...>     },
      ...>     time: ~U[2026-04-15 10:00:00Z],
      ...>     category_uid: 3,
      ...>     class_uid: 3002,
      ...>     type_uid: 300_201,
      ...>     activity_id: 1,
      ...>     severity_id: 1,
      ...>     status_id: 1,
      ...>     user: %{uid: "u1"},
      ...>     service: %{name: "Cryptr Auth"}
      ...>   )
      iex> {:ok, _valid} = OCSF.validate(event)
      iex> OCSF.validate(%{event | service: nil})
      {:error,
       %OCSF.Error{
         reason: :constraint_violated,
         path: "service|dst_endpoint",
         details: %{at_least_one: [:service, :dst_endpoint], class_uid: 3002}
       }}
  """
  @spec validate(OCSF.Event.t()) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def validate(%OCSF.Event{} = event) do
    with :ok <- check_object_types(event),
         :ok <- check_metadata_uid(event),
         :ok <- check_metadata_version(event),
         :ok <- check_metadata_product(event),
         :ok <- check_category(event),
         :ok <- check_class(event),
         :ok <- check_type_uid(event),
         :ok <- check_activity(event),
         :ok <- check_status(event),
         :ok <- check_status_detail(event),
         :ok <- check_severity(event),
         :ok <- check_time(event),
         :ok <- check_class_required_fields(event),
         :ok <- check_class_constraints(event) do
      {:ok, event}
    end
  end

  # Expected struct (or list element type) of every nested field, at the
  # event level and inside each object. Malformed input is kept as-is by
  # `OCSF.Event.new/1` and `OCSF.Deserializer.from_map/1`; this is where
  # it is reported instead of raising later in the serializer.
  @event_object_types [
    metadata: OCSF.Metadata,
    actor: OCSF.Actor,
    user: OCSF.User,
    updated_user: OCSF.User,
    entity: OCSF.Entity,
    group: OCSF.Group,
    groups: {:list, OCSF.Group},
    iam_role: OCSF.IamRole,
    iam_roles: {:list, OCSF.IamRole},
    updated_role: OCSF.IamRole,
    api: OCSF.Api,
    privileges: {:list, :string},
    resources: {:list, OCSF.ResourceDetails},
    http_request: OCSF.HttpRequest,
    src_endpoint: OCSF.NetworkEndpoint,
    dst_endpoint: OCSF.NetworkEndpoint,
    service: OCSF.Service
  ]

  @nested_object_types %{
    OCSF.Metadata => [product: OCSF.Product],
    OCSF.Product => [feature: OCSF.Feature],
    OCSF.User => [org: OCSF.Organization],
    OCSF.Actor => [user: OCSF.User],
    OCSF.Api => [service: OCSF.Service],
    OCSF.IamRole => [resources: {:list, OCSF.ResourceDetails}],
    OCSF.ResourceDetails => [owner: OCSF.User, group: OCSF.Group]
  }

  defp check_object_types(event), do: check_typed_fields(event, @event_object_types, "")

  defp check_typed_fields(container, specs, prefix) do
    Enum.reduce_while(specs, :ok, fn {field, spec}, :ok ->
      case check_typed_value(Map.get(container, field), spec, prefix <> Atom.to_string(field)) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp check_typed_value(nil, _spec, _path), do: :ok

  defp check_typed_value(list, {:list, spec}, path) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {item, i}, :ok ->
      case check_typed_value(item, spec, "#{path}[#{i}]") do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp check_typed_value(value, {:list, _spec}, path), do: type_mismatch(path, "list", value)
  defp check_typed_value(value, :string, _path) when is_binary(value), do: :ok
  defp check_typed_value(value, :string, path), do: type_mismatch(path, "String.t()", value)

  defp check_typed_value(%mod{} = struct, mod, path),
    do: check_typed_fields(struct, Map.get(@nested_object_types, mod, []), path <> ".")

  defp check_typed_value(value, mod, path), do: type_mismatch(path, "%#{inspect(mod)}{}", value)

  defp type_mismatch(path, expected, value),
    do: {:error, OCSF.Error.new(:type_mismatch, path, %{expected: expected, got: value})}

  defp check_metadata_uid(%{metadata: %{uid: uid}}) when is_binary(uid) and uid != "", do: :ok
  defp check_metadata_uid(_), do: {:error, OCSF.Error.new(:missing, "metadata.uid")}

  defp check_metadata_version(%{metadata: %{version: nil}}),
    do: {:error, OCSF.Error.new(:missing, "metadata.version")}

  defp check_metadata_version(%{metadata: %{version: v}}) when v in @supported_versions, do: :ok

  defp check_metadata_version(%{metadata: %{version: v}}),
    do:
      {:error,
       OCSF.Error.new(:invalid, "metadata.version", %{
         expected: @supported_versions,
         got: v
       })}

  defp check_metadata_product(%{metadata: %{product: %OCSF.Product{}}}), do: :ok
  defp check_metadata_product(_), do: {:error, OCSF.Error.new(:missing, "metadata.product")}

  defp check_category(%{category_uid: uid}) do
    if OCSF.Category.valid?(uid),
      do: :ok,
      else: {:error, OCSF.Error.new(:invalid, "category_uid", %{got: uid})}
  end

  defp check_class(%{class_uid: class_uid, category_uid: category_uid}) do
    cond do
      not OCSF.Class.valid?(class_uid) ->
        {:error, OCSF.Error.new(:invalid, "class_uid", %{got: class_uid})}

      OCSF.Class.category(class_uid) != category_uid ->
        {:error,
         OCSF.Error.new(:invalid, "class_uid", %{
           expected_category: OCSF.Class.category(class_uid),
           got_category: category_uid
         })}

      true ->
        :ok
    end
  end

  defp check_type_uid(%{type_uid: type_uid, class_uid: class_uid, activity_id: activity_id}) do
    expected = class_uid * 100 + activity_id

    if type_uid == expected,
      do: :ok,
      else: {:error, OCSF.Error.new(:invalid, "type_uid", %{expected: expected, got: type_uid})}
  end

  defp check_activity(%{class_uid: class_uid, activity_id: activity_id}) do
    if OCSF.Activity.valid?(class_uid, activity_id),
      do: :ok,
      else:
        {:error,
         OCSF.Error.new(:invalid, "activity_id", %{class_uid: class_uid, got: activity_id})}
  end

  defp check_status(%{status_id: status_id}) do
    if OCSF.Status.valid?(status_id),
      do: :ok,
      else: {:error, OCSF.Error.new(:invalid, "status_id", %{got: status_id})}
  end

  defp check_status_detail(%{status_detail: nil}), do: :ok
  defp check_status_detail(%{status_detail: d}) when is_binary(d), do: :ok

  defp check_status_detail(%{status_detail: d}),
    do:
      {:error, OCSF.Error.new(:type_mismatch, "status_detail", %{expected: "String.t()", got: d})}

  defp check_severity(%{severity_id: severity_id}) do
    if OCSF.Severity.valid?(severity_id),
      do: :ok,
      else: {:error, OCSF.Error.new(:invalid, "severity_id", %{got: severity_id})}
  end

  defp check_time(%{time: %DateTime{utc_offset: 0}}), do: :ok

  defp check_time(%{time: %DateTime{}}),
    do: {:error, OCSF.Error.new(:invalid, "time", %{expected: "UTC offset 0"})}

  defp check_time(_), do: {:error, OCSF.Error.new(:missing, "time")}

  defp check_class_required_fields(%{class_uid: 3002, user: nil}),
    do:
      {:error, OCSF.Error.new(:missing, "user", %{reason: "required for Authentication (3002)"})}

  defp check_class_required_fields(%{class_uid: 3003, user: nil}),
    do:
      {:error,
       OCSF.Error.new(:missing, "user", %{reason: "required for Authorize Session (3003)"})}

  defp check_class_required_fields(%{class_uid: 3007, user: nil}),
    do:
      {:error, OCSF.Error.new(:missing, "user", %{reason: "required for User Management (3007)"})}

  defp check_class_required_fields(%{class_uid: 3008, iam_role: nil}),
    do:
      {:error,
       OCSF.Error.new(:missing, "iam_role", %{reason: "required for Role Management (3008)"})}

  defp check_class_required_fields(%{class_uid: 6003, api: nil}),
    do: {:error, OCSF.Error.new(:missing, "api", %{reason: "required for API Activity (6003)"})}

  defp check_class_required_fields(%{class_uid: 6003, actor: nil}),
    do: {:error, OCSF.Error.new(:missing, "actor", %{reason: "required for API Activity (6003)"})}

  defp check_class_required_fields(%{class_uid: 6003, src_endpoint: nil}),
    do:
      {:error,
       OCSF.Error.new(:missing, "src_endpoint", %{reason: "required for API Activity (6003)"})}

  defp check_class_required_fields(%{class_uid: 3004, entity: nil}),
    do:
      {:error,
       OCSF.Error.new(:missing, "entity", %{reason: "required for Entity Management (3004)"})}

  defp check_class_required_fields(%{class_uid: 3006, group: nil}),
    do:
      {:error,
       OCSF.Error.new(:missing, "group", %{reason: "required for Group Management (3006)"})}

  defp check_class_required_fields(_), do: :ok

  # OCSF `at_least_one` class constraints. `nil` and `[]` both count as
  # absent, matching the serializer, which omits empty lists.
  @class_constraints %{
    3002 => [:service, :dst_endpoint],
    3003 => [:privileges, :groups, :iam_roles]
  }

  defp check_class_constraints(%{class_uid: class_uid} = event) do
    case Map.fetch(@class_constraints, class_uid) do
      {:ok, fields} ->
        if Enum.any?(fields, &present?(Map.get(event, &1))) do
          :ok
        else
          {:error,
           OCSF.Error.new(:constraint_violated, Enum.join(fields, "|"), %{
             at_least_one: fields,
             class_uid: class_uid
           })}
        end

      :error ->
        :ok
    end
  end

  defp present?(nil), do: false
  defp present?([]), do: false
  defp present?(_), do: true
end
