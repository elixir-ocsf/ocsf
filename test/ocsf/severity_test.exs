defmodule OCSF.SeverityTest do
  use ExUnit.Case, async: true

  alias OCSF.Severity

  describe "values/0" do
    test "covers OCSF 1.9 severity levels" do
      values = Severity.values()
      assert {:Unknown, 0} in values
      assert {:Informational, 1} in values
      assert {:Low, 2} in values
      assert {:Medium, 3} in values
      assert {:High, 4} in values
      assert {:Critical, 5} in values
      assert {:Fatal, 6} in values
      assert {:Other, 99} in values
      assert length(values) == 8
    end
  end

  describe "uid/1" do
    test "round-trips with name/1" do
      for {name, uid} <- Severity.values() do
        assert Severity.uid(name) == uid
      end
    end
  end

  describe "name/1" do
    test "round-trips with uid/1" do
      for {name, uid} <- Severity.values() do
        assert Severity.name(uid) == name
      end
    end
  end

  describe "valid?/1" do
    test "accepts known atoms and integers, rejects unknown" do
      assert Severity.valid?(:Informational)
      assert Severity.valid?(1)
      refute Severity.valid?(:fake)
      refute Severity.valid?(42)
    end
  end

  describe "ecto_values/0" do
    test "matches values/0" do
      assert Severity.ecto_values() == Severity.values()
    end
  end
end
