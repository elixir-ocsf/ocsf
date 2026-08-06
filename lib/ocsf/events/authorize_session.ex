defmodule OCSF.Events.AuthorizeSession do
  @moduledoc """
  Builder for OCSF Authorize Session events (class 3003).

  Corresponds to the OCSF
  [Authorize Session](https://schema.ocsf.io/1.9.0/classes/authorize_session)
  class under the Identity & Access Management category (UID 3). Used to
  record privileges and groups assigned to a newly established user
  session (e.g. right after logon).

  Each function maps to an OCSF activity:

  | Function             | Activity ID | OCSF name         |
  |----------------------|-------------|-------------------|
  | `assign_privileges/1`| 1           | Assign Privileges |
  | `assign_groups/1`    | 2           | Assign Groups     |
  | `assign_roles/1`     | 3           | Assign Roles      |

  > **OCSF compliance note:** `user` is a required field for the
  > Authorize Session class. Builders return `{:error, _}` if omitted.
  > OCSF also requires at least one of `privileges`, `groups`, or
  > `iam_roles`; pass the one relevant to the activity.

  See `OCSF.User`, `OCSF.Group`, `OCSF.IamRole`, `OCSF.Event`,
  `OCSF.Activity`.
  """

  @class_uid 3003
  @category_uid 3

  @doc """
  Build an Assign Privileges event (activity_id 1).

  ## Options

  See `OCSF.Event` for all accepted top-level keys. Required:

  - **`:user`** — map with at least `:uid`. Cast to `%OCSF.User{}`.

  Pass `:privileges` (a list of strings) for the granted privileges.

  ## Examples

      {:ok, event} =
        OCSF.Events.AuthorizeSession.assign_privileges(
          user: %{uid: "u1"},
          privileges: ["read:reports", "write:reports"],
          status: :Success
        )
  """
  @spec assign_privileges(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_privileges(opts), do: build(1, opts)

  @doc """
  Build an Assign Groups event (activity_id 2).

  Pass `:groups` (a list of `%OCSF.Group{}` or plain maps) for the
  groups whose membership grants access.
  """
  @spec assign_groups(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_groups(opts), do: build(2, opts)

  @doc """
  Build an Assign Roles event (activity_id 3).

  Pass `:iam_roles` (a list of `%OCSF.IamRole{}` or plain maps) for the
  roles materialised into the authorized session.
  """
  @spec assign_roles(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_roles(opts), do: build(3, opts)

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
      user: opts[:user],
      group: opts[:group],
      groups: opts[:groups],
      iam_roles: opts[:iam_roles],
      privileges: opts[:privileges],
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
