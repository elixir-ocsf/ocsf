defmodule OCSF.Events.RoleManagement do
  @moduledoc """
  Builder for OCSF Role Management events (class 3008).

  Corresponds to the OCSF
  [Role Management](https://schema.ocsf.io/1.9.0/classes/role_management)
  class under the Identity & Access Management category (UID 3). Added in
  OCSF 1.9, it audits the lifecycle of an IAM role -- creation, update,
  deletion, and the assignment or removal of privileges, resources,
  policies, and programmatic credentials.

  Each function maps to an OCSF activity:

  | Function                            | Activity ID | OCSF name                       |
  |-------------------------------------|-------------|---------------------------------|
  | `create/1`                          | 1           | Create                          |
  | `update/1`                          | 2           | Update                          |
  | `delete/1`                          | 3           | Delete                          |
  | `assign_privileges/1`               | 4           | Assign Privileges               |
  | `remove_privileges/1`               | 5           | Remove Privileges               |
  | `assign_resources/1`                | 6           | Assign Resources                |
  | `remove_resources/1`                | 7           | Remove Resources                |
  | `attach_policies/1`                 | 8           | Attach Policies                 |
  | `detach_policies/1`                 | 9           | Detach Policies                 |
  | `add_programmatic_credentials/1`    | 10          | Add Programmatic Credentials    |
  | `remove_programmatic_credentials/1` | 11          | Remove Programmatic Credentials |

  > **OCSF compliance note:** `iam_role` is a required field for the Role
  > Management class. Builders return `{:error, _}` if omitted.

  Optional `:updated_role` records the target role after the change,
  `:privileges` the privileges assigned or removed, and `:resources` the
  `OCSF.ResourceDetails` assigned or removed (each needs a `name` or a
  `uid`).

  See `OCSF.IamRole`, `OCSF.ResourceDetails`, `OCSF.Event`,
  `OCSF.Activity`.
  """

  alias OCSF.Events.Builder

  @class_uid 3008
  @category_uid 3

  @doc """
  Build a Create role event (activity_id 1).

  ## Options

  See `OCSF.Event` for all accepted top-level keys. Required:

  - **`:iam_role`** — map with at least `:name` and `:uid`. Cast to
    `%OCSF.IamRole{}`.

  Optional: `:updated_role`, `:privileges`, `:resources`.

  ## Examples

      {:ok, event} =
        OCSF.Events.RoleManagement.create(
          iam_role: %{name: "admin", uid: "role-1"},
          status: :Success
        )
  """
  @spec create(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def create(opts), do: build(1, opts)

  @doc """
  Build an Update role event (activity_id 2).
  """
  @spec update(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def update(opts), do: build(2, opts)

  @doc """
  Build a Delete role event (activity_id 3).
  """
  @spec delete(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def delete(opts), do: build(3, opts)

  @doc """
  Build an Assign Privileges event (activity_id 4).
  """
  @spec assign_privileges(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_privileges(opts), do: build(4, opts)

  @doc """
  Build a Remove Privileges event (activity_id 5).
  """
  @spec remove_privileges(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_privileges(opts), do: build(5, opts)

  @doc """
  Build an Assign Resources event (activity_id 6).

  Pass `:resources` (a list of `OCSF.ResourceDetails` maps, each with a
  `:name` or `:uid`) granted to the role.
  """
  @spec assign_resources(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_resources(opts), do: build(6, opts)

  @doc """
  Build a Remove Resources event (activity_id 7).
  """
  @spec remove_resources(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_resources(opts), do: build(7, opts)

  @doc """
  Build an Attach Policies event (activity_id 8).
  """
  @spec attach_policies(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def attach_policies(opts), do: build(8, opts)

  @doc """
  Build a Detach Policies event (activity_id 9).
  """
  @spec detach_policies(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def detach_policies(opts), do: build(9, opts)

  @doc """
  Build an Add Programmatic Credentials event (activity_id 10).
  """
  @spec add_programmatic_credentials(keyword) ::
          {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def add_programmatic_credentials(opts), do: build(10, opts)

  @doc """
  Build a Remove Programmatic Credentials event (activity_id 11).
  """
  @spec remove_programmatic_credentials(keyword) ::
          {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_programmatic_credentials(opts), do: build(11, opts)

  # -- Internal builder --

  defp build(activity_id, opts) do
    Builder.build(@class_uid, @category_uid, activity_id, opts, %{
      iam_role: opts[:iam_role],
      updated_role: opts[:updated_role],
      privileges: opts[:privileges],
      resources: opts[:resources]
    })
  end
end
