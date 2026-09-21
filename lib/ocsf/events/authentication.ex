defmodule OCSF.Events.Authentication do
  @moduledoc """
  Builder for OCSF Authentication events (class 3002).

  Corresponds to the OCSF
  [Authentication](https://schema.ocsf.io/1.9.0/classes/authentication)
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
  > Authentication class, and OCSF requires at least one of `service`
  > or `dst_endpoint`. Builders return `{:error, _}` (reason `:missing`
  > or `:constraint_violated`) when either rule is not met.

  See `OCSF.Event`, `OCSF.Activity`, `OCSF.EventCodeFormat`.
  """

  alias OCSF.Events.Builder

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
    Builder.build(@class_uid, @category_uid, activity_id, opts, %{
      auth_protocol_id: resolve_auth_protocol(opts[:auth_protocol]),
      user: opts[:user],
      service: opts[:service]
    })
  end

  defp resolve_auth_protocol(nil), do: nil
  defp resolve_auth_protocol(id) when is_integer(id), do: id
  defp resolve_auth_protocol(name) when is_atom(name), do: OCSF.AuthProtocol.uid(name)
end
