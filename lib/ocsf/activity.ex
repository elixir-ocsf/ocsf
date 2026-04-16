defmodule OCSF.Activity do
  @moduledoc "OCSF per-class activity mappings."

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
    6003 => [
      {:Unknown, 0},
      {:Create, 1},
      {:Read, 2},
      {:Update, 3},
      {:Delete, 4},
      {:Other, 99}
    ]
  }

  @doc "Returns activities for a class_uid as a keyword list."
  @spec values(integer) :: [{atom, integer}]
  def values(class_uid), do: Map.get(@mappings, class_uid, [])

  @doc "Returns the human-readable label for a class_uid + activity_id."
  @spec label(integer, integer) :: atom | nil
  def label(class_uid, activity_id) do
    class_uid
    |> values()
    |> Enum.find_value(fn {name, id} -> if id == activity_id, do: name end)
  end

  @doc "Returns the activity_id for a class_uid + activity name."
  @spec uid(integer, atom) :: integer | nil
  def uid(class_uid, name) do
    class_uid
    |> values()
    |> Enum.find_value(fn {n, id} -> if n == name, do: id end)
  end

  @doc "Returns true if the activity_id is valid for the given class_uid."
  @spec valid?(integer, integer) :: boolean
  def valid?(class_uid, activity_id) do
    label(class_uid, activity_id) != nil
  end
end
