defmodule OCSF.Events.AccountChange do
  @moduledoc """
  Builder for OCSF Account Change events (class 3001).

  Corresponds to the OCSF
  [Account Change](https://schema.ocsf.io/1.8.0/classes/account_change)
  class under the Identity & Access Management category (UID 3). Used to
  audit changes to a user account -- creation, enable/disable, password
  and MFA factor changes, policy attach/detach, and lock/unlock.

  Each function maps to an OCSF activity:

  | Function                | Activity ID | OCSF name          |
  |-------------------------|-------------|--------------------|
  | `create/1`              | 1           | Create             |
  | `enable/1`              | 2           | Enable             |
  | `password_change/1`     | 3           | Password Change    |
  | `password_reset/1`      | 4           | Password Reset     |
  | `disable/1`             | 5           | Disable            |
  | `delete/1`              | 6           | Delete             |
  | `attach_policy/1`       | 7           | Attach Policy      |
  | `detach_policy/1`       | 8           | Detach Policy      |
  | `lock/1`                | 9           | Lock               |
  | `mfa_factor_enable/1`   | 10          | MFA Factor Enable  |
  | `mfa_factor_disable/1`  | 11          | MFA Factor Disable |
  | `unlock/1`              | 12          | Unlock             |

  > **OCSF compliance note:** `user` is a required field for the Account
  > Change class. Builders return `{:error, _}` if omitted.

  See `OCSF.User`, `OCSF.Event`, `OCSF.Activity`.
  """

  @class_uid 3001
  @category_uid 3

  @doc """
  Build a Create account event (activity_id 1).

  ## Options

  See `OCSF.Event` for all accepted top-level keys. Required:

  - **`:user`** — map with at least `:uid`. Cast to `%OCSF.User{}`.

  ## Examples

      {:ok, event} =
        OCSF.Events.AccountChange.create(
          user: %{uid: "u1", name: "Jane"},
          status: :Success
        )
  """
  @spec create(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def create(opts), do: build(1, opts)

  @doc """
  Build an Enable account event (activity_id 2).
  """
  @spec enable(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def enable(opts), do: build(2, opts)

  @doc """
  Build a Password Change event (activity_id 3).
  """
  @spec password_change(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def password_change(opts), do: build(3, opts)

  @doc """
  Build a Password Reset event (activity_id 4).
  """
  @spec password_reset(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def password_reset(opts), do: build(4, opts)

  @doc """
  Build a Disable account event (activity_id 5).
  """
  @spec disable(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def disable(opts), do: build(5, opts)

  @doc """
  Build a Delete account event (activity_id 6).
  """
  @spec delete(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def delete(opts), do: build(6, opts)

  @doc """
  Build an Attach Policy event (activity_id 7).
  """
  @spec attach_policy(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def attach_policy(opts), do: build(7, opts)

  @doc """
  Build a Detach Policy event (activity_id 8).
  """
  @spec detach_policy(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def detach_policy(opts), do: build(8, opts)

  @doc """
  Build a Lock account event (activity_id 9).
  """
  @spec lock(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def lock(opts), do: build(9, opts)

  @doc """
  Build an MFA Factor Enable event (activity_id 10).
  """
  @spec mfa_factor_enable(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def mfa_factor_enable(opts), do: build(10, opts)

  @doc """
  Build an MFA Factor Disable event (activity_id 11).
  """
  @spec mfa_factor_disable(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def mfa_factor_disable(opts), do: build(11, opts)

  @doc """
  Build an Unlock account event (activity_id 12).
  """
  @spec unlock(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def unlock(opts), do: build(12, opts)

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
