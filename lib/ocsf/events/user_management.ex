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
  `:iam_roles` the roles assigned or removed, `:privileges` the
  privileges assigned or removed, and `:resources` the
  `OCSF.ResourceDetails` those privileges and roles give access to.

  See `OCSF.User`, `OCSF.IamRole`, `OCSF.ResourceDetails`, `OCSF.Event`,
  `OCSF.Activity`.
  """

  alias OCSF.Events.Builder

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

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.update(
          user: %{uid: "u1"},
          updated_user: %{uid: "u1", name: "Jane R."},
          status: :Success
        )
  """
  @spec update(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def update(opts), do: build(2, opts)

  @doc """
  Build a Delete user event (activity_id 3).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.delete(
          user: %{uid: "u1"},
          status: :Success
        )
  """
  @spec delete(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def delete(opts), do: build(3, opts)

  @doc """
  Build an Enable user event (activity_id 4).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.enable(
          user: %{uid: "u1"},
          status: :Success
        )
  """
  @spec enable(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def enable(opts), do: build(4, opts)

  @doc """
  Build a Disable user event (activity_id 5).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.disable(
          user: %{uid: "u1"},
          status: :Success,
          status_detail: "offboarding"
        )
  """
  @spec disable(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def disable(opts), do: build(5, opts)

  @doc """
  Build a Lock user event (activity_id 6).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.lock(
          user: %{uid: "u1"},
          status: :Success,
          status_detail: "too_many_failed_logons"
        )
  """
  @spec lock(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def lock(opts), do: build(6, opts)

  @doc """
  Build an Unlock user event (activity_id 7).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.unlock(
          user: %{uid: "u1"},
          actor: %{user: %{uid: "admin-1"}},
          status: :Success
        )
  """
  @spec unlock(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def unlock(opts), do: build(7, opts)

  @doc """
  Build a Password Change event (activity_id 8).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.password_change(
          user: %{uid: "u1"},
          status: :Success
        )
  """
  @spec password_change(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def password_change(opts), do: build(8, opts)

  @doc """
  Build a Password Reset event (activity_id 9).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.password_reset(
          user: %{uid: "u1"},
          actor: %{user: %{uid: "admin-1"}},
          status: :Success
        )
  """
  @spec password_reset(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def password_reset(opts), do: build(9, opts)

  @doc """
  Build an Attach Policies event (activity_id 10).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.attach_policies(
          user: %{uid: "u1"},
          status_detail: "policy:mfa-required",
          status: :Success
        )
  """
  @spec attach_policies(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def attach_policies(opts), do: build(10, opts)

  @doc """
  Build a Detach Policies event (activity_id 11).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.detach_policies(
          user: %{uid: "u1"},
          status_detail: "policy:mfa-required",
          status: :Success
        )
  """
  @spec detach_policies(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def detach_policies(opts), do: build(11, opts)

  @doc """
  Build an Enable MFA Factors event (activity_id 12).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.enable_mfa_factors(
          user: %{uid: "u1"},
          status_detail: "totp",
          status: :Success
        )
  """
  @spec enable_mfa_factors(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def enable_mfa_factors(opts), do: build(12, opts)

  @doc """
  Build a Disable MFA Factors event (activity_id 13).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.disable_mfa_factors(
          user: %{uid: "u1"},
          status_detail: "totp",
          status: :Success
        )
  """
  @spec disable_mfa_factors(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def disable_mfa_factors(opts), do: build(13, opts)

  @doc """
  Build an Assign Privileges event (activity_id 14).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.assign_privileges(
          user: %{uid: "u1"},
          privileges: ["billing:write"],
          status: :Success
        )
  """
  @spec assign_privileges(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_privileges(opts), do: build(14, opts)

  @doc """
  Build a Remove Privileges event (activity_id 15).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.remove_privileges(
          user: %{uid: "u1"},
          privileges: ["billing:write"],
          status: :Success
        )
  """
  @spec remove_privileges(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_privileges(opts), do: build(15, opts)

  @doc """
  Build an Assign Roles event (activity_id 16).

  Pass `:iam_roles` (a list of `%OCSF.IamRole{}` or plain maps) for the
  roles granted to the user.

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.assign_roles(
          user: %{uid: "u1"},
          iam_roles: [%{name: "admin", uid: "role-1"}],
          status: :Success
        )
  """
  @spec assign_roles(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def assign_roles(opts), do: build(16, opts)

  @doc """
  Build a Remove Roles event (activity_id 17).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.remove_roles(
          user: %{uid: "u1"},
          iam_roles: [%{name: "admin", uid: "role-1"}],
          status: :Success
        )
  """
  @spec remove_roles(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_roles(opts), do: build(17, opts)

  @doc """
  Build an Add Programmatic Credentials event (activity_id 18).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.add_programmatic_credentials(
          user: %{uid: "u1"},
          status_detail: "api_key",
          status: :Success
        )
  """
  @spec add_programmatic_credentials(keyword) ::
          {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def add_programmatic_credentials(opts), do: build(18, opts)

  @doc """
  Build a Remove Programmatic Credentials event (activity_id 19).

  ## Examples

      {:ok, event} =
        OCSF.Events.UserManagement.remove_programmatic_credentials(
          user: %{uid: "u1"},
          status_detail: "api_key",
          status: :Success
        )
  """
  @spec remove_programmatic_credentials(keyword) ::
          {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def remove_programmatic_credentials(opts), do: build(19, opts)

  # -- Internal builder --

  defp build(activity_id, opts) do
    Builder.build(@class_uid, @category_uid, activity_id, opts, %{
      user: opts[:user],
      updated_user: opts[:updated_user],
      iam_roles: opts[:iam_roles],
      privileges: opts[:privileges],
      resources: opts[:resources]
    })
  end
end
