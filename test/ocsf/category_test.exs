defmodule OCSF.CategoryTest do
  use ExUnit.Case, async: true

  alias OCSF.Category

  test "values/0 returns all categories" do
    values = Category.values()
    assert is_list(values)
    assert {:"Identity & Access Management", 3} in values
    assert {:"Application Activity", 6} in values
  end

  test "uid/1 returns the uid for a category name" do
    assert Category.uid(:"Identity & Access Management") == 3
    assert Category.uid(:"Application Activity") == 6
    assert Category.uid(:nonexistent) == nil
  end

  test "name/1 returns the name for a category uid" do
    assert Category.name(3) == :"Identity & Access Management"
    assert Category.name(6) == :"Application Activity"
    assert Category.name(999) == nil
  end

  test "valid?/1 checks both atoms and integers" do
    assert Category.valid?(:"Identity & Access Management")
    assert Category.valid?(3)
    refute Category.valid?(:fake)
    refute Category.valid?(999)
  end

  test "ecto_values/0 matches values/0" do
    assert Category.ecto_values() == Category.values()
  end
end
