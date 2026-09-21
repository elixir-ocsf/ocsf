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
  > `iam_roles`; builders return `{:error, %{reason: :constraint_violated}}`
  > when none is given. Pass the one relevant to the activity.

  See `OCSF.User`, `OCSF.Group`, `OCSF.IamRole`, `OCSF.Event`,
  `OCSF.Activity`.
  """

  alias OCSF.Events.Builder

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
    Builder.build(@class_uid, @category_uid, activity_id, opts, %{
      user: opts[:user],
      group: opts[:group],
      groups: opts[:groups],
      iam_roles: opts[:iam_roles],
      privileges: opts[:privileges]
    })
  end
end
