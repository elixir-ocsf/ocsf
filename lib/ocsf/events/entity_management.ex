defmodule OCSF.Events.EntityManagement do
  @moduledoc """
  Builder for OCSF Entity Management events (class 3004).

  Corresponds to the OCSF
  [Entity Management](https://schema.ocsf.io/1.9.0/classes/entity_management)
  class under the Identity & Access Management category (UID 3). Used to
  audit the lifecycle of managed entities -- users, groups, and other
  records (create / update / delete / activate).

  Each function maps to an OCSF activity:

  | Function        | Activity ID | OCSF name   |
  |-----------------|-------------|-------------|
  | `create/1`      | 1           | Create      |
  | `read/1`        | 2           | Read        |
  | `update/1`      | 3           | Update      |
  | `delete/1`      | 4           | Delete      |
  | `activate/1`    | 10          | Activate    |
  | `deactivate/1`  | 11          | Deactivate  |

  > **OCSF compliance note:** `entity` is a required field for the
  > Entity Management class. Builders return `{:error, _}` if omitted.
  > The class defines no top-level `user` or `service`: identify the
  > caller through `actor.user`.

  See `OCSF.Entity`, `OCSF.Actor`, `OCSF.Event`, `OCSF.Activity`.
  """

  alias OCSF.Events.Builder

  @class_uid 3004
  @category_uid 3

  @doc """
  Build a Create entity event (activity_id 1).

  ## Options

  See `OCSF.Event` for all accepted top-level keys. Required:

  - **`:entity`** — map with at least `:uid`. Cast to `%OCSF.Entity{}`.

  ## Examples

      {:ok, event} =
        OCSF.Events.EntityManagement.create(
          entity: %{uid: "u1", type: "User", name: "Jane"},
          status: :Success
        )
  """
  @spec create(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def create(opts), do: build(1, opts)

  @doc """
  Build a Read entity event (activity_id 2).
  """
  @spec read(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def read(opts), do: build(2, opts)

  @doc """
  Build an Update entity event (activity_id 3).
  """
  @spec update(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def update(opts), do: build(3, opts)

  @doc """
  Build a Delete entity event (activity_id 4).
  """
  @spec delete(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def delete(opts), do: build(4, opts)

  @doc """
  Build an Activate entity event (activity_id 10).
  """
  @spec activate(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def activate(opts), do: build(10, opts)

  @doc """
  Build a Deactivate entity event (activity_id 11).
  """
  @spec deactivate(keyword) :: {:ok, OCSF.Event.t()} | {:error, OCSF.Error.t()}
  def deactivate(opts), do: build(11, opts)

  # -- Internal builder --

  defp build(activity_id, opts) do
    Builder.build(@class_uid, @category_uid, activity_id, opts, %{
      entity: opts[:entity]
    })
  end
end
