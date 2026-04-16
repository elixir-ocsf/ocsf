defmodule OCSF.AuthProtocol do
  @moduledoc "OCSF authentication protocol identifiers."

  @values [
    {:"Unknown", 0},
    {:"NTLM", 1},
    {:"Kerberos", 2},
    {:"Digest", 3},
    {:"OpenID", 4},
    {:"SAML", 5},
    {:"OAUTH 2.0", 6},
    {:"PAP", 7},
    {:"CHAP", 8},
    {:"EAP", 9},
    {:"RADIUS", 10},
    {:"Basic Authentication", 11},
    {:"LDAP", 12},
    {:"Other", 99}
  ]

  @by_uid Map.new(@values)
  @by_name Map.new(@values, fn {name, uid} -> {uid, name} end)

  @spec values() :: [{atom, integer}]
  def values, do: @values

  @spec ecto_values() :: keyword
  def ecto_values, do: @values

  @spec uid(atom) :: integer | nil
  def uid(name), do: Map.get(@by_uid, name)

  @spec name(integer) :: atom | nil
  def name(uid), do: Map.get(@by_name, uid)

  @spec valid?(atom | integer) :: boolean
  def valid?(name) when is_atom(name), do: Map.has_key?(@by_uid, name)
  def valid?(uid) when is_integer(uid), do: Map.has_key?(@by_name, uid)
end
