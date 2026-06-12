defmodule OCSF do
  @moduledoc """
  Elixir library modelling the Open Cybersecurity Schema Framework (OCSF 1.8).

  Provides structs, enums, and helpers that map to the
  [OCSF 1.8.0](https://schema.ocsf.io/1.8.0/) specification. Use this
  module as the top-level entry point for schema version information.
  Persistence-agnostic core with optional Postgres (`ocsf_ecto`) and
  ClickHouse (`ocsf_clickhouse`) sinks.

  See `OCSF.Category`, `OCSF.Class`, `OCSF.Activity`, `OCSF.Severity`,
  `OCSF.Status`, and `OCSF.Classification` for the core enums and taxonomy.
  """

  @ocsf_version "1.8.0"

  @doc """
  Return the OCSF schema version this library targets.

  ## Examples

      iex> OCSF.version()
      "1.8.0"
  """
  @spec version() :: String.t()
  def version, do: @ocsf_version

  @doc """
  Convert an `%OCSF.Event{}` to an OCSF-compliant nested map.

  Nil fields are omitted. Integer UIDs are emitted as-is; their
  corresponding `_name` labels are added alongside per OCSF convention.

  Delegates to `OCSF.Serializer.to_map/1`.
  """
  @spec to_map(OCSF.Event.t()) :: map
  def to_map(%OCSF.Event{} = event), do: OCSF.Serializer.to_map(event)

  @doc """
  Serialize an `%OCSF.Event{}` to OCSF-compliant JSON iodata.
  """
  @spec to_json(OCSF.Event.t()) :: iodata
  def to_json(%OCSF.Event{} = event), do: event |> to_map() |> Jason.encode_to_iodata!()

  @doc """
  Reconstruct an `%OCSF.Event{}` from a nested OCSF map.

  Delegates to `OCSF.Event.from_map/1`.
  """
  @spec from_map(map) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def from_map(map) when is_map(map), do: OCSF.Event.from_map(map)

  @doc """
  Apply a sink **policy** to an event, returning a **redacted** event.

  Delegates to `OCSF.Policy.apply/2`.
  """
  @spec redact(OCSF.Event.t(), OCSF.Policy.t()) :: OCSF.Event.t()
  def redact(%OCSF.Event{} = event, %OCSF.Policy{} = policy),
    do: OCSF.Policy.apply(policy, event)

  @doc """
  Validate an `%OCSF.Event{}` structurally.

  Runs a 12-step check (SPEC §10): metadata presence, version, product,
  category/class/type consistency, activity/status/severity validity,
  time format, and class-specific required fields.

  Returns `{:ok, event}` on success or `{:error, %OCSF.Error{}}` on
  the first failure.
  """
  @spec validate(OCSF.Event.t()) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def validate(%OCSF.Event{} = event) do
    with :ok <- check_metadata_uid(event),
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
         :ok <- check_class_required_fields(event) do
      {:ok, event}
    end
  end

  defp check_metadata_uid(%{metadata: %{uid: uid}}) when is_binary(uid) and uid != "", do: :ok
  defp check_metadata_uid(_), do: {:error, OCSF.Error.new(:missing, "metadata.uid")}

  defp check_metadata_version(%{metadata: %{version: v}}) when v == @ocsf_version, do: :ok

  defp check_metadata_version(%{metadata: %{version: v}}),
    do: {:error, OCSF.Error.new(:invalid, "metadata.version", %{expected: @ocsf_version, got: v})}

  defp check_metadata_version(_), do: {:error, OCSF.Error.new(:missing, "metadata.version")}

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

  defp check_class_required_fields(%{class_uid: 3004, entity: nil}),
    do:
      {:error,
       OCSF.Error.new(:missing, "entity", %{reason: "required for Entity Management (3004)"})}

  defp check_class_required_fields(%{class_uid: 3006, group: nil}),
    do:
      {:error,
       OCSF.Error.new(:missing, "group", %{reason: "required for Group Management (3006)"})}

  defp check_class_required_fields(_), do: :ok
end
