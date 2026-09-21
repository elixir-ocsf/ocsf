defmodule OCSF.Events.ApiActivity do
  @moduledoc """
  Builder for OCSF API Activity events (class 6003).

  Corresponds to the OCSF
  [API Activity](https://schema.ocsf.io/1.9.0/classes/api_activity)
  class under the Application Activity category (UID 6). Used to audit
  management-plane / programmatic API calls -- the CRUD operations a
  caller performs against a service's API.

  Each function maps to an OCSF activity:

  | Function   | Activity ID | OCSF name |
  |------------|-------------|-----------|
  | `create/1` | 1           | Create    |
  | `read/1`   | 2           | Read      |
  | `update/1` | 3           | Update    |
  | `delete/1` | 4           | Delete    |

  > **OCSF compliance note:** `api`, `actor`, and `src_endpoint` are
  > required fields for the API Activity class. Builders return
  > `{:error, _}` if any is omitted.

  Optional `:resources` lists the `OCSF.ResourceDetails` affected by the
  call. The class defines no top-level `user` or `service`: the caller
  goes in `actor.user` and the called service in `api.service`.

  See `OCSF.Api`, `OCSF.Actor`, `OCSF.NetworkEndpoint`,
  `OCSF.ResourceDetails`, `OCSF.Event`.
  """

  alias OCSF.Events.Builder

  @class_uid 6003
  @category_uid 6

  @doc """
  Build a Create API Activity event (activity_id 1).

  ## Options

  See `OCSF.Event` for all accepted top-level keys. Required:

  - **`:api`** — map with at least `:operation`. Cast to `%OCSF.Api{}`.
  - **`:actor`** — map with the calling actor. Cast to `%OCSF.Actor{}`.
  - **`:src_endpoint`** — the caller network endpoint.

  ## Examples

      {:ok, event} =
        OCSF.Events.ApiActivity.create(
          api: %{operation: "CreateUser", service: %{name: "scim"}},
          actor: %{user: %{uid: "admin-1"}},
          src_endpoint: %{ip: "10.0.0.1"},
          status: :Success
        )
  """
  @spec create(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def create(opts), do: build(1, opts)

  @doc """
  Build a Read API Activity event (activity_id 2).
  """
  @spec read(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def read(opts), do: build(2, opts)

  @doc """
  Build an Update API Activity event (activity_id 3).
  """
  @spec update(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def update(opts), do: build(3, opts)

  @doc """
  Build a Delete API Activity event (activity_id 4).
  """
  @spec delete(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def delete(opts), do: build(4, opts)

  # -- Internal builder --

  defp build(activity_id, opts) do
    Builder.build(@class_uid, @category_uid, activity_id, opts, %{
      api: opts[:api],
      resources: opts[:resources]
    })
  end
end
