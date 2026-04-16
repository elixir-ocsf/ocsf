defmodule OCSF.StatusTest do
  use ExUnit.Case, async: true

  alias OCSF.Status

  test "values/0 covers OCSF 1.8 status values" do
    values = Status.values()
    assert {:"Unknown", 0} in values
    assert {:"Success", 1} in values
    assert {:"Failure", 2} in values
    assert {:"Other", 99} in values
    assert length(values) == 4
  end

  test "uid/1 and name/1 round-trip" do
    for {name, uid} <- Status.values() do
      assert Status.uid(name) == uid
      assert Status.name(uid) == name
    end
  end
end
