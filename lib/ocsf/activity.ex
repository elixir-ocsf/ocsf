defmodule OCSF.Activity do
  @moduledoc """
  OCSF per-class activity mappings.

  Maps activity names to their OCSF 1.8 numeric identifiers within each
  event class. Activities describe *what* happened in a given event class
  (e.g. Logon, Logoff for Authentication).

  See the OCSF
  [activity_id](https://schema.ocsf.io/1.8.0/data_types/integer?caption=activity_id)
  definition.

  ## Activities by class

  | Class UID | Activity          | ID |
  |-----------|-------------------|----|
  | 3002      | `:Logon`          | 1  |
  | 3002      | `:Logoff`         | 2  |
  | 3002      | `:Preauth`        | 6  |
  | 3001      | `:Create`         | 1  |
  | 3001      | `:Delete`         | 6  |
  | 3003      | `:"Assign Privileges"` | 1 |
  | 6003      | `:Create`         | 1  |
  | ...       | ...               | ...|

  See `OCSF.Class` for class definitions.
  """

  @mappings %{
    3002 => [
      {:Unknown, 0},
      {:Logon, 1},
      {:Logoff, 2},
      {:"Authentication Ticket", 3},
      {:"Service Ticket Request", 4},
      {:"Service Ticket Renew", 5},
      {:Preauth, 6},
      {:"Account Switch", 7},
      {:Other, 99}
    ],
    3001 => [
      {:Unknown, 0},
      {:Create, 1},
      {:Enable, 2},
      {:"Password Change", 3},
      {:"Password Reset", 4},
      {:Disable, 5},
      {:Delete, 6},
      {:"Attach Policy", 7},
      {:"Detach Policy", 8},
      {:Lock, 9},
      {:"MFA Factor Enable", 10},
      {:"MFA Factor Disable", 11},
      {:Unlock, 12},
      {:Other, 99}
    ],
    3003 => [
      {:Unknown, 0},
      {:"Assign Privileges", 1},
      {:"Revoke Privileges", 2},
      {:Other, 99}
    ],
    3004 => [
      {:Unknown, 0},
      {:Create, 1},
      {:Read, 2},
      {:Update, 3},
      {:Delete, 4},
      {:Move, 5},
      {:Enroll, 6},
      {:Unenroll, 7},
      {:Enable, 8},
      {:Disable, 9},
      {:Activate, 10},
      {:Deactivate, 11},
      {:Suspend, 12},
      {:Resume, 13},
      {:Other, 99}
    ],
    3006 => [
      {:Unknown, 0},
      {:"Assign Privileges", 1},
      {:"Revoke Privileges", 2},
      {:"Add User", 3},
      {:"Remove User", 4},
      {:Delete, 5},
      {:Create, 6},
      {:"Add Subgroup", 7},
      {:"Remove Subgroup", 8},
      {:Other, 99}
    ],
    6003 => [
      {:Unknown, 0},
      {:Create, 1},
      {:Read, 2},
      {:Update, 3},
      {:Delete, 4},
      {:Other, 99}
    ]
  }

  @doc """
  Return activities for a `class_uid` as a keyword list.

  Returns an empty list if the class is unknown.

  ## Examples

      iex> OCSF.Activity.values(3003)
      [{:Unknown, 0}, {:"Assign Privileges", 1}, {:"Revoke Privileges", 2}, {:Other, 99}]

      iex> OCSF.Activity.values(9999)
      []
  """
  @spec values(integer) :: [{atom, integer}]
  def values(class_uid), do: Map.get(@mappings, class_uid, [])

  @doc """
  Return the human-readable label for a `class_uid` and `activity_id`.

  Returns `nil` if the class or activity is unknown.

  ## Examples

      iex> OCSF.Activity.label(3002, 1)
      :Logon

      iex> OCSF.Activity.label(3002, 42)
      nil
  """
  @spec label(integer, integer) :: atom | nil
  def label(class_uid, activity_id) do
    class_uid
    |> values()
    |> Enum.find_value(fn {name, id} -> if id == activity_id, do: name end)
  end

  @doc """
  Return the `activity_id` for a `class_uid` and activity name.

  Returns `nil` if the class or activity name is unknown.

  ## Examples

      iex> OCSF.Activity.uid(3002, :Logon)
      1

      iex> OCSF.Activity.uid(3002, :NonExistent)
      nil
  """
  @spec uid(integer, atom) :: integer | nil
  def uid(class_uid, name) do
    class_uid
    |> values()
    |> Enum.find_value(fn {n, id} -> if n == name, do: id end)
  end

  @doc """
  Return true if the `activity_id` is valid for the given `class_uid`.

  ## Examples

      iex> OCSF.Activity.valid?(3002, 1)
      true

      iex> OCSF.Activity.valid?(3002, 42)
      false
  """
  @spec valid?(integer, integer) :: boolean
  def valid?(class_uid, activity_id) do
    label(class_uid, activity_id) != nil
  end
end
