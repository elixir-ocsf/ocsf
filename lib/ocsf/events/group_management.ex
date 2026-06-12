defmodule OCSF.Events.GroupManagement do
  @moduledoc """
  Builder for OCSF Group Management events (class 3006).

  Corresponds to the OCSF
  [Group Management](https://schema.ocsf.io/1.8.0/classes/group_management)
  class under the Identity & Access Management category (UID 3). Used to
  audit group lifecycle and membership changes -- create, delete, and
  add/remove user.

  Each function maps to an OCSF activity:

  | Function             | Activity ID | OCSF name          |
  |----------------------|-------------|--------------------|
  | `assign_privileges/1`| 1           | Assign Privileges  |
  | `revoke_privileges/1`| 2           | Revoke Privileges  |
  | `add_user/1`         | 3           | Add User           |
  | `remove_user/1`      | 4           | Remove User        |
  | `delete/1`           | 5           | Delete             |
  | `create/1`           | 6           | Create             |
  | `add_subgroup/1`     | 7           | Add Subgroup       |
  | `remove_subgroup/1`  | 8           | Remove Subgroup    |

  > **OCSF compliance note:** `group` is a required field for the Group
  > Management class. Builders return `{:error, _}` if omitted. For
  > membership activities, pass the affected `user` as well.

  See `OCSF.Group`, `OCSF.Event`, `OCSF.Activity`.
  """

  @class_uid 3006
  @category_uid 3

  @doc """
  Build an Assign Privileges event (activity_id 1).
  """
  @spec assign_privileges(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_privileges(opts), do: build(1, opts)

  @doc """
  Build a Revoke Privileges event (activity_id 2).
  """
  @spec revoke_privileges(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def revoke_privileges(opts), do: build(2, opts)

  @doc """
  Build an Add User event (activity_id 3).

  ## Options

  See `OCSF.Event` for all accepted top-level keys. Required:

  - **`:group`** — map with at least `:uid`. Cast to `%OCSF.Group{}`.

  Pass `:user` for the member added to the group.

  ## Examples

      {:ok, event} =
        OCSF.Events.GroupManagement.add_user(
          group: %{uid: "g1", name: "Admins"},
          user: %{uid: "u1"},
          status: :Success
        )
  """
  @spec add_user(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def add_user(opts), do: build(3, opts)

  @doc """
  Build a Remove User event (activity_id 4).
  """
  @spec remove_user(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_user(opts), do: build(4, opts)

  @doc """
  Build a Delete group event (activity_id 5).
  """
  @spec delete(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def delete(opts), do: build(5, opts)

  @doc """
  Build a Create group event (activity_id 6).
  """
  @spec create(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def create(opts), do: build(6, opts)

  @doc """
  Build an Add Subgroup event (activity_id 7).
  """
  @spec add_subgroup(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def add_subgroup(opts), do: build(7, opts)

  @doc """
  Build a Remove Subgroup event (activity_id 8).
  """
  @spec remove_subgroup(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_subgroup(opts), do: build(8, opts)

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
      group: opts[:group],
      user: opts[:user],
      actor: opts[:actor],
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
