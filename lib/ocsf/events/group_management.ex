defmodule OCSF.Events.GroupManagement do
  @moduledoc """
  Builder for OCSF Group Management events (class 3006).

  Corresponds to the OCSF
  [Group Management](https://schema.ocsf.io/1.9.0/classes/group_management)
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

  Optional `:resources` lists the `OCSF.ResourceDetails` the group's
  privileges give access to.

  See `OCSF.Group`, `OCSF.ResourceDetails`, `OCSF.Event`, `OCSF.Activity`.
  """

  alias OCSF.Events.Builder

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
    Builder.build(@class_uid, @category_uid, activity_id, opts, %{
      group: opts[:group],
      user: opts[:user],
      resources: opts[:resources]
    })
  end
end
