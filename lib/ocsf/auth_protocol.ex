defmodule OCSF.AuthProtocol do
  @moduledoc """
  OCSF authentication protocol identifiers.

  Maps authentication protocol names to their OCSF 1.8 numeric
  identifiers. Used to populate the `auth_protocol_id` field on
  Authentication events.

  See the OCSF
  [auth_protocol_id](https://schema.ocsf.io/1.8.0/objects/authentication?caption=auth_protocol_id)
  definition.

  ## Values

  | Name                      | ID |
  |---------------------------|----|
  | `:Unknown`                | 0  |
  | `:NTLM`                  | 1  |
  | `:Kerberos`              | 2  |
  | `:Digest`                | 3  |
  | `:OpenID`                | 4  |
  | `:SAML`                  | 5  |
  | `:"OAUTH 2.0"`           | 6  |
  | `:PAP`                   | 7  |
  | `:CHAP`                  | 8  |
  | `:EAP`                   | 9  |
  | `:RADIUS`                | 10 |
  | `:"Basic Authentication"`| 11 |
  | `:LDAP`                  | 12 |
  | `:Other`                 | 99 |

  See `OCSF.Class` and `OCSF.Activity` for authentication event classes
  and activities.
  """

  @values [
    {:Unknown, 0},
    {:NTLM, 1},
    {:Kerberos, 2},
    {:Digest, 3},
    {:OpenID, 4},
    {:SAML, 5},
    {:"OAUTH 2.0", 6},
    {:PAP, 7},
    {:CHAP, 8},
    {:EAP, 9},
    {:RADIUS, 10},
    {:"Basic Authentication", 11},
    {:LDAP, 12},
    {:Other, 99}
  ]

  @by_uid Map.new(@values)
  @by_name Map.new(@values, fn {name, uid} -> {uid, name} end)

  @doc """
  Return all values as a keyword list.

  ## Examples

      iex> {:"OAUTH 2.0", 6} in OCSF.AuthProtocol.values()
      true
  """
  @spec values() :: [{atom, integer}]
  def values, do: @values

  @doc """
  Return values formatted for `Ecto.Enum`.

  ## Examples

      iex> {:"OAUTH 2.0", 6} in OCSF.AuthProtocol.ecto_values()
      true
  """
  @spec ecto_values() :: keyword
  def ecto_values, do: @values

  @doc """
  Return the numeric identifier for the given name atom.

  ## Examples

      iex> OCSF.AuthProtocol.uid(:SAML)
      5

      iex> OCSF.AuthProtocol.uid(:"OAUTH 2.0")
      6

      iex> OCSF.AuthProtocol.uid(:NonExistent)
      nil
  """
  @spec uid(atom) :: integer | nil
  def uid(name), do: Map.get(@by_uid, name)

  @doc """
  Return the name atom for the given numeric identifier.

  ## Examples

      iex> OCSF.AuthProtocol.name(5)
      :SAML

      iex> OCSF.AuthProtocol.name(6)
      :"OAUTH 2.0"

      iex> OCSF.AuthProtocol.name(42)
      nil
  """
  @spec name(integer) :: atom | nil
  def name(uid), do: Map.get(@by_name, uid)

  @doc """
  Return true if the given name or identifier is valid.

  ## Examples

      iex> OCSF.AuthProtocol.valid?(:SAML)
      true

      iex> OCSF.AuthProtocol.valid?(5)
      true

      iex> OCSF.AuthProtocol.valid?(:NonExistent)
      false
  """
  @spec valid?(atom | integer) :: boolean
  def valid?(name) when is_atom(name), do: Map.has_key?(@by_uid, name)
  def valid?(uid) when is_integer(uid), do: Map.has_key?(@by_name, uid)
end
