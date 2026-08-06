defmodule OCSF.Events.EntityManagement do
  @moduledoc """
  Builder for OCSF Entity Management events (class 3004).

  Corresponds to the OCSF
  [Entity Management](https://schema.ocsf.io/1.9.0/classes/entity_management)
  class under the Identity & Access Management category (UID 3). Used to
  audit the lifecycle of managed entities -- users, groups, and other
  records (create / update / delete / activate).

  Each function maps to an OCSF activity:

  | Function        | Activity ID | OCSF name   |
  |-----------------|-------------|-------------|
  | `create/1`      | 1           | Create      |
  | `read/1`        | 2           | Read        |
  | `update/1`      | 3           | Update      |
  | `delete/1`      | 4           | Delete      |
  | `activate/1`    | 10          | Activate    |
  | `deactivate/1`  | 11          | Deactivate  |

  > **OCSF compliance note:** `entity` is a required field for the
  > Entity Management class. Builders return `{:error, _}` if omitted.

  See `OCSF.Entity`, `OCSF.Event`, `OCSF.Activity`.
  """

  @class_uid 3004
  @category_uid 3

  @doc """
  Build a Create entity event (activity_id 1).

  ## Options

  See `OCSF.Event` for all accepted top-level keys. Required:

  - **`:entity`** — map with at least `:uid`. Cast to `%OCSF.Entity{}`.

  ## Examples

      {:ok, event} =
        OCSF.Events.EntityManagement.create(
          entity: %{uid: "u1", type: "User", name: "Jane"},
          status: :Success
        )
  """
  @spec create(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def create(opts), do: build(1, opts)

  @doc """
  Build a Read entity event (activity_id 2).
  """
  @spec read(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def read(opts), do: build(2, opts)

  @doc """
  Build an Update entity event (activity_id 3).
  """
  @spec update(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def update(opts), do: build(3, opts)

  @doc """
  Build a Delete entity event (activity_id 4).
  """
  @spec delete(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def delete(opts), do: build(4, opts)

  @doc """
  Build an Activate entity event (activity_id 10).
  """
  @spec activate(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def activate(opts), do: build(10, opts)

  @doc """
  Build a Deactivate entity event (activity_id 11).
  """
  @spec deactivate(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def deactivate(opts), do: build(11, opts)

  # -- Internal builder --

  defp build(activity_id, opts) do
    severity = resolve_severity(opts[:severity])
    status = resolve_status(opts[:status])
    time = opts[:time] || DateTime.utc_now()
    correlation_uid = opts[:correlation_uid] || OCSF.Correlation.current()
    metadata_input = opts[:metadata] || %{}

    metadata = build_metadata(metadata_input, correlation_uid, opts)

    attrs = %{
      metadata: metadata,
      time: time,
      category_uid: @category_uid,
      class_uid: @class_uid,
      type_uid: @class_uid * 100 + activity_id,
      activity_id: activity_id,
      severity_id: severity,
      status_id: status,
      status_detail: opts[:status_detail],
      entity: opts[:entity],
      actor: opts[:actor],
      user: opts[:user],
      http_request: opts[:http_request],
      src_endpoint: opts[:src_endpoint],
      dst_endpoint: opts[:dst_endpoint],
      service: opts[:service],
      raw_data: opts[:raw_data],
      unmapped: opts[:unmapped]
    }

    with {:ok, event} <- OCSF.Event.new(attrs),
         {:ok, event} <- OCSF.validate(event) do
      event = resolve_event_code(event, opts)
      OCSF.Telemetry.event_new(@class_uid, activity_id)
      {:ok, event}
    else
      {:error, error} ->
        OCSF.Telemetry.event_invalid(error.reason, error.path, @class_uid)
        {:error, error}
    end
  end

  defp build_metadata(input, correlation_uid, opts) do
    base = if is_struct(input, OCSF.Metadata), do: Map.from_struct(input), else: input

    %{
      uid: get_base(base, :uid) || OCSF.UUID.v7_string(),
      version: OCSF.version(),
      product: get_base(base, :product) || %OCSF.Product{},
      profiles: get_base(base, :profiles) || [],
      event_code: opts[:event_code] || get_base(base, :event_code),
      correlation_uid: opts[:correlation_uid] || correlation_uid,
      trace_uid: opts[:trace_uid] || get_base(base, :trace_uid),
      span_uid: opts[:span_uid] || get_base(base, :span_uid)
    }
  end

  defp get_base(base, key), do: base[key] || base[to_string(key)]

  defp resolve_event_code(event, opts) do
    cond do
      event.metadata.event_code != nil ->
        event

      format_name = opts[:event_code_format] ->
        apply_format(event, format_name)

      default = OCSF.EventCodeFormat.default_format() ->
        apply_format(event, default)

      true ->
        event
    end
  end

  defp apply_format(event, format_name) do
    case OCSF.EventCodeFormat.get(format_name) do
      nil ->
        event

      format ->
        code = OCSF.EventCodeFormat.generate(format, event)
        put_in(event.metadata.event_code, code)
    end
  end

  defp resolve_severity(nil), do: OCSF.Severity.uid(:Informational)
  defp resolve_severity(id) when is_integer(id), do: id
  defp resolve_severity(name) when is_atom(name), do: OCSF.Severity.uid(name) || 0

  defp resolve_status(nil), do: OCSF.Status.uid(:Unknown)
  defp resolve_status(id) when is_integer(id), do: id
  defp resolve_status(name) when is_atom(name), do: OCSF.Status.uid(name) || 0
end
