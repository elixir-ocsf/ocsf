defmodule OCSF.Events.UserManagement do
  @moduledoc """
  Builder for OCSF User Management events (class 3007).

  Corresponds to the OCSF
  [User Management](https://schema.ocsf.io/1.9.0/classes/user_management)
  class under the Identity & Access Management category (UID 3). Added in
  OCSF 1.9, it supersedes the deprecated Account Change (3001) class and
  audits the full lifecycle of a user account -- creation, enable/disable,
  lock/unlock, credential and MFA changes, and the assignment or removal
  of privileges and roles.

  Each function maps to an OCSF activity:

  | Function                          | Activity ID | OCSF name                       |
  |-----------------------------------|-------------|---------------------------------|
  | `create/1`                        | 1           | Create                          |
  | `update/1`                        | 2           | Update                          |
  | `delete/1`                        | 3           | Delete                          |
  | `enable/1`                        | 4           | Enable                          |
  | `disable/1`                       | 5           | Disable                         |
  | `lock/1`                          | 6           | Lock                            |
  | `unlock/1`                        | 7           | Unlock                          |
  | `password_change/1`               | 8           | Password Change                 |
  | `password_reset/1`                | 9           | Password Reset                  |
  | `attach_policies/1`               | 10          | Attach Policies                 |
  | `detach_policies/1`               | 11          | Detach Policies                 |
  | `enable_mfa_factors/1`            | 12          | Enable MFA Factors              |
  | `disable_mfa_factors/1`           | 13          | Disable MFA Factors             |
  | `assign_privileges/1`             | 14          | Assign Privileges               |
  | `remove_privileges/1`             | 15          | Remove Privileges               |
  | `assign_roles/1`                  | 16          | Assign Roles                    |
  | `remove_roles/1`                  | 17          | Remove Roles                    |
  | `add_programmatic_credentials/1`  | 18          | Add Programmatic Credentials    |
  | `remove_programmatic_credentials/1` | 19        | Remove Programmatic Credentials |

  > **OCSF compliance note:** `user` is a required field for the User
  > Management class. Builders return `{:error, _}` if omitted.

  Optional `:updated_user` records the target user after the change,
  `:iam_roles` the roles assigned or removed, and `:privileges` the
  privileges assigned or removed.

  See `OCSF.User`, `OCSF.IamRole`, `OCSF.Event`, `OCSF.Activity`.
  """

  @class_uid 3007
  @category_uid 3

  @doc """
  Build a Create user event (activity_id 1).

  ## Options

  See `OCSF.Event` for all accepted top-level keys. Required:

  - **`:user`** — map with at least `:uid`. Cast to `%OCSF.User{}`.

  Optional: `:updated_user`, `:iam_roles`, `:privileges`.

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.create(
          user: %{uid: "u1", name: "Jane"},
          status: :Success
        )
  """
  @spec create(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def create(opts), do: build(1, opts)

  @doc """
  Build an Update user event (activity_id 2).
  """
  @spec update(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def update(opts), do: build(2, opts)

  @doc """
  Build a Delete user event (activity_id 3).
  """
  @spec delete(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def delete(opts), do: build(3, opts)

  @doc """
  Build an Enable user event (activity_id 4).
  """
  @spec enable(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def enable(opts), do: build(4, opts)

  @doc """
  Build a Disable user event (activity_id 5).
  """
  @spec disable(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def disable(opts), do: build(5, opts)

  @doc """
  Build a Lock user event (activity_id 6).
  """
  @spec lock(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def lock(opts), do: build(6, opts)

  @doc """
  Build an Unlock user event (activity_id 7).
  """
  @spec unlock(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def unlock(opts), do: build(7, opts)

  @doc """
  Build a Password Change event (activity_id 8).
  """
  @spec password_change(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def password_change(opts), do: build(8, opts)

  @doc """
  Build a Password Reset event (activity_id 9).
  """
  @spec password_reset(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def password_reset(opts), do: build(9, opts)

  @doc """
  Build an Attach Policies event (activity_id 10).
  """
  @spec attach_policies(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def attach_policies(opts), do: build(10, opts)

  @doc """
  Build a Detach Policies event (activity_id 11).
  """
  @spec detach_policies(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def detach_policies(opts), do: build(11, opts)

  @doc """
  Build an Enable MFA Factors event (activity_id 12).
  """
  @spec enable_mfa_factors(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def enable_mfa_factors(opts), do: build(12, opts)

  @doc """
  Build a Disable MFA Factors event (activity_id 13).
  """
  @spec disable_mfa_factors(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def disable_mfa_factors(opts), do: build(13, opts)

  @doc """
  Build an Assign Privileges event (activity_id 14).
  """
  @spec assign_privileges(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_privileges(opts), do: build(14, opts)

  @doc """
  Build a Remove Privileges event (activity_id 15).
  """
  @spec remove_privileges(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_privileges(opts), do: build(15, opts)

  @doc """
  Build an Assign Roles event (activity_id 16).

  Pass `:iam_roles` (a list of `%OCSF.IamRole{}` or plain maps) for the
  roles granted to the user.
  """
  @spec assign_roles(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_roles(opts), do: build(16, opts)

  @doc """
  Build a Remove Roles event (activity_id 17).
  """
  @spec remove_roles(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_roles(opts), do: build(17, opts)

  @doc """
  Build an Add Programmatic Credentials event (activity_id 18).
  """
  @spec add_programmatic_credentials(keyword) ::
          {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def add_programmatic_credentials(opts), do: build(18, opts)

  @doc """
  Build a Remove Programmatic Credentials event (activity_id 19).
  """
  @spec remove_programmatic_credentials(keyword) ::
          {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_programmatic_credentials(opts), do: build(19, opts)

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
      updated_user: opts[:updated_user],
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
