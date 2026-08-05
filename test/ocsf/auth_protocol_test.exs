defmodule OCSF.AuthProtocolTest do
  use ExUnit.Case, async: true

  alias OCSF.AuthProtocol

  describe "values/0" do
    test "covers OCSF 1.9 auth protocols" do
      values = AuthProtocol.values()
      assert {:Unknown, 0} in values
      assert {:SAML, 5} in values
      assert {:"OAUTH 2.0", 6} in values
      assert {:"Basic Authentication", 11} in values
      assert {:LDAP, 12} in values
      assert {:Other, 99} in values
      assert length(values) == 14
    end
  end

  describe "uid/1" do
    test "round-trips with name/1" do
      for {name, uid} <- AuthProtocol.values() do
        assert AuthProtocol.uid(name) == uid
      end
    end
  end

  describe "name/1" do
    test "round-trips with uid/1" do
      for {name, uid} <- AuthProtocol.values() do
        assert AuthProtocol.name(uid) == name
      end
    end
  end

  describe "valid?/1" do
    test "accepts known atoms and integers, rejects unknown" do
      assert AuthProtocol.valid?(:"OAUTH 2.0")
      assert AuthProtocol.valid?(6)
      assert AuthProtocol.valid?(:"Basic Authentication")
      assert AuthProtocol.valid?(11)
      refute AuthProtocol.valid?(:fake)
      refute AuthProtocol.valid?(42)
    end
  end

  describe "ecto_values/0" do
    test "matches values/0" do
      assert AuthProtocol.ecto_values() == AuthProtocol.values()
    end
  end
end
