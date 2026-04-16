defmodule OCSF.SeverityTest do
  use ExUnit.Case, async: true

  alias OCSF.Severity

  test "values/0 covers OCSF 1.8 severity levels" do
    values = Severity.values()
    assert {:"Unknown", 0} in values
    assert {:"Informational", 1} in values
    assert {:"Low", 2} in values
    assert {:"Medium", 3} in values
    assert {:"High", 4} in values
    assert {:"Critical", 5} in values
    assert {:"Fatal", 6} in values
    assert {:"Other", 99} in values
    assert length(values) == 8
  end

  test "uid/1 and name/1 round-trip" do
    for {name, uid} <- Severity.values() do
      assert Severity.uid(name) == uid
      assert Severity.name(uid) == name
    end
  end

  test "valid?/1" do
    assert Severity.valid?(:"Informational")
    assert Severity.valid?(1)
    refute Severity.valid?(:fake)
    refute Severity.valid?(42)
  end
end
