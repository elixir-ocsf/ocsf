defmodule OCSF.ClassTest do
  use ExUnit.Case, async: true

  alias OCSF.Class

  test "values/0 returns all classes" do
    values = Class.values()
    assert {:Authentication, 3002} in values
    assert {:"Account Change", 3001} in values
    assert {:Authorization, 3003} in values
    assert {:"API Activity", 6003} in values
  end

  test "uid/1 and name/1 round-trip" do
    assert Class.uid(:Authentication) == 3002
    assert Class.name(3002) == :Authentication
    assert Class.uid(:nonexistent) == nil
    assert Class.name(0) == nil
  end

  test "category/1 returns the correct category_uid" do
    assert Class.category(3001) == 3
    assert Class.category(3002) == 3
    assert Class.category(3003) == 3
    assert Class.category(6003) == 6
    assert Class.category(9999) == nil
  end

  test "valid?/1 checks both atoms and integers" do
    assert Class.valid?(:Authentication)
    assert Class.valid?(3002)
    refute Class.valid?(:fake)
    refute Class.valid?(0)
  end
end
