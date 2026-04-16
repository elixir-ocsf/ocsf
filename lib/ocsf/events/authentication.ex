defmodule OCSF.Events.Authentication do
  @moduledoc """
  Builder for OCSF Authentication events (class 3002).

  Corresponds to the OCSF
  [Authentication](https://schema.ocsf.io/1.8.0/classes/authentication)
  class under the Identity & Access Management category (UID 3).

  Each function maps to an OCSF activity:

  | Function                 | Activity ID | OCSF name            |
  |--------------------------|-------------|----------------------|
  | `logon/1`                | 1           | Logon                |
  | `logoff/1`               | 2           | Logoff               |
  | `preauth/1`              | 6           | Preauth              |
  | `authentication_ticket/1`| 3           | Authentication Ticket|
  | `account_switch/1`       | 7           | Account Switch       |

  > **OCSF compliance note:** `user` is a required field for the
  > Authentication class. Builders return `{:error, _}` if omitted.

  See `OCSF.Event`, `OCSF.Activity`, `OCSF.EventCodeFormat`.
  """

  @class_uid 3002
  @category_uid 3

  @doc """
  Build a Logon authentication event (activity_id 1).

  ## Options

  See `OCSF.Event` for all accepted top-level keys. Required:

  - **`:user`** — map with at least `:uid`. Cast to `%OCSF.User{}`.

  ## Examples

      {:ok, event} =
        OCSF.Events.Authentication.logon(
          user: %{uid: "u1", org: %{uid: "acme"}},
          status: :Success,
          severity: :Informational
        )
  """
  @spec logon(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def logon(opts), do: build(1, opts)

  @doc """
  Build a Logoff authentication event (activity_id 2).
  """
  @spec logoff(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def logoff(opts), do: build(2, opts)

  @doc """
  Build a Preauth authentication event (activity_id 6).
  """
  @spec preauth(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def preauth(opts), do: build(6, opts)

  @doc """
  Build an Authentication Ticket event (activity_id 3).
  """
  @spec authentication_ticket(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def authentication_ticket(opts), do: build(3, opts)

  @doc """
  Build an Account Switch event (activity_id 7).
  """
  @spec account_switch(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def account_switch(opts), do: build(7, opts)

  # -- Internal builder --

  defp build(activity_id, opts) do
    severity = resolve_severity(opts[:severity])
    status = resolve_status(opts[:status])
    auth_protocol = resolve_auth_protocol(opts[:auth_protocol])
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
      auth_protocol_id: auth_protocol,
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
      # Explicit event_code already set
      event.metadata.event_code != nil ->
        event

      # Format specified in opts
      format_name = opts[:event_code_format] ->
        apply_format(event, format_name)

      # Default format from config
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

  defp resolve_auth_protocol(nil), do: nil
  defp resolve_auth_protocol(id) when is_integer(id), do: id
  defp resolve_auth_protocol(name) when is_atom(name), do: OCSF.AuthProtocol.uid(name)
end
