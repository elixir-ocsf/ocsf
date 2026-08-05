defmodule OCSF.ClassTest do
  use ExUnit.Case, async: true

  alias OCSF.Class

  describe "values/0" do
    test "returns all classes" do
      values = Class.values()
      assert {:Authentication, 3002} in values
      assert {:"Account Change", 3001} in values
      assert {:"Authorize Session", 3003} in values
      assert {:"User Access Management", 3005} in values
      assert {:"API Activity", 6003} in values
    end
  end

  describe "uid/1" do
    test "returns uid for known class and nil for unknown" do
      assert Class.uid(:Authentication) == 3002
      assert Class.uid(:nonexistent) == nil
    end
  end

  describe "name/1" do
    test "returns name for known uid and nil for unknown" do
      assert Class.name(3002) == :Authentication
      assert Class.name(0) == nil
    end
  end

  describe "category/1" do
    test "returns the correct category_uid" do
      assert Class.category(3001) == 3
      assert Class.category(3002) == 3
      assert Class.category(3003) == 3
      assert Class.category(3005) == 3
      assert Class.category(6003) == 6
      assert Class.category(9999) == nil
    end
  end

  describe "valid?/1" do
    test "checks both atoms and integers" do
      assert Class.valid?(:Authentication)
      assert Class.valid?(3002)
      refute Class.valid?(:fake)
      refute Class.valid?(0)
    end
  end

  describe "ecto_values/0" do
    test "matches values/0" do
      assert Class.ecto_values() == Class.values()
    end
  end
end
