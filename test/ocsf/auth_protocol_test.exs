defmodule OCSF.AuthProtocolTest do
  use ExUnit.Case, async: true

  alias OCSF.AuthProtocol

  test "values/0 covers OCSF 1.8 auth protocols" do
    values = AuthProtocol.values()
    assert {:Unknown, 0} in values
    assert {:SAML, 5} in values
    assert {:"OAUTH 2.0", 6} in values
    assert {:"Basic Authentication", 11} in values
    assert {:LDAP, 12} in values
    assert {:Other, 99} in values
    assert length(values) == 14
  end

  test "uid/1 and name/1 round-trip" do
    for {name, uid} <- AuthProtocol.values() do
      assert AuthProtocol.uid(name) == uid
      assert AuthProtocol.name(uid) == name
    end
  end

  test "valid?/1" do
    assert AuthProtocol.valid?(:"OAUTH 2.0")
    assert AuthProtocol.valid?(6)
    assert AuthProtocol.valid?(:"Basic Authentication")
    assert AuthProtocol.valid?(11)
    refute AuthProtocol.valid?(:fake)
    refute AuthProtocol.valid?(42)
  end
end
